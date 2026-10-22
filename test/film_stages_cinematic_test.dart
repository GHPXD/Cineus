import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/repositories/stage_repository_impl.dart';
import 'package:cineus/domain/entities/stage.dart';
import 'package:cineus/domain/repositories/stage_repository.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/film_stages_screen.dart';
import 'package:cineus/presentation/screens/generic_stage_detail_screen.dart';
import 'color_persistence_ui_test.dart' show ColorUiFixture, settleColors;

class ControlledFilmStagesRepository implements StageRepository {
  final StageRepository delegate;
  bool fail = false, empty = false;
  ControlledFilmStagesRepository(this.delegate);
  @override
  Future<List<Stage>> getAllStages({String mode = 'clue'}) async {
    if (fail) throw StateError('controlled stage read failure');
    if (empty) return [];
    return delegate.getAllStages(mode: mode);
  }

  @override
  Future<void> markMovieCompleted(
    int stageId,
    int movieId, {
    String mode = 'clue',
  }) => delegate.markMovieCompleted(stageId, movieId, mode: mode);
}

Future<void> warmFilmAssets(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final name in [
      'modeClues',
      'lock',
      'ticket',
      'inProgress',
      'homeStats',
      'homeForward',
      'completed',
      'chevron',
      'home',
      'modePoster',
      'modeColors',
      'stagesGrid',
      'retry',
    ]) {
      for (final suffix in ['', '_ink']) {
        await SvgAssetLoader(
          'assets/generated/icons/$name$suffix.svg',
        ).loadBytes(null);
      }
    }
    for (final kind in ['empty', 'error']) {
      await SvgAssetLoader(
        'assets/generated/illustrations/state_$kind.svg',
      ).loadBytes(null);
    }
  });
}

