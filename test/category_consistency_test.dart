import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/presentation/providers/color_providers.dart';
import 'package:cineus/presentation/providers/journey_provider.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/progress_provider.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/stats_notifier.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/archive_screen.dart';
import 'package:cineus/presentation/screens/friends_screen.dart';
import 'package:cineus/presentation/screens/mastery_screen.dart';
import 'package:cineus/presentation/visuals/cineus_assets.dart';
import 'package:cineus/presentation/widgets/category_backdrop.dart';
import 'package:cineus/presentation/widgets/stage_navigation_indicator.dart';
import 'package:cineus/presentation/widgets/stats_dashboard.dart';
import 'color_persistence_test.dart' show finishColors;
import 'monetization_experience_test.dart' show experience, warmExperience;
import 'native_ads_data_screen_test.dart' show app;
import 'player_collection_ui_test.dart' show settleCollection;

Future<void> _capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  await settleCollection(tester);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: name);
  if (!const bool.fromEnvironment('CINEUS_CAPTURE_CONSISTENCY')) return;
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    const directory = String.fromEnvironment(
      'CINEUS_CAPTURE_DIRECTORY',
      defaultValue: 'docs/preview/category-consistency-2026-10-21',
    );
    final file = File('$directory/screens/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<(ProviderContainer, GoRouter, GlobalKey)> _mount(
  WidgetTester tester, {
  String route = '/home',
  double width = 390,
  double scale = 1,
  String language = 'pt',
  bool seed = false,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  rootBundle.clear();
  await warmExperience(tester);
  final c = await experience(tester, movies: true);
  if (seed) {
    await tester.runAsync(() async {
      final games = c.read(gameRepositoryProvider);
      for (final mode in GameMode.values) {
        await games.saveSession(
          GameSession.daily(
            mode: mode,
            date: '2026-10-14',
            movieId: 1,
          ).copyWith(status: GameStatus.won, score: 8),
        );
      }
      await c.read(clueGameProvider.notifier).loadStageFilm(4, 1, [
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
      ]);
      final colors = c.read(colorRepositoryProvider);
      final catalog = await c.read(colorCatalogProvider.future);
      final record = await colors.archive(catalog, '2026-10-14');
      await colors.save(record, finishColors(record.game.clone()));
      await c.read(statsNotifierProvider.notifier).load();
      await c.read(posterStatsNotifierProvider.notifier).load();
      await c.read(continuingGameProvider.future);
      await c.read(journeyProgressProvider.future);
      await c.read(presenceProvider.future);
    });
  }
  final router = AppRouter.create(initialLocation: route);
  addTearDown(router.dispose);
  final boundary = GlobalKey();
  await tester.pumpWidget(
    app(c, boundary, router, language: language, scale: scale),
  );
  await settleCollection(tester);
  await tester.pumpAndSettle();
  return (c, router, boundary);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'categories share backdrop and stage navigation without charging',
    (tester) async {
      final (c, router, boundary) = await _mount(tester, route: '/stages');
      for (final (route, name) in [
        ('/stages', 'films'),
        ('/visual', 'posters'),
        ('/colors', 'colors'),
      ]) {
        router.go(route);
        await settleCollection(tester);
        expect(find.byType(CategoryBackdrop), findsOneWidget);
        if (route != '/colors') {
          final stage = find.byKey(const ValueKey('stage-1'));
          final indicator = find.descendant(
            of: stage,
            matching: find.byType(StageNavigationIndicator),
          );
          expect(indicator, findsOneWidget);
          expect(tester.getSize(indicator), const Size(32, 32));
          await tester.tap(stage);
          await settleCollection(tester);
          expect(c.read(ticketNotifierProvider).total, 10);
          router.pop();
          await settleCollection(tester);
        }
        await _capture(tester, boundary, '${name}_390_pt');
      }
    },
  );

  testWidgets('home native is between countdown and continuing game', (
    tester,
  ) async {
    final (_, _, boundary) = await _mount(tester, seed: true);
    final ad = find.byKey(const ValueKey('home-native-ad'));
    final continuing = find.byKey(const ValueKey('home-progress-action'));
    await tester.scrollUntilVisible(
      continuing,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settleCollection(tester);
    final countdownDot = find.byKey(const ValueKey('home-select-poster'));
    expect(
      tester.getBottomLeft(countdownDot).dy,
      lessThan(tester.getTopLeft(ad).dy),
    );
    expect(
      tester.getBottomLeft(ad).dy,
      lessThan(tester.getTopLeft(continuing).dy),
    );
    expect(find.text('Continuar partida'), findsOneWidget);
    await _capture(tester, boundary, 'home_native_390_pt');
  });

  testWidgets(
    'all statistics use aligned metric rows with truthful color scores',
    (tester) async {
      final (_, router, boundary) = await _mount(
        tester,
        route: '/stats',
        seed: true,
      );
      for (final mode in ['clue', 'poster', 'colors']) {
        router.go('/stats?mode=$mode');
        await settleCollection(tester);
        await _capture(tester, boundary, 'stats_${mode}_overview_390_pt');
        final grid = find.byType(StatsGrid);
        await tester.ensureVisible(grid);
        await settleCollection(tester);
        final metrics = tester
            .widgetList<StatsMetric>(find.byType(StatsMetric))
            .toList();
        expect(metrics.map((m) => m.icon), [
          CineusAssetId.homeGames,
          CineusAssetId.homeTrophy,
          CineusAssetId.categoryGoal,
          CineusAssetId.stats,
        ]);
        final panels = find.descendant(
          of: grid,
          matching: find.byType(StatsPanel),
        );
        for (var i = 0; i < 4; i += 2) {
          expect(
            tester.getTopLeft(panels.at(i)).dy,
            tester.getTopLeft(panels.at(i + 1)).dy,
          );
          expect(
            tester.getSize(panels.at(i)),
            tester.getSize(panels.at(i + 1)),
          );
        }
        if (mode == 'colors') {
          expect(metrics[0].value, '1');
          expect(metrics[1].label, 'Melhor média');
          expect(metrics[2].value, '5');
          expect(metrics[3].subtitle, 'pontos de 0 a 10');
        }
        await _capture(tester, boundary, 'stats_${mode}_390_pt');
      }
    },
  );

  for (final (width, scale, lang) in [
    (390.0, 1.0, 'pt'),
    (320.0, 2.0, 'pt'),
    (320.0, 2.0, 'en'),
    (320.0, 2.0, 'es'),
  ]) {
    testWidgets(
      'journey shortcuts stay in one accessible row $width $scale $lang',
      (tester) async {
        final (_, router, boundary) = await _mount(
          tester,
          route: '/journey',
          width: width,
          scale: scale,
          language: lang,
        );
        final actions = [
          for (final path in ['/archive', '/mastery', '/friends'])
            find.byKey(ValueKey('journey-shortcut$path')),
        ];
        final top = tester.getTopLeft(actions.first).dy;
        for (final action in actions) {
          expect(tester.getTopLeft(action).dy, top);
          expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        }
        if (scale == 1) {
          expect(tester.getTopLeft(actions.first).dx, greaterThanOrEqualTo(20));
          expect(
            tester.getTopRight(actions.last).dx,
            lessThanOrEqualTo(width - 20),
          );
        }
        await _capture(
          tester,
          boundary,
          'journey_${width.toInt()}_${scale.toInt()}x_$lang',
        );
        for (final (path, screen) in [
          ('/archive', ArchiveScreen),
          ('/mastery', MasteryScreen),
          ('/friends', FriendsScreen),
        ]) {
          final action = find.byKey(ValueKey('journey-shortcut$path'));
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          await tester.tap(action);
          await settleCollection(tester);
          expect(find.byType(screen), findsOneWidget);
          expect(tester.takeException(), isNull);
          router.pop();
          await settleCollection(tester);
        }
      },
    );
  }
}
