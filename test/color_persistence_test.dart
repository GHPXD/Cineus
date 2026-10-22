import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/repositories/color_repository.dart';
import 'package:cineus/domain/entities/color_daily_selector.dart';
import 'package:cineus/domain/entities/color_question.dart';
import 'package:cineus/domain/entities/color_training_session.dart';
import 'package:cineus/presentation/providers/color_session_controller.dart';
import 'color_training_session_test.dart' show trainingFixture;
import 'support/test_database.dart';

class ControlledColorRepository extends ColorRepository {
  bool fail = false;
  bool failLoad = false;
  Completer<void>? loadGate;
  Completer<void>? gate;
  ControlledColorRepository(super.provider, {super.now});
  @override
  Future<List<SavedColorSession>> list() async {
    await loadGate?.future;
    if (failLoad) throw StateError('Simulated read failure');
    return super.list();
  }

  @override
  Future<SavedColorSession> save(
    SavedColorSession previous,
    ColorTrainingSession game,
  ) async {
    await gate?.future;
    if (fail) throw StateError('Simulated disk failure');
    return super.save(previous, game);
  }
}

ColorTrainingSession finishColors(ColorTrainingSession game) {
  for (var i = game.round; i <= 5; i++) {
    if (game.phase == ColorRoundPhase.answering) game.confirm(game.question.id);
    game.advance(game.question.id);
  }
  return game;
}

