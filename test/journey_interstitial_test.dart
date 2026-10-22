import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/data/datasources/journey_schema.dart';
import 'package:cineus/data/datasources/collection_schema.dart';
import 'package:cineus/data/repositories/journey_repository.dart';
import 'package:cineus/data/repositories/interstitial_repository.dart';
import 'package:cineus/data/repositories/game_repository_impl.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  var now = DateTime.utc(2026, 10, 15, 12);
  test(
    'weekly missions derive from real persisted results and claim atomically once per period',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final database = TestDatabaseProvider(db),
          journey = JourneyRepository(TestDatabaseProvider(db), () => now);
      final games = GameRepositoryImpl(database, now: () => now);
      final playing = await games.saveSession(
        GameSession.stage(mode: GameMode.clue, stageId: 1, movieId: 1),
      );
      final won = playing.copyWith(status: GameStatus.won, score: 10);
      await games.saveSession(won);
      await games.saveSession(won);
      expect((await journey.load()).missions.first.current, 1);
      expect(await journey.claim('play'), isFalse);
      for (var i = 1; i < 3; i++) {
        await JourneySchema.finish(
          db,
          key: 'extra:$i',
          mode: i == 1 ? 'poster' : 'colors',
          kind: 'stage',
          at: now,
          scoreCents: 900,
        );
      }
      final claims = await Future.wait([
        journey.claim('play'),
        journey.claim('play'),
      ]);
      expect(claims.where((c) => c), hasLength(1));
      expect(
        (await journey.load()).missions
            .where((m) => m.id == 'modes')
            .single
            .current,
        3,
      );
      expect(
        (await db.query(
          'collection_ownership',
          where: 'source_id LIKE ?',
          whereArgs: ['mission:%'],
        )),
        hasLength(1),
      );
      now = now.add(const Duration(days: 7));
      expect((await journey.load()).missions.first.current, 0);
      expect(
        (await db.query(
          'collection_ownership',
          where: 'source_id LIKE ?',
          whereArgs: ['mission:%'],
        )),
        hasLength(1),
      );
    },
  );
  test('failure granting a mission rolls back its claim', () async {
    now=DateTime.utc(2026,10,15,12);
    final db = await openTestDatabase();
    addTearDown(db.close);
    await JourneySchema.ensure(db);
    await CollectionSchema.ensure(db);
    for (var i = 0; i < 3; i++) {
      await JourneySchema.finish(
        db,
        key: 'film:$i',
        mode: 'clue',
        kind: 'stage',
        at: now,
        scoreCents: 500,
      );
    }
    await db.execute(
      "CREATE TRIGGER reject_mission BEFORE INSERT ON collection_ownership BEGIN SELECT RAISE(ABORT,'test'); END",
    );
    final repo = JourneyRepository(TestDatabaseProvider(db), () => now);
    await expectLater(repo.claim('play'), throwsA(anything));
    expect(await db.query('journey_claims'), isEmpty);
  });
  test(
    'interstitial reservations enforce sessions, four completions, ten minutes, daily cap and durable deduplication',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      now = DateTime.utc(2026, 10, 15, 12);
      final repo = InterstitialRepository(
        TestDatabaseProvider(db),
        () => now,
        holdout: () => false,
      );
      for (var i = 0; i < 4; i++) {
        await repo.foreground();
        now = now.add(const Duration(minutes: 31));
      }
      for (var i = 0; i < 4; i++) {
        await JourneySchema.finish(
          db,
          key: 'film:$i',
          mode: 'clue',
          kind: 'stage',
          at: now,
          scoreCents: 1000,
        );
      }
      expect(
        await repo.reserve(
          'film:3',
          rightsKnown: false,
          paid: false,
          ready: true,
        ),
        isFalse,
      );
      expect(
        await repo.reserve(
          'film:3',
          rightsKnown: true,
          paid: true,
          ready: true,
        ),
        isFalse,
      );
      expect(
        await repo.reserve(
          'film:3',
          rightsKnown: true,
          paid: false,
          ready: true,
        ),
        isTrue,
      );
      final reopened = InterstitialRepository(
        TestDatabaseProvider(db),
        () => now,
        holdout: () => true,
      );
      await repo.shown('film:3');
      expect(
        await reopened.reserve(
          'film:3',
          rightsKnown: true,
          paid: false,
          ready: true,
        ),
        isFalse,
      );
      for (var i = 4; i < 8; i++) {
        await JourneySchema.finish(
          db,
          key: 'film:$i',
          mode: 'poster',
          kind: 'stage',
          at: now,
          scoreCents: 500,
        );
      }
      expect(
        await repo.reserve(
          'film:7',
          rightsKnown: true,
          paid: false,
          ready: true,
        ),
        isFalse,
      );
      now = now.add(const Duration(minutes: 10));
      expect(
        await repo.reserve(
          'film:7',
          rightsKnown: true,
          paid: false,
          ready: true,
        ),
        isTrue,
      );
      for (var i = 8; i < 12; i++) {
        if (i == 8) await repo.shown('film:7');
        await JourneySchema.finish(
          db,
          key: 'film:$i',
          mode: 'colors',
          kind: 'stage',
          at: now,
          scoreCents: 900,
        );
      }
      now = now.add(const Duration(minutes: 10));
      expect(
        await repo.reserve(
          'film:11',
          rightsKnown: true,
          paid: false,
          ready: true,
        ),
        isFalse,
      );
      now = now.add(const Duration(days: 1));
      expect(
        await repo.reserve(
          'film:11',
          rightsKnown: true,
          paid: false,
          ready: true,
        ),
        isTrue,
      );
      expect(
        await repo.reserve(
          'daily:today',
          rightsKnown: true,
          paid: false,
          ready: true,
        ),
        isFalse,
      );
    },
  );
  test(
    'holdout group never reserves an ad; rapid returns do not create new sessions',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final repo = InterstitialRepository(
        TestDatabaseProvider(db),
        () => now,
        holdout: () => true,
      );
      for (var i = 0; i < 8; i++) {
        await repo.foreground();
      }
      expect(
        (await db.query(
          'app_meta',
          where: 'key=?',
          whereArgs: ['ads_sessions'],
        )).single['value'],
        '1',
      );
      for (var i = 0; i < 4; i++) {
        await JourneySchema.finish(
          db,
          key: 'film:$i',
          mode: 'clue',
          kind: 'stage',
          at: now,
          scoreCents: 1000,
        );
      }
      expect(
        await repo.reserve(
          'film:3',
          rightsKnown: true,
          paid: false,
          ready: true,
        ),
        isFalse,
      );
    },
  );
}
