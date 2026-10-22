import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/stats_notifier.dart';
import 'package:cineus/presentation/providers/monetization_notifier.dart';
import 'package:cineus/presentation/providers/journey_provider.dart';
import 'package:cineus/presentation/providers/progress_provider.dart';
import 'package:cineus/presentation/screens/home_screen.dart';
import 'package:cineus/presentation/widgets/ticket_details_sheet.dart';
import 'support/test_database.dart';

Future<void> settleData(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

class Fixture {
  DateTime now = DateTime.utc(2026, 10, 12, 23, 59, 58);
  late Database db;
  late ProviderContainer container;
  late GoRouter router;
}

Future<void> withHome(
  WidgetTester tester,
  Future<void> Function(Fixture) action, {
  double width = 390,
  double scale = 1,
  List<Override> overrides = const [],
  Future<void> Function(Fixture)? prepare,
  Locale locale = const Locale('pt'),
  bool seededCatalog = false,
}) async {
  final f = Fixture();
  await tester.runAsync(() async {
    sqfliteFfiInit();
    f.db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    const seeder = DatabaseSeeder();
    await seeder.ensureCanonicalSchema(f.db);
    if (seededCatalog) {
      await seeder.seedFromJsonAsset(f.db);
      await seeder.syncStages(f.db);
    }
    for (var id = 1; !seededCatalog && id <= 3; id++) {
      await f.db.insert('movies', {
        'id': id,
        'tmdb_id': id,
        'title': 'Filme $id',
        'original_title': 'Film $id',
      });
    }
    f.container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(TestDatabaseProvider(f.db)),
        appClockProvider.overrideWithValue(() => f.now),
        ...overrides,
      ],
    );
    await f.container.read(ticketNotifierProvider.notifier).ready;
    await f.container.read(statsNotifierProvider.notifier).load();
    await f.container.read(posterStatsNotifierProvider.notifier).load();
    if (prepare != null) await prepare(f);
    await f.container.read(monetizationNotifierProvider.notifier).load();
    await f.container.read(journeyProgressProvider.future);
    await f.container.read(presenceProvider.future);
    await f.container.read(continuingGameProvider.future);
    for (final family in {
      'Nunito': 'Nunito-400.ttf',
      'Fredoka': 'Fredoka-700.ttf',
    }.entries) {
      await (FontLoader(
        family.key,
      )..addFont(rootBundle.load('assets/fonts/${family.value}'))).load();
    }
  });
  f.router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      for (final route in [
        '/victory',
        '/defeat',
        '/visual/victory',
        '/visual/defeat',
        '/game',
        '/visual/play',
      ])
        GoRoute(
          path: route,
          builder: (_, __) => Scaffold(body: Text('ROUTE $route')),
        ),
    ],
  );
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  try {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: f.container,
        child: MaterialApp.router(
          theme: AppTheme.dark,
          locale: locale,
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          routerConfig: f.router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    await settleData(tester);
    await action(f);
    expect(tester.takeException(), isNull);
  } finally {
    // Let queries launched by a tap return through the fake widget event loop
    // before unmounting; awaiting their Future inside runAsync can deadlock it.
    await settleData(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.runAsync(() async {
      f.router.dispose();
      f.container.dispose();
      await f.db.close();
    });
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

Future<void> completed(Fixture f) async {
  for (final mode in GameMode.values) {
    await f.container
        .read(gameRepositoryProvider)
        .saveSession(
          GameSession.daily(
            mode: mode,
            date: '2026-10-12',
            movieId: mode == GameMode.clue ? 1 : 2,
          ).copyWith(
            status: mode == GameMode.clue ? GameStatus.won : GameStatus.lost,
            score: mode == GameMode.clue ? 10 : 0,
          ),
        );
  }
  // An unrelated stage must not be displayed when reopening a Daily result.
  await f.container.read(clueGameProvider.notifier).loadStageFilm(3, 1, [3]);
  await f.container.read(posterGameProvider.notifier).loadStageFilm(3, 1, [3]);
}

Future<void> selectHomeMovie(WidgetTester tester, GameMode mode) async {
  final dot = find.byKey(
    ValueKey('home-select-${mode == GameMode.clue ? 'clues' : 'poster'}'),
  );
  if (dot.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(dot), alignment: .8);
    await tester.pump();
    await tester.tap(dot);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
  final key = find.byKey(ValueKey('daily-${mode.name}'));
  await tester.scrollUntilVisible(
    key,
    160,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('home-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await Scrollable.ensureVisible(tester.element(key), alignment: .5);
  await tester.pump();
}

void main() {
  for (final locale in ['pt', 'en', 'es']) {
    testWidgets('Home + wallet fit 320px / 200% in $locale', (tester) async {
      await withHome(
        tester,
        (f) async {
          await tester.tap(find.byKey(const ValueKey('ticket-balance')));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          expect(find.byType(TicketDetailsSheet), findsOneWidget);
          Navigator.of(tester.element(find.byType(TicketDetailsSheet))).pop();
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('daily-poster')),
            200,
          );
          expect(
            tester.getSize(find.byKey(const ValueKey('daily-poster'))).height,
            greaterThanOrEqualTo(48),
          );
        },
        width: 320,
        scale: 2,
        locale: Locale(locale),
      );
    });
  }
  testWidgets('wallet shows persisted total, daily and bonus; target >=48', (
    tester,
  ) async {
    await withHome(
      tester,
      (f) async {
        expect(find.text('14 tickets'), findsOneWidget);
        expect(
          tester.getSize(find.byKey(const ValueKey('ticket-balance'))).height,
          greaterThanOrEqualTo(48),
        );
        await tester.tap(find.byKey(const ValueKey('ticket-balance')));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('10 de 10'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('Bônus'), findsOneWidget);
      },
      prepare: (f) =>
          f.container.read(ticketNotifierProvider.notifier).addTickets(4),
    );
  });
  for (final mode in GameMode.values) {
    testWidgets(
      'reopens ${mode.name} result from correct daily despite stage loaded',
      (tester) async {
        await withHome(tester, (f) async {
          await selectHomeMovie(tester, mode);
          expect(
            find.textContaining(
              mode == GameMode.clue ? 'Acertou' : 'Não foi desta vez',
            ),
            findsOneWidget,
          );
          final key = ValueKey(
            mode == GameMode.clue ? 'daily-clue' : 'daily-poster',
          );
          await tester.ensureVisible(find.byKey(key));
          await tester.tap(find.byKey(key));
          await settleData(tester);
          expect(
            find.text(
              mode == GameMode.clue ? 'ROUTE /victory' : 'ROUTE /visual/defeat',
            ),
            findsOneWidget,
          );
          final state = f.container.read(
            mode == GameMode.clue ? clueGameProvider : posterGameProvider,
          );
          expect(state.session!.isDaily, isTrue);
          expect(state.movie!.id, mode == GameMode.clue ? 1 : 2);
        }, prepare: completed);
      },
    );
  }
  testWidgets('new and playing cards have separate Play/Continue actions', (
    tester,
  ) async {
    await withHome(tester, (f) async {
      await selectHomeMovie(tester, GameMode.clue);
      expect(find.text('Jogar o diário'), findsOneWidget);
      await tester.runAsync(
        () => f.container.read(clueGameProvider.notifier).loadDaily(),
      );
      f.container.invalidate(dailySessionProvider(GameMode.clue));
      await settleData(tester);
      expect(find.text('Continuar'), findsOneWidget);
      await selectHomeMovie(tester, GameMode.poster);
      expect(find.text('Jogar o diário'), findsOneWidget);
    });
  });
  testWidgets('one failed Daily retries independently of the other mode', (
    tester,
  ) async {
    var attempts = 0;
    await withHome(
      tester,
      (f) async {
        await selectHomeMovie(tester, GameMode.poster);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('daily-poster')))
              .onPressed,
          isNotNull,
        );
        await selectHomeMovie(tester, GameMode.clue);
        expect(find.text('Tentar novamente'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('daily-clue')));
        await settleData(tester);
        expect(attempts, 2);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('daily-clue')))
              .onPressed,
          isNotNull,
        );
      },
      overrides: [
        dailySessionProvider(GameMode.clue).overrideWith((ref) async {
          if (++attempts == 1) throw StateError('Temporary storage failure');
          return null;
        }),
      ],
    );
  });
  testWidgets('loading a Daily never exposes Play before data arrives', (
    tester,
  ) async {
    final pending = Completer<GameSession?>();
    await withHome(
      tester,
      (f) async {
        await selectHomeMovie(tester, GameMode.clue);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('daily-clue')))
              .onPressed,
          isNull,
        );
        pending.complete(null);
        await tester.pump();
        await settleData(tester);
        expect(
          tester
              .widget<FilledButton>(find.byKey(const ValueKey('daily-clue')))
              .onPressed,
          isNotNull,
        );
      },
      overrides: [
        dailySessionProvider(
          GameMode.clue,
        ).overrideWith((ref) => pending.future),
      ],
    );
  });
  testWidgets('UTC rollover refreshes readonly daily and both ticket buckets', (
    tester,
  ) async {
    await withHome(
      tester,
      (f) async {
        f.now = DateTime.utc(2026, 10, 13, 0, 0, 1);
        await tester.pump(const Duration(seconds: 1));
        await settleData(tester);
        expect(f.container.read(dailyDateProvider), '2026-10-13');
        await selectHomeMovie(tester, GameMode.clue);
        expect(find.text('Jogar o diário'), findsOneWidget);
        expect(f.container.read(ticketNotifierProvider).dailyTickets, 10);
        expect(f.container.read(ticketNotifierProvider).extraTickets, 4);
        await tester.runAsync(
          () => f.container.read(clueGameProvider.notifier).loadDaily(),
        );
        expect(f.container.read(clueGameProvider).session!.date, '2026-10-13');
      },
      prepare: (f) async {
        await completed(f);
        await f.container.read(ticketNotifierProvider.notifier).addTickets(4);
        await f.container
            .read(ticketNotifierProvider.notifier)
            .consumeTicket(count: 3);
      },
    );
  });
  testWidgets(
    'foreground refresh reads persisted changes even on the same day',
    (tester) async {
      await withHome(tester, (f) async {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.runAsync(
          () => f.db.update('player_tickets', {
            'extra_tickets': 7,
          }, where: 'id = 1'),
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await settleData(tester);
        expect(find.text('17 tickets'), findsOneWidget);
        expect(f.container.read(ticketNotifierProvider).extraTickets, 7);
      });
    },
  );
  testWidgets('loading/error balance never displays invented initial 10', (
    tester,
  ) async {
    await withHome(tester, (f) async {
      f.container.read(ticketBalanceStatusProvider.notifier).state =
          const AsyncLoading();
      await tester.pump();
      expect(find.text('10 tickets'), findsNothing);
      f.container.read(ticketBalanceStatusProvider.notifier).state = AsyncError(
        StateError('offline'),
        StackTrace.current,
      );
      await tester.pump();
      expect(find.text('10 tickets'), findsNothing);
      await tester.tap(find.text('Tentar novamente'));
      await settleData(tester);
      expect(find.text('10 tickets'), findsOneWidget);
    });
  });
}
