import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/data/datasources/database_provider.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/repositories/player_collection_repository.dart';
import 'package:cineus/domain/entities/player_collection.dart';
import 'package:cineus/presentation/providers/player_collection_provider.dart';
import 'support/test_database.dart';

class ReopenableCollectionDatabase implements DatabaseProvider {
  Database db;
  ReopenableCollectionDatabase(this.db);
  @override
  Future<Database> get database async => db;
}

void main() {
  test(
    'unavailable catalog is a recoverable state rather than a provider construction error',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final notifier = PlayerCollectionNotifier(
        PlayerCollectionRepository(TestDatabaseProvider(db), catalog: const []),
      );
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.loading, isFalse);
      expect(notifier.state.hasError, isTrue);
      expect(notifier.state.profile, isNull);
      await notifier.load();
      expect(notifier.state.hasError, isTrue);
    },
  );

  test(
    'starter grants are unique, equipping consumes nothing and survives SQLite reopen',
    () async {
      sqfliteFfiInit();
      final path =
          '${Directory.current.path}/.dart_tool/collection-${DateTime.now().microsecondsSinceEpoch}.db';
      final provider = ReopenableCollectionDatabase(
        await databaseFactoryFfi.openDatabase(path),
      );
      try {
        var repo = PlayerCollectionRepository(provider);
        final initial = await repo.load();
        expect(initial.owned, hasLength(5));
        expect(initial.displayName, isEmpty);
        expect(initial.showIdentity, isTrue);
        await repo.equip('avatar_fox_v1');
        await repo.saveIdentity('  Marina  ', false);
        await repo.load();
        expect(await provider.db.query('collection_ownership'), hasLength(5));
        await provider.db.close();
        provider.db = await databaseFactoryFfi.openDatabase(path);
        repo = PlayerCollectionRepository(provider);
        final restored = await repo.load();
        expect(restored.equipped[CollectionItemKind.avatar], 'avatar_fox_v1');
        expect(restored.displayName, 'Marina');
        expect(restored.showIdentity, isFalse);
        expect(restored.owned, initial.owned);
      } finally {
        await provider.db.close();
        await databaseFactoryFfi.deleteDatabase(path);
      }
    },
  );

  test(
    'unowned item cannot be equipped; revoked item falls back without losing the rest',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      const extra = CollectionItem(
        id: 'future_paid_test',
        asset: 'assets/collection/avatar_fox.svg',
        kind: CollectionItemKind.avatar,
      );
      final repo = PlayerCollectionRepository(
        TestDatabaseProvider(db),
        catalog: [...PlayerCollectionCatalog.items, extra],
      );
      final initial = await repo.load();
      await expectLater(repo.equip(extra.id), throwsStateError);
      expect((await repo.load()).equipped, initial.equipped);
      // Simulate a grant from the future reconciliation layer, not a public unlock API.
      await db.insert('collection_ownership', {
        'item_id': extra.id,
        'source_id': 'verified_test',
        'granted_at': DateTime.now().toUtc().toIso8601String(),
      });
      await repo.equip(extra.id);
      await db.delete(
        'collection_ownership',
        where: 'source_id=?',
        whereArgs: ['verified_test'],
      );
      final recovered = await repo.load();
      expect(recovered.equipped[CollectionItemKind.avatar], 'avatar_owl_v1');
      expect(
        recovered.equipped[CollectionItemKind.frame],
        initial.equipped[CollectionItemKind.frame],
      );
      expect(recovered.owned, hasLength(5));
    },
  );

  test(
    'write failure rolls back equipment; identity validation and SQL parameters protect data',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final repo = PlayerCollectionRepository(TestDatabaseProvider(db));
      final initial = await repo.load();
      await db.execute(
        "CREATE TRIGGER reject_equipment BEFORE INSERT ON collection_equipment BEGIN SELECT RAISE(ABORT,'write failed'); END",
      );
      await expectLater(repo.equip('avatar_fox_v1'), throwsA(anything));
      await db.execute('DROP TRIGGER reject_equipment');
      expect((await repo.load()).equipped, initial.equipped);
      expect(() => repo.saveIdentity('x' * 25, true), throwsArgumentError);
      expect(() => repo.saveIdentity('one\ntwo', true), throwsArgumentError);
      final literal = "' OR 1=1--";
      expect((await repo.saveIdentity(literal, true)).displayName, literal);
      expect((await db.query('collection_profile')), hasLength(1));
    },
  );

  test('migration preserves gameplay, existing flags and balance', () async {
    final db = await openTestDatabase(withMovies: true);
    addTearDown(db.close);
    const seeder = DatabaseSeeder();
    await seeder.ensureCanonicalSchema(db);
    await db.insert('player_tickets', {
      'id': 1,
      'daily_tickets': 7,
      'extra_tickets': 12,
      'last_reset_date': '2026-10-14',
    });
    await seeder.writeMeta(db, 'some_existing_flag', 'kept');
    final before = await db.query('player_tickets');
    final repo = PlayerCollectionRepository(TestDatabaseProvider(db));
    await repo.load();
    await repo.equip('frame_blue_reel_v1');
    await seeder.ensureCanonicalSchema(db);
    expect(await db.query('player_tickets'), before);
    expect(await seeder.readMeta(db, 'some_existing_flag'), 'kept');
    expect(await seeder.readSchemaVersion(db), 7);
    expect(
      (await repo.load()).equipped[CollectionItemKind.frame],
      'frame_blue_reel_v1',
    );
  });
}
