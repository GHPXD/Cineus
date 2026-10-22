import 'package:sqflite/sqflite.dart';
import '../../domain/entities/player_collection.dart';
import '../datasources/collection_schema.dart';
import '../datasources/database_provider.dart';

/// Local starter inventory only. Paid ownership will be reconciled from verified
/// grants in later sprints; there is deliberately no client-side unlock method.
class PlayerCollectionRepository {
  final DatabaseProvider database;
  final List<CollectionItem> catalog;
  final DateTime Function() now;
  PlayerCollectionRepository(
    this.database, {
    List<CollectionItem> catalog = PlayerCollectionCatalog.items,
    DateTime Function()? now,
  }) : catalog = List.unmodifiable(catalog),
       now = now ?? DateTime.now;

  void _validateCatalog() {
    if (catalog.map((i) => i.id).toSet().length != catalog.length ||
        CollectionItemKind.values.any(
          (kind) => !catalog.any((i) => i.kind == kind && i.starter),
        )) {
      throw ArgumentError(
        'Collection catalog needs unique IDs and a starter for each kind',
      );
    }
  }

  Future<T> _transaction<T>(Future<T> Function(Transaction txn) action) async {
    _validateCatalog();
    final db = await database.database;
    return db.transaction((txn) async {
      await CollectionSchema.ensure(txn);
      await txn.insert('collection_profile', {
        'id': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      for (final item in catalog.where((i) => i.starter)) {
        await txn.insert('collection_ownership', {
          'item_id': item.id,
          'source_id': 'starter_v1',
          'granted_at': now().toUtc().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      return action(txn);
    });
  }

  Future<PlayerCollection> _read(Transaction txn) async {
    final profile = (await txn.query(
      'collection_profile',
      where: 'id=1',
    )).single;
    final grants = await txn.query(
      'collection_ownership',
      columns: ['item_id'],
      distinct: true,
    );
    final known = catalog.map((i) => i.id).toSet();
    final owned = grants
        .map((r) => r['item_id'] as String)
        .where(known.contains)
        .toSet();
    final rows = await txn.query('collection_equipment');
    final stored = {
      for (final row in rows) row['kind'] as String: row['item_id'] as String,
    };
    final equipped = <CollectionItemKind, String>{};
    for (final kind in CollectionItemKind.values) {
      final eligible = catalog.where(
        (i) => i.kind == kind && owned.contains(i.id),
      );
      final current = eligible
          .where((i) => i.id == stored[kind.name])
          .firstOrNull;
      final selected =
          current ??
          eligible.where((i) => i.starter).firstOrNull ??
          eligible.first;
      equipped[kind] = selected.id;
      if (stored[kind.name] != selected.id) {
        await txn.insert('collection_equipment', {
          'kind': kind.name,
          'item_id': selected.id,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
    return PlayerCollection(
      displayName: profile['display_name'] as String,
      showIdentity: profile['show_identity'] == 1,
      owned: owned,
      equipped: equipped,
    );
  }

  Future<PlayerCollection> load() => _transaction(_read);

  Future<PlayerCollection> equip(String itemId) => _transaction((txn) async {
    final item = catalog.where((i) => i.id == itemId).firstOrNull;
    if (item == null) throw ArgumentError('Unknown collection item');
    final owned = await txn.query(
      'collection_ownership',
      columns: ['item_id'],
      where: 'item_id=?',
      whereArgs: [itemId],
      limit: 1,
    );
    if (owned.isEmpty) throw StateError('Item not owned');
    await txn.insert('collection_equipment', {
      'kind': item.kind.name,
      'item_id': itemId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return _read(txn);
  });

  Future<PlayerCollection> saveIdentity(String name, bool show) {
    final normalized = name.trim();
    if (normalized.runes.length > 24 ||
        RegExp(r'[\x00-\x1f\x7f-\x9f]').hasMatch(normalized)) {
      throw ArgumentError('Invalid display name');
    }
    return _transaction((txn) async {
      await txn.update('collection_profile', {
        'display_name': normalized,
        'show_identity': show ? 1 : 0,
      }, where: 'id=1');
      return _read(txn);
    });
  }
}
