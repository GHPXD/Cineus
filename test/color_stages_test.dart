import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/domain/entities/color_stage.dart';
import 'package:cineus/data/repositories/color_stage_repository.dart';
import 'package:cineus/domain/entities/saved_color_session.dart';
import 'package:cineus/presentation/providers/ticket_notifier.dart';
import 'color_persistence_ui_test.dart' show ColorUiFixture;
import 'color_persistence_test.dart' show finishColors;
import 'support/test_database.dart';
import 'color_training_session_test.dart' show trainingFixture;

Map<String, dynamic> stageJson() =>
    jsonDecode(File('assets/colors/stages_v1.json').readAsStringSync())
        as Map<String, dynamic>;
void main() {
  test(
    'two continuity modules append without altering the original ninety questions or nine stages',
    () {
      final original =
          jsonDecode(
                File('test/fixtures/color_training_2.json').readAsStringSync(),
              )
              as Map;
      final current =
          jsonDecode(File('assets/colors/training_v1.json').readAsStringSync())
              as Map;
      final oldStages =
          jsonDecode(
                File(
                  'test/fixtures/color_stages_1_original.json',
                ).readAsStringSync(),
              )
              as Map;
      expect(
        (current['questions'] as List).take(90).toList(),
        original['questions'],
      );
      expect(
        (stageJson()['stages'] as List).take(9).toList(),
        oldStages['stages'],
      );
    },
  );
  test(
    'nine fixed modules cover every region with ten unique characters and never repeat a region',
    () {
      final colors = trainingFixture(),
          catalog = ColorStageCatalog.fromJson(stageJson(), trainingFixture());
      expect(catalog.stages, hasLength(11));
      final questions = catalog.stages.expand((s) => s.questions).toList();
      expect(
        questions.map((q) => q.id).toSet(),
        colors.questions.map((q) => q.id).toSet(),
      );
      expect(
        questions.map((q) => '${q.characterId}:${q.artPart}').toSet(),
        hasLength(110),
      );
      for (final stage in catalog.stages) {
        expect(
          stage.questions.map((q) => q.characterId).toSet(),
          hasLength(10),
        );
        expect(
          stage
              .match(0)
              .map((q) => q.characterId)
              .toSet()
              .intersection(stage.match(1).map((q) => q.characterId).toSet()),
          isEmpty,
        );
      }
      final bad = stageJson();
      bad['stages'][0]['questions'][1] = bad['stages'][0]['questions'][0];
      expect(
        () => ColorStageCatalog.fromJson(bad, colors),
        throwsFormatException,
      );
    },
  );
  test(
    'atomic purchase, rollback, free resume, prerequisites and persistence coexist with old training',
    () async {
      final f = await ColorUiFixture.create();
      final catalog = ColorStageCatalog.fromJson(stageJson(), f.catalog);
      final repo = ColorStageRepository(TestDatabaseProvider(f.db), f.now);
      await repo.prepare();
      await f.seed(id: 'legacy:training');
      final tickets = TicketNotifier(TestDatabaseProvider(f.db), now: f.now);
      await tickets.ready;
      Future<SavedColorSession?> start(int stage, int match) =>
          tickets.purchaseOnce(
            existing: (db) => repo.existing(db, catalog, stage, match),
            create: (db) => repo.create(db, catalog, stage, match),
          );
      try {
        await expectLater(start(2, 0), throwsStateError);
        await expectLater(start(1, 1), throwsStateError);
        expect(tickets.state.total, 10);
        await expectLater(
          tickets.purchaseOnce<SavedColorSession>(
            existing: (db) => repo.existing(db, catalog, 1, 0),
            create: (db) async {
              await repo.create(db, catalog, 1, 0);
              throw StateError('Interrupted write');
            },
          ),
          throwsStateError,
        );
        expect(tickets.state.total, 10);
        expect(await f.db.query('color_stage_slots'), isEmpty);
        final doubleTap = await Future.wait([start(1, 0), start(1, 0)]);
        expect(doubleTap[0]!.id, doubleTap[1]!.id);
        expect(tickets.state.total, 9);
        expect((await f.repo.activeTraining())!.id, 'legacy:training');
        final saved = await f.repo.save(
          doubleTap.first!,
          finishColors(doubleTap.first!.game.clone()),
        );
        expect(saved.stageId, 1);
        expect((await f.repo.load(saved.id))!.stageMatch, 0);
        final second = (await start(1, 1))!;
        expect(tickets.state.total, 8);
        await f.repo.save(second, finishColors(second.game.clone()));
        final progress = ColorStageProgress.from(catalog, await f.repo.list());
        expect(progress[0].completed, 10);
        expect(progress[1].locked, false);
        expect(progress[2].locked, true);
        expect((await start(1, 0))!.status, 'completed');
        expect(tickets.state.total, 8);
        final restarted = TicketNotifier(
          TestDatabaseProvider(f.db),
          now: f.now,
        );
        await restarted.ready;
        expect(restarted.state.total, 8);
        restarted.dispose();
        expect((await f.repo.load(second.id))!.game.answers, hasLength(5));
      } finally {
        tickets.dispose();
        await f.db.close();
      }
    },
  );
  test('no balance never creates a paid stage session', () async {
    final f = await ColorUiFixture.create();
    final tickets = TicketNotifier(TestDatabaseProvider(f.db), now: f.now);
    await tickets.ready;
    await tickets.debitTickets(count: 10);
    final repo = ColorStageRepository(TestDatabaseProvider(f.db), f.now);
    await repo.prepare();
    final catalog = ColorStageCatalog.fromJson(stageJson(), f.catalog);
    final record = await tickets.purchaseOnce(
      existing: (db) => repo.existing(db, catalog, 1, 0),
      create: (db) => repo.create(db, catalog, 1, 0),
    );
    expect(record, isNull);
    expect(await f.repo.list(), isEmpty);
    tickets.dispose();
    await f.db.close();
  });
}