Future<void> withFilmScreen(
  WidgetTester tester,
  Future<void> Function(
    ColorUiFixture,
    ProviderContainer,
    ControlledFilmStagesRepository,
    GoRouter,
  )
  action, {
  double width = 390,
  double scale = 1,
  String language = 'pt',
  bool fail = false,
  bool empty = false,
  bool poster = false,
}) async {
  late ColorUiFixture f;
  late ControlledFilmStagesRepository repo;
  await tester.runAsync(() async {
    f = await ColorUiFixture.create();
    await const DatabaseSeeder().seedFromJsonAsset(f.db);
    await const DatabaseSeeder().syncStages(f.db);
    repo = ControlledFilmStagesRepository(
      StageRepositoryImpl(f.repo.databaseProvider),
    );
  });
  repo.fail = fail;
  repo.empty = empty;
  await warmFilmAssets(tester);
  final router = AppRouter.create(
    initialLocation: poster ? '/visual' : '/stages',
  );
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('stage-list-capture'),
      child: f.routedApp(
        router,
        scale: scale,
        language: language,
        overrides: [stageRepositoryProvider.overrideWithValue(repo)],
      ),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(FilmStagesScreen)),
  );
  await tester.runAsync(() async {
    await container
        .read(
          (poster ? posterStageNotifierProvider : stageNotifierProvider)
              .notifier,
        )
        .load();
    await container.read(ticketNotifierProvider.notifier).ready;
  });
  await settleColors(tester);
  try {
    await action(f, container, repo, router);
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await tester.runAsync(f.db.close);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'stage preview costs nothing, rapid taps push once, return refreshes real progress',
    (tester) async {
      await withFilmScreen(tester, (f, c, repo, router) async {
        final before = c.read(ticketNotifierProvider).total;
        final action = find.byKey(const ValueKey('stage-1'));
        await tester.ensureVisible(action);
        await tester.pump();
        final position = tester.getCenter(action);
        await tester.tapAt(position);
        await tester.tapAt(position);
        await settleColors(tester);
        expect(find.byType(GenericStageDetailScreen), findsOneWidget);
        expect(
          tester
              .widget<GenericStageDetailScreen>(
                find.byType(GenericStageDetailScreen),
              )
              .stageId,
          1,
        );
        expect(router.canPop(), true);
        expect(c.read(ticketNotifierProvider).total, before);
        final first = (await tester.runAsync(() => repo.getAllStages()))!.first;
        await tester.runAsync(() async {
          for (final id in first.movieIds.take(3)) {
            await repo.markMovieCompleted(first.id, id);
          }
        });
        router.pop();
        await settleColors(tester);
        for (
          var i = 0;
          i < 8 &&
              c.read(stageNotifierProvider).valueOrNull?.first.completedCount !=
                  3;
          i++
        ) {
          await settleColors(tester);
        }
        await tester.pumpAndSettle();
        expect(router.canPop(), false);
        expect(find.byType(GenericStageDetailScreen), findsNothing);
        expect(
          c.read(stageNotifierProvider).requireValue.first.completedCount,
          3,
        );
        await tester.drag(
          find.byKey(const ValueKey('films-scroll')),
          const Offset(0, 1600),
        );
        await tester.pumpAndSettle();
        expect(find.text('3 / 10 filmes concluídos'), findsOneWidget);
        expect(c.read(ticketNotifierProvider).total, before);
      });
    },
  );
  testWidgets(
    'locked row has no tap action, completing only clue stage selects stage two',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await withFilmScreen(tester, (f, c, repo, router) async {
          final locked = find.byKey(const ValueKey('stage-2'));
          await tester.scrollUntilVisible(
            locked,
            120,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('films-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          expect(tester.widget<InkWell>(locked).onTap, isNull);
          final lockedSemantics = find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label ?? '').startsWith('Estágio 2.'),
          );
          expect(
            tester.widget<Semantics>(lockedSemantics).properties.onTap,
            isNull,
          );
          final stage = (await tester.runAsync(
            () => repo.getAllStages(),
          ))!.first;
          await tester.runAsync(() async {
            for (final id in stage.movieIds) {
              await repo.markMovieCompleted(stage.id, id);
            }
            await c.read(stageNotifierProvider.notifier).load();
          });
          await settleColors(tester);
          await tester.drag(
            find.byKey(const ValueKey('films-scroll')),
            const Offset(0, 1600),
          );
          await tester.pumpAndSettle();
          final featured = find.byKey(const ValueKey('stage-2'));
          expect(tester.widget<InkWell>(featured).onTap, isNotNull);
          expect(
            find.descendant(of: featured, matching: find.text('Estágio 2')),
            findsOneWidget,
          );
          final posters = (await tester.runAsync(
            () => repo.getAllStages(mode: 'poster'),
          ))!;
          expect(posters.first.completedCount, 0);
          expect(posters[1].isLocked, true);
        });
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'read error retries and empty catalogue never invents a next stage',
    (tester) async {
      await withFilmScreen(tester, (f, c, repo, router) async {
        expect(
          find.text('Não foi possível carregar a partida.'),
          findsOneWidget,
        );
        repo.fail = false;
        await tester.tap(find.text('Tentar novamente'));
        await tester.runAsync(
          () => c.read(stageNotifierProvider.notifier).load(),
        );
        await settleColors(tester);
        expect(find.byKey(const ValueKey('stage-1')), findsOneWidget);
        repo.empty = true;
        await tester.runAsync(
          () => c.read(stageNotifierProvider.notifier).load(),
        );
        await settleColors(tester);
        expect(find.text('Nenhum estágio disponível.'), findsOneWidget);
        expect(find.byKey(const ValueKey('films-featured')), findsNothing);
        expect(find.text('0/0'), findsNothing);
      }, fail: true);
    },
  );
  for (final language in ['pt', 'en', 'es']) {
    testWidgets(
      '320px with 200% text keeps stage actions reachable in $language',
      (tester) async {
        await withFilmScreen(
          tester,
          (f, c, repo, router) async {
            final action = find.byKey(const ValueKey('stage-1'));
            await tester.scrollUntilVisible(
              action,
              160,
              scrollable: find
                  .descendant(
                    of: find.byKey(const ValueKey('films-scroll')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await Scrollable.ensureVisible(
              tester.element(action),
              alignment: .5,
            );
            await tester.pump();
            expect(action.hitTestable(), findsOneWidget);
            expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
            final locked = find.byKey(const ValueKey('stage-2'));
            await tester.scrollUntilVisible(
              locked,
              160,
              scrollable: find
                  .descendant(
                    of: find.byKey(const ValueKey('films-scroll')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            expect(tester.widget<InkWell>(locked).onTap, isNull);
          },
          width: 320,
          scale: 2,
          language: language,
        );
      },
    );
  }
  testWidgets(
    'all completed stages retain real progress without a redundant featured card',
    (tester) async {
      await withFilmScreen(tester, (f, c, repo, router) async {
        await tester.runAsync(() async {
          final stages = await repo.getAllStages();
          final batch = f.db.batch();
          for (final stage in stages) {
            for (final movie in stage.movieIds) {
              batch.insert('stage_progress', {
                'stage_id': stage.id,
                'movie_id': movie,
                'mode': 'clue',
                'status': 'completed',
              });
            }
          }
          await batch.commit(noResult: true);
          await c.read(stageNotifierProvider.notifier).load();
        });
        await settleColors(tester);
        expect(find.text('ESTÁGIO CONCLUÍDO'), findsNothing);
        expect(find.text('SEU PRÓXIMO ESTÁGIO'), findsNothing);
        expect(find.text('10 / 10 filmes concluídos'), findsWidgets);
        expect(
          c
              .read(stageNotifierProvider)
              .requireValue
              .every((s) => s.isCompleted),
          true,
        );
      });
    },
  );
}
