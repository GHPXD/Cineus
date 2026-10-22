import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/data/repositories/color_repository.dart';
import 'package:cineus/domain/entities/color_question.dart';
import 'package:cineus/domain/entities/color_training_session.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'package:cineus/presentation/providers/color_providers.dart';
import 'package:cineus/presentation/providers/color_session_controller.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/presentation/screens/color_hub_screen.dart';
import 'package:cineus/presentation/screens/color_stages_screen.dart';
import 'package:cineus/presentation/screens/color_session_screen.dart';
import 'package:cineus/presentation/screens/color_training_screen.dart';
import 'package:cineus/presentation/screens/stats_screen.dart';
import 'package:cineus/presentation/screens/color_tutorial_screen.dart';
import 'package:cineus/presentation/screens/home_screen.dart';
import 'color_persistence_test.dart'
    show ControlledColorRepository, finishColors;
import 'color_training_session_test.dart' show trainingFixture, fixedTraining;
import 'color_training_screen_test.dart' show warmTrainingAssets;
import 'support/test_database.dart';

Future<void> settleColors(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> warmPersistenceAssets(
  WidgetTester tester,
  ColorPilotCatalog catalog,
) async {
  await warmTrainingAssets(tester, catalog);
  await tester.runAsync(() async {
    for (final id in [
      'clock',
      'inProgress',
      'stats',
      'completed',
      'ticket',
      'share',
      'copy',
      'win',
    ]) {
      for (final suffix in ['', '_ink']) {
        await SvgAssetLoader(
          'assets/generated/icons/$id$suffix.svg',
        ).loadBytes(null);
      }
    }
    for (final kind in ['empty', 'error', 'recovery']) {
      await SvgAssetLoader(
        'assets/generated/illustrations/state_$kind.svg',
      ).loadBytes(null);
    }
    await SvgAssetLoader(
      'assets/generated/illustrations/learning_daily.svg',
    ).loadBytes(null);
  });
}

class ColorUiFixture {
  final Database db;
  final ControlledColorRepository repo;
  final ColorPilotCatalog catalog;
  final DateTime Function() now;
  ColorUiFixture(this.db, this.repo, this.catalog, this.now);
  static Future<ColorUiFixture> create({
    DateTime Function()? now,
    bool guideSeen = true,
  }) async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    final clock = now ?? () => DateTime.utc(2026, 10, 13, 15, 30);
    final repo = ControlledColorRepository(
      TestDatabaseProvider(db),
      now: clock,
    );
    await const DatabaseSeeder().ensureCanonicalSchema(db);
    if (guideSeen) await repo.markGuideSeen();
    await repo.list();
    return ColorUiFixture(db, repo, trainingFixture(), clock);
  }

  Future<SavedColorSession> seed({
    String id = 'training:fixture',
    String? dailyDate,
    ColorTrainingSession? game,
  }) async {
    game ??= fixedTraining(catalog);
    final record = SavedColorSession(
      id: id,
      kind: dailyDate == null
          ? ColorSessionKind.training
          : ColorSessionKind.daily,
      dailyDate: dailyDate,
      revision: 0,
      status: game.phase == ColorRoundPhase.finished ? 'completed' : 'active',
      createdAt: now().toUtc(),
      updatedAt: now().toUtc(),
      catalog: catalog,
      game: game,
    );
    await db.insert('color_sessions', record.toRow());
    return record;
  }

  GoRouter router({String initial = '/colors', bool realHome = false}) =>
      GoRouter(
        initialLocation: initial,
        routes: [
          GoRoute(
            path: '/home',
            builder: (c, s) => realHome
                ? const HomeScreen()
                : Scaffold(
                    body: FilledButton(
                      onPressed: () => c.push('/colors'),
                      child: const Text('Abrir Cores'),
                    ),
                  ),
          ),
          GoRoute(
            path: '/colors',
            builder: (c, s) => const ColorStagesScreen(),
          ),
          GoRoute(
            path: '/colors/history',
            builder: (c, s) => const ColorHubScreen(),
          ),
          GoRoute(
            path: '/colors/stats',
            builder: (c, s) => StatsScreen(initialColors: true, onBack: () {}),
          ),
          GoRoute(
            path: '/colors/guide',
            builder: (c, s) => const ColorGuideScreen(),
          ),
          GoRoute(
            path: '/colors/train',
            builder: (c, s) => const ColorSessionScreen(),
          ),
          GoRoute(
            path: '/colors/daily',
            builder: (c, s) =>
                const ColorSessionScreen(kind: ColorSessionKind.daily),
          ),
          GoRoute(
            path: '/colors/session/:id',
            builder: (c, s) =>
                ColorSessionScreen(sessionId: s.pathParameters['id']),
          ),
        ],
      );
  Widget app({
    required Widget child,
    double scale = 1,
    String language = 'pt',
    List<Override> overrides = const [],
  }) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
      colorRepositoryProvider.overrideWithValue(repo),
      colorCatalogProvider.overrideWith((ref) async => catalog),
      appClockProvider.overrideWithValue(now),
      ...overrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: Locale(language),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: w!,
      ),
      home: child,
    ),
  );
  Widget routedApp(
    GoRouter router, {
    double scale = 1,
    String language = 'pt',
    List<Override> overrides = const [],
  }) => ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
      colorRepositoryProvider.overrideWithValue(repo),
      colorCatalogProvider.overrideWith((ref) async => catalog),
      appClockProvider.overrideWithValue(now),
      ...overrides,
    ],
    child: MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: Locale(language),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (c, w) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: w!,
      ),
    ),
  );
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('read failure preserves records and offers retry after loading', (
    tester,
  ) async {
    late ColorUiFixture f;
    await tester.runAsync(() async {
      f = await ColorUiFixture.create();
      await f.seed();
    });
    await warmPersistenceAssets(tester, f.catalog);
    f.repo.failLoad = true;
    await tester.pumpWidget(f.app(child: const ColorStagesScreen()));
    await settleColors(tester);
    expect(find.textContaining('Não foi possível abrir'), findsOneWidget);
    f.repo.failLoad = false;
    await tester.tap(find.text('Tentar novamente'));
    await settleColors(tester);
    expect(find.text('Todos os estágios'), findsOneWidget);
    await tester.runAsync(() async {
      expect((await f.repo.list()).length, 1);
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(f.db.close);
  });
  testWidgets(
    'saved back flushes draft and resumes without discard; daily cannot restart',
    (tester) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
        await f.seed();
      });
      await warmPersistenceAssets(tester, f.catalog);
      final router = f.router(initial: '/home');
      addTearDown(router.dispose);
      await tester.pumpWidget(f.routedApp(router));
      await tester.tap(find.text('Abrir Cores'));
      await settleColors(tester);
      await tester.scrollUntilVisible(
        find.text('Retomar treino anterior'),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('colors-hub-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retomar treino anterior'));
      await settleColors(tester);
      await tester.pumpAndSettle();
      expect(find.byType(ColorTrainingScreen), findsOneWidget);
      final controller = tester
          .widget<ColorTrainingScreen>(find.byType(ColorTrainingScreen))
          .controller!;
      controller.choose(
        ColorSelection(12.25, 34.5, 67.75),
        controller.game.question.id,
      );
      f.repo.gate = Completer<void>();
      await tester.binding.handlePopRoute();
      final back = tester
          .widget<IconButton>(
            find
                .ancestor(
                  of: find.descendant(
                    of: find.byType(ColorTrainingScreen),
                    matching: find.byTooltip('Voltar'),
                  ),
                  matching: find.byType(IconButton),
                )
                .first,
          )
          .onPressed!;
      back();
      back();
      expect(find.byType(ColorTrainingScreen), findsOneWidget);
      f.repo.gate!.complete();
      f.repo.gate = null;
      await settleColors(tester);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ColorStagesScreen), findsOneWidget);
      await tester.runAsync(() async {
        expect(
          (await f.repo.load('training:fixture'))!.game.selection.toJson(),
          [12.25, 34.5, 67.75],
        );
      });
      router.push('/colors/daily');
      await settleColors(tester);
      for (
        var wait = 0;
        wait < 20 && find.byType(ColorTrainingScreen).evaluate().isEmpty;
        wait++
      ) {
        await settleColors(tester);
      }
      expect(find.byKey(const ValueKey('colors-restart')), findsNothing);
      expect(
        find.byType(ColorTrainingScreen),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      expect(
        tester
            .widget<ColorTrainingScreen>(find.byType(ColorTrainingScreen))
            .controller!
            .record
            .dailyDate,
        '2026-10-13',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(f.db.close);
    },
  );
  testWidgets(
    'write failure keeps round, disables confirm, retries, then records one answer',
    (tester) async {
      late ColorUiFixture f;
      late SavedColorSession saved;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
        saved = await f.seed();
      });
      await warmPersistenceAssets(tester, f.catalog);
      final controller = ColorSessionController(f.repo, saved);
      await tester.pumpWidget(
        f.app(
          child: ColorTrainingScreen(
            catalog: f.catalog,
            controller: controller,
            onBack: () {},
          ),
        ),
      );
      await settleColors(tester);
      f.repo.fail = true;
      await tester.tap(find.byKey(const ValueKey('colors-confirm')));
      await settleColors(tester);
      expect(controller.game.phase, ColorRoundPhase.answering);
      expect(find.textContaining('Não foi possível salvar.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('colors-confirm')))
            .onPressed,
        isNull,
      );
      f.repo.fail = false;
      await tester.tap(find.text('Tentar novamente'));
      await settleColors(tester);
      final confirm = tester
          .widget<FilledButton>(find.byKey(const ValueKey('colors-confirm')))
          .onPressed!;
      confirm();
      confirm();
      await settleColors(tester);
      expect(controller.game.answers.length, 1);
      await tester.runAsync(() async {
        expect((await f.repo.load(saved.id))!.game.answers.length, 1);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      await tester.runAsync(f.db.close);
    },
  );
  for (final config in [
    (390.0, 844.0, 1.0, 'pt'),
    (320.0, 640.0, 2.0, 'pt'),
    (1024.0, 768.0, 1.0, 'pt'),
    (320.0, 640.0, 2.0, 'en'),
    (320.0, 640.0, 2.0, 'es'),
  ]) {
    testWidgets('hub, pending daily and both history categories fit $config', (
      tester,
    ) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
        await f.seed();
        await f.seed(id: 'daily:2026-10-12', dailyDate: '2026-10-12');
        await f.seed(
          id: 'training:completed',
          game: finishColors(fixedTraining(f.catalog)),
        );
        await f.seed(
          id: 'daily:2026-10-11',
          dailyDate: '2026-10-11',
          game: finishColors(fixedTraining(f.catalog)),
        );
      });
      await warmPersistenceAssets(tester, f.catalog);
      tester.view.physicalSize = Size(config.$1, config.$2);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        f.app(
          child: const ColorStagesScreen(),
          scale: config.$3,
          language: config.$4,
        ),
      );
      await settleColors(tester);
      expect(tester.takeException(), isNull);
      final list = tester.widget<ListView>(
        find.byKey(const ValueKey('colors-hub-scroll')),
      );
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('colors-hub-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      expect(list, isNotNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        f.app(
          child: const ColorHubScreen(),
          scale: config.$3,
          language: config.$4,
        ),
      );
      await settleColors(tester);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('colors-history-training')),
        100,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('colors-hub-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byType(ChoiceChip), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const ValueKey('colors-history-training'))),
        alignment: .1,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('colors-history-training')));
      await tester.pump();
      expect(
        tester
            .widget<ChoiceChip>(
              find.byKey(const ValueKey('colors-history-training')),
            )
            .selected,
        true,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(f.db.close);
    });
  }
}