void main() {
  sqfliteFfiInit();
  final catalog = trainingFixture();
  late Database db;
  late DateTime clock;
  late ControlledColorRepository repo;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    clock = DateTime.utc(2026, 10, 13, 23, 59, 59);
    repo = ControlledColorRepository(
      TestDatabaseProvider(db),
      now: () => clock,
    );
  });
  tearDown(() async => db.close());
  test(
    'expanded pack resumes and finishes pinned training-1 sessions unchanged',
    () async {
      final legacy = ColorPilotCatalog.fromJson(
        jsonDecode(
              File('test/fixtures/color_training_v1.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final oldTraining = await repo.start(legacy, ColorSessionKind.training);
      final resumedTraining = await repo.start(
        catalog,
        ColorSessionKind.training,
      );
      expect(resumedTraining.id, oldTraining.id);
      expect(resumedTraining.catalog.packVersion, 'training-1');
      expect(resumedTraining.game.toJson(), oldTraining.game.toJson());
      final oldDaily = await repo.start(legacy, ColorSessionKind.daily);
      final completed = await repo.save(
        oldDaily,
        finishColors(oldDaily.game.clone()),
      );
      final stillSameDaily = await repo.start(catalog, ColorSessionKind.daily);
      expect(stillSameDaily.id, completed.id);
      expect(stillSameDaily.catalog.packVersion, 'training-1');
      expect(stillSameDaily.game.toJson(), completed.game.toJson());
      final replacement = await repo.start(
        catalog,
        ColorSessionKind.training,
        replaceTraining: true,
      );
      expect(replacement.catalog.packVersion, 'training-3');
      expect(
        replacement.catalog.questions.map((q) => q.characterId).toSet().length,
        50,
      );
      clock = clock.add(const Duration(days: 1));
      final nextDay = await repo.start(catalog, ColorSessionKind.daily);
      expect(nextDay.catalog.packVersion, 'training-3');
      expect(
        nextDay.game.questions.map((q) => q.characterId).toSet().length,
        5,
      );
    },
  );
  test(
    'stable daily golden across catalogue ordering and UTC offset',
    () async {
      final goldenCatalog = ColorPilotCatalog.fromJson(
        jsonDecode(
              File('test/fixtures/color_training_v1.json').readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final a = ColorDailySelector.draw(goldenCatalog, '2026-10-13');
      final json = goldenCatalog.toJson();
      json['questions'] = (json['questions'] as List).reversed.toList();
      final b = ColorDailySelector.draw(
        ColorPilotCatalog.fromJson(json),
        '2026-10-13',
      );
      expect(a.questions.map((q) => q.id), b.questions.map((q) => q.id));
      expect(a.questions.map((q) => q.characterId).toSet().length, 5);
      expect(
        ColorDailySelector.draw(
          goldenCatalog,
          '2026-10-14',
        ).questions.map((q) => q.id),
        isNot(a.questions.map((q) => q.id)),
      );
      expect(
        () => ColorDailySelector.draw(catalog, '2026-02-31'),
        throwsFormatException,
      );
      clock = DateTime.parse('2026-10-13T21:00:00-03:00');
      final saved = await repo.start(catalog, ColorSessionKind.daily);
      expect(saved.dailyDate, '2026-10-14');
      expect(a.questions.map((q) => q.id).toList(), [
        'cartman_jacket',
        'finn_skin',
        'goku_undershirt',
        'pink_panther_body',
        'pikachu_ear_tips',
      ]);
    },
  );
  test(
    'daily transaction creates one session despite concurrent starts and new pack',
    () async {
      final starts = await Future.wait(
        List.generate(8, (_) => repo.start(catalog, ColorSessionKind.daily)),
      );
      expect(starts.map((s) => s.id).toSet().length, 1);
      final upgraded = catalog.toJson()..['pack_version'] = 'training-4';
      final resumed = await repo.start(
        ColorPilotCatalog.fromJson(upgraded),
        ColorSessionKind.daily,
        replaceTraining: true,
      );
      expect(resumed.catalog.packVersion, 'training-3');
      expect((await repo.list()).length, 1);
    },
  );
  test(
    'old daily remains resumable alongside today and cannot replace it',
    () async {
      final old = await repo.start(catalog, ColorSessionKind.daily);
      clock = clock.add(const Duration(seconds: 2));
      final today = await repo.start(catalog, ColorSessionKind.daily);
      final done = await repo.save(old, finishColors(old.game.clone()));
      expect(done.dailyDate, '2026-10-13');
      expect((await repo.load(today.id))!.status, 'active');
      expect((await repo.list()).length, 2);
    },
  );
  test(
    'saved draft doubles, hint, review, confirmed cents and palettes stay pinned',
    () async {
      final start = await repo.start(catalog, ColorSessionKind.training);
      final game = start.game.clone();
      game.choose(ColorSelection(56.125, 82.375, 96.625), game.question.id);
      game.useHint(game.question.id);
      final draft = await repo.save(start, game);
      final restored = (await repo.load(draft.id))!;
      expect(restored.game.selection.toJson(), [56.125, 82.375, 96.625]);
      expect(restored.game.hintUsed, true);
      game.confirm(game.question.id);
      final review = await repo.save(draft, game);
      final read = (await repo.load(review.id))!;
      expect(read.game.phase, ColorRoundPhase.review);
      expect(
        read.game.answers.single.scoreCents,
        game.answers.single.scoreCents,
      );
      expect(read.game.confirm(read.game.question.id), false);
      expect(read.catalog.toJson(), catalog.toJson());
      final next = await repo.start(
        ColorPilotCatalog.fromJson(catalog.toJson()..['pack_version'] = 'new'),
        ColorSessionKind.training,
      );
      expect(next.catalog.packVersion, 'training-3');
    },
  );
  test(
    'close and reopen physical SQLite file resumes and keeps completed histories separate',
    () async {
      final dir = await Directory.systemTemp.createTemp('cineus-colors-');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/state.db';
      var disk = await databaseFactoryFfi.openDatabase(path);
      var diskRepo = ColorRepository(
        TestDatabaseProvider(disk),
        now: () => clock,
      );
      var training = await diskRepo.start(catalog, ColorSessionKind.training);
      final game = training.game.clone()
        ..choose(ColorSelection(0.5, 1.25, 99.75), training.game.question.id);
      training = await diskRepo.save(training, game);
      await disk.close();
      disk = await databaseFactoryFfi.openDatabase(path);
      addTearDown(disk.close);
      diskRepo = ColorRepository(TestDatabaseProvider(disk), now: () => clock);
      training = (await diskRepo.load(training.id))!;
      expect(training.game.selection.toJson(), [0.5, 1.25, 99.75]);
      training = await diskRepo.save(training, finishColors(training.game));
      var daily = await diskRepo.start(catalog, ColorSessionKind.daily);
      daily = await diskRepo.save(daily, finishColors(daily.game.clone()));
      final results = await diskRepo.list();
      expect(
        results
            .where(
              (s) =>
                  s.kind == ColorSessionKind.training &&
                  s.status == 'completed',
            )
            .length,
        1,
      );
      expect(
        results
            .where(
              (s) =>
                  s.kind == ColorSessionKind.daily && s.status == 'completed',
            )
            .length,
        1,
      );
      expect(
        (await diskRepo.start(
          catalog,
          ColorSessionKind.daily,
        )).game.averageCents,
        daily.game.averageCents,
      );
      await expectLater(
        diskRepo.save(daily, daily.game),
        throwsA(isA<ColorWriteConflict>()),
      );
      await expectLater(
        diskRepo.save(training, training.game),
        throwsA(isA<ColorWriteConflict>()),
      );
    },
  );
  test(
    'compare-and-swap prevents old writer undoing confirmed answers',
    () async {
      final start = await repo.start(catalog, ColorSessionKind.training);
      final confirmed = start.game.clone()..confirm(start.game.question.id);
      await repo.save(start, confirmed);
      await expectLater(
        repo.save(start, start.game),
        throwsA(isA<ColorWriteConflict>()),
      );
      expect((await repo.load(start.id))!.game.answers.length, 1);
    },
  );
  test(
    'restart replaces only active training, preserving daily and history',
    () async {
      final daily = await repo.start(catalog, ColorSessionKind.daily);
      var complete = await repo.start(catalog, ColorSessionKind.training);
      complete = await repo.save(complete, finishColors(complete.game.clone()));
      final old = await repo.start(catalog, ColorSessionKind.training);
      final replacement = await repo.start(
        catalog,
        ColorSessionKind.training,
        replaceTraining: true,
      );
      expect(replacement.id, isNot(old.id));
      expect((await repo.load(old.id))!.status, 'abandoned');
      expect((await repo.load(daily.id))!.status, 'active');
      expect((await repo.load(complete.id))!.status, 'completed');
      await expectLater(
        repo.save(old, old.game),
        throwsA(isA<ColorWriteConflict>()),
      );
      expect((await repo.list()).length, 3);
    },
  );
  test(
    'legacy additive migration is idempotent and preserves progress, streaks, tickets and sessions',
    () async {
      const seeder = DatabaseSeeder();
      await seeder.ensureCanonicalSchema(db);
      await db.insert('player_tickets', {
        'id': 1,
        'daily_tickets': 7,
        'extra_tickets': 31,
        'last_reset_date': '2026-10-13',
      });
      await db.insert('stage_progress', {
        'stage_id': 2,
        'movie_id': 24,
        'mode': 'poster',
        'status': 'completed',
      });
      await db.insert('game_sessions', {
        'mode': 'clue',
        'kind': 'daily',
        'date': '2026-10-12',
        'stage_id': 0,
        'movie_id': 24,
        'status': 'won',
        'score': 100,
      });
      await db.insert('streak_freezes', {
        'date': '2026-10-11',
        'created_at': '2026-10-12T00:00:00Z',
      });
      await seeder.writeMeta(db, 'some_existing_flag', 'kept');
      final tables = [
        'player_tickets',
        'stage_progress',
        'game_sessions',
        'streak_freezes',
        'ticket_rewards',
      ];
      final before = {for (final name in tables) name: await db.query(name)};
      // Simulate a v2 installation: only the new colour table is absent.
      await db.execute('DROP TABLE color_sessions');
      await seeder.writeSchemaVersion(db, 2);
      await seeder.ensureCanonicalSchema(db);
      final session = await repo.start(catalog, ColorSessionKind.training);
      await seeder.ensureCanonicalSchema(db);
      for (final name in tables) {
        expect(await db.query(name), before[name]);
      }
      expect(await seeder.readSchemaVersion(db), 7);
      expect(await seeder.readMeta(db, 'some_existing_flag'), 'kept');
      expect((await repo.load(session.id))!.id, session.id);
    },
  );
  test(
    'unknown scoring versions preserve stored result cents without recalculation',
    () {
      final game = finishColors(ColorTrainingSession.draw(catalog));
      final json = game.toJson()..['rule'] = 'future-v9';
      (json['answers'] as List)[0]['score'] = 123;
      json['average'] = 456;
      final read = ColorTrainingSession.fromJson(json);
      expect(read.answers.first.scoreCents, 123);
      expect(read.averageCents, 456);
      final active = ColorTrainingSession.draw(catalog).toJson()
        ..['rule'] = 'future-v9';
      final pending = ColorTrainingSession.fromJson(active);
      expect(() => pending.confirm(pending.question.id), throwsFormatException);
    },
  );
  test(
    'invalid saved answer/state is rejected without deleting database records',
    () async {
      final saved = await repo.start(catalog, ColorSessionKind.training);
      final row = saved.toRow();
      final snapshot =
          jsonDecode(row['snapshot'] as String) as Map<String, dynamic>;
      snapshot['game']['index'] = 3;
      await db.update(
        'color_sessions',
        {'snapshot': jsonEncode(snapshot)},
        where: 'id = ?',
        whereArgs: [saved.id],
      );
      await expectLater(repo.load(saved.id), throwsFormatException);
      expect((await db.query('color_sessions')).length, 1);
    },
  );
  test(
    'controller blocks duplicate confirmation until commit and recovers a failed write',
    () async {
      final saved = await repo.start(catalog, ColorSessionKind.training);
      final c = ColorSessionController(repo, saved);
      addTearDown(c.dispose);
      repo.gate = Completer<void>();
      final first = c.act((g) => g.confirm(g.question.id));
      expect(await c.act((g) => g.confirm(g.question.id)), false);
      expect(c.game.phase, ColorRoundPhase.answering);
      repo.fail = true;
      repo.gate!.complete();
      expect(await first, false);
      expect(c.game.answers, isEmpty);
      expect(c.error, isNotNull);
      repo.gate = null;
      repo.fail = false;
      expect(await c.retry(), true);
      expect(await c.act((g) => g.confirm(g.question.id)), true);
      expect((await repo.load(saved.id))!.game.answers.length, 1);
    },
  );
  test(
    'draft autosave serializes edits made during a write and survives retry',
    () async {
      final saved = await repo.start(catalog, ColorSessionKind.training);
      final c = ColorSessionController(repo, saved);
      addTearDown(c.dispose);
      c.choose(ColorSelection(51, 72, 93), c.game.question.id);
      repo.gate = Completer<void>();
      final write = c.flush();
      c.choose(ColorSelection(59.5, 79.5, 99.5), c.game.question.id);
      repo.gate!.complete();
      repo.gate = null;
      expect(await write, true);
      expect((await repo.load(saved.id))!.game.selection.toJson(), [
        59.5,
        79.5,
        99.5,
      ]);
      repo.fail = true;
      c.choose(ColorSelection(100, 80, 60), c.game.question.id);
      expect(await c.flush(), false);
      expect(c.dirty, true);
      repo.fail = false;
      expect(await c.retry(), true);
      expect((await repo.load(saved.id))!.game.selection.toJson(), [
        100,
        80,
        60,
      ]);
    },
  );
  test(
    'controller conflict recovery reloads newest state rather than overwriting it',
    () async {
      final saved = await repo.start(catalog, ColorSessionKind.training);
      final c = ColorSessionController(repo, saved);
      addTearDown(c.dispose);
      await repo.save(
        saved,
        saved.game.clone()..useHint(saved.game.question.id),
      );
      expect(await c.act((g) => g.confirm(g.question.id)), false);
      expect(c.error, isA<ColorWriteConflict>());
      expect(await c.retry(), true);
      expect(c.game.hintUsed, true);
    },
  );
}
