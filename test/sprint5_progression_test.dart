import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/core/constants/app_constants.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/core/utils/daily_selector.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/domain/entities/achievement.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/entities/game_stats.dart';
import 'package:cineus/domain/entities/stage.dart';
import 'package:cineus/domain/repositories/stage_repository.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/stage_notifier.dart';
import 'package:cineus/presentation/providers/stats_notifier.dart';
import 'package:cineus/presentation/providers/reward_notifier.dart';
import 'package:cineus/presentation/screens/generic_stage_detail_screen.dart';
import 'package:cineus/presentation/screens/film_stages_screen.dart';
import 'package:cineus/presentation/screens/stats_screen.dart';
import 'package:cineus/presentation/widgets/ticket_details_sheet.dart';
import 'package:cineus/presentation/widgets/streak_recovery_card.dart';
import 'package:cineus/presentation/visuals/cineus_assets.dart';
import 'support/test_database.dart';

Future<void> settle5(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 60));
  }
}

Future<void> progressionFixture(
  WidgetTester tester,
  Future<void> Function(ProviderContainer, Database, GoRouter, List<int>)
  action, {
  GameMode mode = GameMode.clue,
  GameStatus? status,
  bool emptyTickets = false,
  double width = 390,
  double scale = 1,
  String initial = '/detail',
  int stageId = 1,
}) async {
  late Database db;
  late ProviderContainer c;
  late List<int> ids;
  await tester.runAsync(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    const seed = DatabaseSeeder();
    await seed.ensureCanonicalSchema(db);
    await seed.seedFromJsonAsset(db);
    await seed.syncStages(db);
    c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
        appClockProvider.overrideWithValue(
          () => DateTime.utc(2026, 10, 12, 15),
        ),
      ],
    );
    final tickets = c.read(ticketNotifierProvider.notifier);
    await tickets.ready;
    if (emptyTickets) {
      await tickets.debitTickets(count: c.read(ticketNotifierProvider).total);
    }
    final stages = await c
        .read(stageRepositoryProvider)
        .getAllStages(mode: mode.name);
    ids = DailySelector.shuffleStage(
      stages.first.movieIds,
      1,
      mode == GameMode.clue
          ? AppConstants.cluesStageSeed
          : AppConstants.posterStageSeed,
    );
    if (status != null) {
      await c
          .read(gameRepositoryProvider)
          .saveSession(
            GameSession.stage(
              mode: mode,
              stageId: 1,
              movieId: ids.first,
            ).copyWith(status: status),
          );
    }
    await c.read(stageNotifierProvider.notifier).load();
    await c.read(posterStageNotifierProvider.notifier).load();
    await c.read(statsNotifierProvider.notifier).load();
    await c.read(posterStatsNotifierProvider.notifier).load();
    for (final entry in {
      'Nunito': 'Nunito-400.ttf',
      'Fredoka': 'Fredoka-700.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load('assets/fonts/${entry.value}'))).load();
    }
  });
  final router = GoRouter(
    initialLocation: initial,
    routes: [
      GoRoute(
        path: '/detail',
        builder: (_, __) => GenericStageDetailScreen(
          stageId: stageId,
          config: StageDetailConfig(mode: mode, playRoute: '/playing'),
        ),
      ),
      GoRoute(
        path: '/playing',
        builder: (_, __) => const Scaffold(body: Text('PLAYING TEST')),
      ),
      GoRoute(path: '/stages', builder: (_, __) => const FilmStagesScreen()),
      GoRoute(
        path: '/visual',
        builder: (_, __) => const FilmStagesScreen(isPoster: true),
      ),
      GoRoute(
        path: '/stats',
        builder: (_, __) => StatsScreen(onBack: () {}),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('HOME TEST')),
      ),
      GoRoute(
        path: '/recovery',
        builder: (_, __) => const Scaffold(
          body: SingleChildScrollView(child: StreakRecoveryCard()),
        ),
      ),
    ],
  );
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: AppTheme.dark,
          locale: const Locale('pt'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          routerConfig: router,
          builder: (_, child) => MediaQuery(
            data: MediaQueryData(
              size: Size(width, 640),
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await settle5(tester);
    await action(c, db, router, ids);
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    c.dispose();
    await tester.runAsync(db.close);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

class DeferredStages implements StageRepository {
  final calls = <Completer<List<Stage>>>[];
  @override
  Future<List<Stage>> getAllStages({String mode = 'clue'}) {
    final c = Completer<List<Stage>>();
    calls.add(c);
    return c.future;
  }

  @override
  Future<void> markMovieCompleted(
    int stageId,
    int movieId, {
    String mode = 'clue',
  }) async {}
}

void main() {
  test(
    'plural zero, one and many is explicit in all supported locales',
    () async {
      for (final locale in ['pt', 'en', 'es']) {
        final l = await AppL10n.delegate.load(Locale(locale));
        expect(l.dayCount(0), startsWith('0 '));
        expect(l.dayCount(1), startsWith('1 '));
        expect(l.dayCount(2), startsWith('2 '));
        expect(l.dayCount(0), isNot(l.dayCount(1)));
        expect(l.slotPoints(0), startsWith('0 '));
        expect(l.filmsCount(1), startsWith('1 '));
        expect(l.protectedDays(0), startsWith('0 '));
      }
    },
  );
  test('all seven stable badge IDs map to dedicated and distinct assets', () {
    final all = Achievements.evaluate(
      stats: const GameStats(),
      stagesCompleted: 0,
      ticketsEarned: 0,
    );
    final assets = all.map((a) => CineusAssets.forAchievement(a.id)).toSet();
    expect(assets.length, 7);
    expect(assets, isNot(contains(CineusAssetId.completed)));
  });
  test(
    'stage reload keeps newest response and safely ignores disposal',
    () async {
      final repo = DeferredStages();
      final n = StageNotifier(repo);
      final reload = n.load();
      repo.calls[1].complete([
        const Stage(id: 2, orderIndex: 2, name: 'new', movieIds: [2]),
      ]);
      await reload;
      repo.calls[0].complete([
        const Stage(id: 1, orderIndex: 1, name: 'old', movieIds: [1]),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(n.state.value!.single.id, 2);
      final pending = n.load();
      n.dispose();
      repo.calls[2].complete([]);
      await pending;
    },
  );
  for (final mode in GameMode.values) {
    testWidgets(
      '${mode.name}: compact stage list and detail scroll with text 200%',
      (tester) async {
        await progressionFixture(
          tester,
          (c, db, router, ids) async {
            expect(
              find.textContaining('Sem tickets para uma nova partida'),
              findsOneWidget,
            );
            await tester.scrollUntilVisible(
              find.byKey(ValueKey('stage-action-${ids.first}')),
              200,
            );
            await tester.pump();
            expect(find.text('Continuar'), findsOneWidget);
            expect(tester.takeException(), isNull);
            router.go(mode == GameMode.clue ? '/stages' : '/visual');
            await settle5(tester);
            expect(find.text('SEU PRÓXIMO ESTÁGIO'), findsOneWidget);
            await tester.drag(find.byType(ListView), const Offset(0, -1000));
            await tester.pump();
            expect(tester.takeException(), isNull);
          },
          mode: mode,
          status: GameStatus.playing,
          emptyTickets: true,
          width: 320,
          scale: 2,
        );
      },
    );
    testWidgets(
      '${mode.name}: resume with no tickets, rapid taps debit nothing',
      (tester) async {
        await progressionFixture(
          tester,
          (c, db, router, ids) async {
            final button = find.byKey(ValueKey('stage-action-${ids.first}'));
            await tester.ensureVisible(button);
            await tester.pump();
            await tester.tap(button);
            await tester.tap(button);
            await settle5(tester);
            expect(find.text('PLAYING TEST'), findsOneWidget);
            expect(c.read(ticketNotifierProvider).total, 0);
            final game = c.read(
              mode == GameMode.clue ? clueGameProvider : posterGameProvider,
            );
            expect(game.session!.movieId, ids.first);
            expect(game.session!.mode, mode);
          },
          mode: mode,
          status: GameStatus.playing,
          emptyTickets: true,
        );
      },
    );
    testWidgets('${mode.name}: starting one film charges once for rapid taps', (
      tester,
    ) async {
      await progressionFixture(tester, (c, db, router, ids) async {
        final first = find.byKey(ValueKey('stage-slot-${ids[0]}'));
        final second = find.byKey(ValueKey('stage-slot-${ids[1]}'));
        final firstSize = tester.getSize(first);
        expect(firstSize.width, closeTo(firstSize.height, .01));
        expect(tester.getSize(second), firstSize);
        expect(tester.getTopLeft(first).dy, tester.getTopLeft(second).dy);
        expect(
          tester.getTopLeft(first).dx,
          lessThan(tester.getTopLeft(second).dx),
        );
        expect(find.textContaining('• 1 ticket'), findsNothing);
        expect(find.textContaining('· 1 ticket'), findsNothing);
        final before = c.read(ticketNotifierProvider).total;
        final button = find.byKey(ValueKey('stage-action-${ids.first}'));
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await tester.tap(button);
        await settle5(tester);
        expect(find.text('PLAYING TEST'), findsOneWidget);
        expect(c.read(ticketNotifierProvider).total, before - 1);
      }, mode: mode);
    });
  }
  testWidgets('locked stage cannot start a film through a direct route', (
    tester,
  ) async {
    await progressionFixture(tester, (c, db, router, ids) async {
      expect(find.textContaining('Complete Estágio 1'), findsOneWidget);
      expect(find.text('Jogar'), findsNothing);
      expect(c.read(ticketNotifierProvider).total, 10);
    }, stageId: 2);
  });
  testWidgets(
    'available stage exposes an accessibility tap action and locked stage does not',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await progressionFixture(tester, (c, db, router, ids) async {
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('stage-1')),
            160,
          );
          final available = find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label ?? '').startsWith('Estágio 1.'),
          );
          expect(
            tester
                .getSemantics(available)
                .getSemanticsData()
                .hasAction(ui.SemanticsAction.tap),
            isTrue,
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('stage-2')),
            160,
          );
          final locked = find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                (w.properties.label ?? '').startsWith('Estágio 2.'),
          );
          expect(
            tester
                .getSemantics(locked)
                .getSemanticsData()
                .hasAction(ui.SemanticsAction.tap),
            isFalse,
          );
        }, initial: '/stages');
      } finally {
        semantics.dispose();
      }
    },
  );
  testWidgets(
    'failed movie load refunds its ticket and offers retry feedback',
    (tester) async {
      await progressionFixture(tester, (c, db, router, ids) async {
        final before = c.read(ticketNotifierProvider).total;
        await tester.runAsync(
          () => db.delete('movies', where: 'id = ?', whereArgs: [ids.first]),
        );
        final button = find.byKey(ValueKey('stage-action-${ids.first}'));
        await tester.ensureVisible(button);
        await tester.pump();
        await tester.tap(button);
        await settle5(tester);
        expect(find.text('PLAYING TEST'), findsNothing);
        expect(c.read(ticketNotifierProvider).total, before);
        expect(find.byType(SnackBar), findsOneWidget);
      });
    },
  );
  testWidgets('a lost film retries once and resets its score and guesses', (
    tester,
  ) async {
    await progressionFixture(tester, (c, db, router, ids) async {
      final before = c.read(ticketNotifierProvider).total;
      final button = find.byKey(ValueKey('stage-action-${ids.first}'));
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.tap(button);
      await settle5(tester);
      expect(c.read(ticketNotifierProvider).total, before - 1);
      final session = c.read(clueGameProvider).session!;
      expect(session.status, GameStatus.playing);
      expect(session.guesses, isEmpty);
      expect(session.score, 0);
    }, status: GameStatus.lost);
  });
  testWidgets('no-ticket action opens balance details, never starts a film', (
    tester,
  ) async {
    await progressionFixture(tester, (c, db, router, ids) async {
      final button = find.byKey(ValueKey('stage-action-${ids.first}'));
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await settle5(tester);
      expect(find.byType(TicketDetailsSheet), findsOneWidget);
      expect(find.text('PLAYING TEST'), findsNothing);
      Navigator.of(tester.element(find.byType(TicketDetailsSheet))).pop();
      await settle5(tester);
    }, emptyTickets: true);
  });
  testWidgets(
    'both modes expose the same badges and explicit Clues Daily scope',
    (tester) async {
      await progressionFixture(tester, (c, db, router, ids) async {
        await tester.tap(find.byKey(const ValueKey('stats-mode-poster')));
        await tester.tap(find.byKey(const ValueKey('stats-achievements')));
        await settle5(tester);
        expect(find.text('Primeira vitória'), findsOneWidget);
        expect(find.text('Daily · Dicas'), findsWidgets);
        expect(find.text('0 de 13 conquistas desbloqueadas'), findsOneWidget);
        expect(find.text('Ainda não desbloqueada'), findsWidgets);
      }, initial: '/stats');
    },
  );
  testWidgets('empty streak has zero best days and readable empty-state text', (
    tester,
  ) async {
    await progressionFixture(
      tester,
      (c, db, router, ids) async {
        final streak = find.byKey(const ValueKey('streak-summary'));
        await tester.scrollUntilVisible(streak, 200);
        await tester.pump();
        expect(find.text('Nenhuma sequência ativa'), findsOneWidget);
        expect(find.text('Melhor: 0 dias'), findsOneWidget);
        expect(find.text('Melhor: 1 dia'), findsNothing);
      },
      initial: '/stats',
      width: 320,
      scale: 2,
    );
  });
  testWidgets(
    'Poster wins do not unlock Clues Daily badges; stages in both modes count',
    (tester) async {
      await progressionFixture(tester, (c, db, router, ids) async {
        await tester.runAsync(() async {
          await c
              .read(gameRepositoryProvider)
              .saveSession(
                GameSession.daily(
                  mode: GameMode.poster,
                  date: '2026-10-12',
                  movieId: 1,
                ).copyWith(status: GameStatus.won, score: 5),
              );
          final stages = await c.read(stageRepositoryProvider).getAllStages();
          for (final stage in stages.take(3)) {
            for (final id in stage.movieIds) {
              await c
                  .read(stageRepositoryProvider)
                  .markMovieCompleted(stage.id, id);
            }
          }
          for (final stage in stages.take(2)) {
            for (final id in stage.movieIds) {
              await c
                  .read(stageRepositoryProvider)
                  .markMovieCompleted(stage.id, id, mode: 'poster');
            }
          }
          await c.read(statsNotifierProvider.notifier).load();
          await c.read(posterStatsNotifierProvider.notifier).load();
        });
        final stats = c.read(statsNotifierProvider);
        expect(
          stats.achievements.firstWhere((a) => a.id == 'first_win').isUnlocked,
          isFalse,
        );
        expect(
          stats.achievements.firstWhere((a) => a.id == 'stages_5').isUnlocked,
          isTrue,
        );
        expect(c.read(posterStatsNotifierProvider).stats.totalWins, 1);
      }, initial: '/stats');
    },
  );
  testWidgets(
    'clock and recorded freeze keep a missed day without adding a win',
    (tester) async {
      await progressionFixture(tester, (c, db, router, ids) async {
        await tester.runAsync(() async {
          for (final date in ['2026-10-12', '2026-10-10']) {
            await c
                .read(gameRepositoryProvider)
                .saveSession(
                  GameSession.daily(
                    mode: GameMode.clue,
                    date: date,
                    movieId: date.endsWith('12') ? 1 : 2,
                  ).copyWith(status: GameStatus.won, score: 8),
                );
          }
          await c.read(rewardRepositoryProvider).freezeStreakDay('2026-10-11');
          await c.read(statsNotifierProvider.notifier).load();
        });
        expect(c.read(statsNotifierProvider).stats.currentStreak, 2);
        expect(c.read(statsNotifierProvider).protectedDays, {'2026-10-11'});
        await settle5(tester);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('streak-summary')),
          180,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('stats-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tester.pump();
        expect(find.text('1 dia protegido'), findsOneWidget);
      }, initial: '/stats');
    },
  );
  testWidgets(
    'recoverable day uses the app clock and is cleared by a recorded freeze',
    (tester) async {
      await progressionFixture(tester, (c, db, router, ids) async {
        await tester.runAsync(() async {
          await c
              .read(gameRepositoryProvider)
              .saveSession(
                GameSession.daily(
                  mode: GameMode.clue,
                  date: '2026-10-10',
                  movieId: 1,
                ).copyWith(status: GameStatus.won, score: 8),
              );
          expect(
            await c.read(recoverableStreakDayProvider.future),
            '2026-10-11',
          );
          await c.read(rewardRepositoryProvider).freezeStreakDay('2026-10-11');
          c.invalidate(recoverableStreakDayProvider);
          expect(await c.read(recoverableStreakDayProvider.future), isNull);
        });
      });
    },
  );
  for (final fail in [false, true]) {
    testWidgets(
      'streak protection ${fail ? 'failure refunds and recovers' : 'rapid taps charge once'}',
      (tester) async {
        await progressionFixture(
          tester,
          (c, db, router, ids) async {
            await tester.runAsync(() async {
              await c
                  .read(gameRepositoryProvider)
                  .saveSession(
                    GameSession.daily(
                      mode: GameMode.clue,
                      date: '2026-10-10',
                      movieId: 1,
                    ).copyWith(status: GameStatus.won, score: 8),
                  );
              if (fail) {
                await db.execute(
                  "CREATE TRIGGER reject_freeze BEFORE INSERT ON streak_freezes BEGIN SELECT RAISE(FAIL, 'test storage failure'); END",
                );
              }
              c.invalidate(recoverableStreakDayProvider);
            });
            await settle5(tester);
            final button = find.text('Proteger sequência · 3 tickets');
            expect(button, findsOneWidget);
            await tester.ensureVisible(button);
            await tester.pump();
            await tester.tap(button);
            await tester.tap(button);
            await settle5(tester);
            expect(c.read(ticketNotifierProvider).total, fail ? 10 : 7);
            await tester.runAsync(() async {
              expect(
                (await c.read(rewardRepositoryProvider).streakFreezes())
                    .contains('2026-10-11'),
                !fail,
              );
            });
            if (fail) {
              expect(
                find.text(
                  'Não foi possível proteger sua sequência. Tente novamente.',
                ),
                findsOneWidget,
              );
              expect(button, findsOneWidget);
            }
          },
          initial: '/recovery',
          width: 320,
          scale: 2,
        );
      },
    );
  }
}
