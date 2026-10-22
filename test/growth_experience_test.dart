import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/color_providers.dart';
import 'package:cineus/presentation/providers/journey_provider.dart';
import 'package:cineus/presentation/providers/progress_provider.dart';
import 'package:cineus/presentation/providers/stats_notifier.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/mastery_screen.dart';
import 'package:cineus/presentation/widgets/result_share_card.dart';
import 'package:cineus/presentation/widgets/personalized_share_panel.dart';
import 'package:cineus/presentation/widgets/cineus_poster.dart';
import 'monetization_experience_test.dart' show experience, warmExperience;
import 'player_collection_ui_test.dart' show settleCollection;
import 'color_persistence_test.dart' show finishColors;

Future<void> _seed(WidgetTester tester, ProviderContainer c) async {
  await tester.runAsync(() async {
    final games = c.read(gameRepositoryProvider);
    await games.saveSession(
      GameSession.daily(
        mode: GameMode.clue,
        date: '2026-10-18',
        movieId: 1,
      ).copyWith(status: GameStatus.won, score: 8),
    );
    await games.saveSession(
      GameSession.daily(
        mode: GameMode.poster,
        date: '2026-10-18',
        movieId: 2,
      ).copyWith(status: GameStatus.won, score: 5),
    );
    await games.saveSession(
      GameSession(
        mode: GameMode.clue,
        kind: SessionKind.training,
        date: 'practice-fixture',
        movieId: 3,
        status: GameStatus.lost,
      ),
    );
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
    final colors = c.read(colorRepositoryProvider),
        catalog = await c.read(colorCatalogProvider.future);
    await colors.markGuideSeen();
    final archive = await colors.archive(catalog, '2026-10-18');
    await colors.save(archive, finishColors(archive.game.clone()));
    await c.read(journeyProgressProvider.future);
    await c.read(presenceProvider.future);
    await c.read(continuingGameProvider.future);
    await c.read(statsNotifierProvider.notifier).load();
    await c.read(posterStatsNotifierProvider.notifier).load();
    await c.read(masteryProvider.future);
  });
}

void main() {
  for (final cfg in [
    (390.0, 1.0, 'pt'),
    (320.0, 2.0, 'pt'),
    (320.0, 2.0, 'en'),
    (320.0, 2.0, 'es'),
  ]) {
    testWidgets('growth routes fit ${cfg.$1}px at ${cfg.$2} in ${cfg.$3}', (
      tester,
    ) async {
      tester.view.physicalSize = Size(cfg.$1, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await warmExperience(tester);
      final c = await experience(
        tester,
        movies: true,
        overrides: [
          appClockProvider.overrideWithValue(
            () => DateTime.utc(2026, 10, 19, 14),
          ),
        ],
      );
      await _seed(tester, c);
      final router = AppRouter.create(initialLocation: '/home');
      addTearDown(router.dispose);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              locale: Locale(cfg.$3),
              localizationsDelegates: AppL10n.localizationsDelegates,
              supportedLocales: AppL10n.supportedLocales,
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(cfg.$2)),
                child: child!,
              ),
            ),
          ),
        ),
      );
      Future<void> snapshot(String name) async {
        await settleCollection(tester);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: name);
        if (!const bool.fromEnvironment('CINEUS_CAPTURE_GROWTH')) return;
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            'docs/preview/growth-2026-10-19/screens/${name}_${cfg.$1.toInt()}_${cfg.$2.toInt()}x_${cfg.$3}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await snapshot('home');
      if (cfg.$1 == 390) {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('home-progress-action')),
          180,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('home-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await snapshot('continue');
      }
      for (final (path, name) in [
        ('/journey', 'missions'),
        ('/archive', 'archive'),
        ('/mastery', 'mastery'),
        ('/stats', 'statistics'),
        ('/data', 'recovery'),
        ('/friends', 'friends'),
      ]) {
        router.go(path);
        await snapshot(name);
        final list = find.byType(Scrollable).first;
        await tester.drag(list, const Offset(0, -350));
        await settleCollection(tester);
        expect(tester.takeException(), isNull, reason: name);
      }
    });
  }
  testWidgets(
    'neutral result preview and captured boundary hide the poster consciously',
    (tester) async {
      final c = await experience(tester, movies: true);
      await warmExperience(tester);
      const data = ResultShareData(
        mode: GameMode.poster,
        kind: SessionKind.daily,
        won: true,
        score: 5,
        steps: 1,
        total: 5,
        movieId: 1,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.dark,
            locale: const Locale('pt'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: Scaffold(
              body: PersonalizedSharePanel(
                text: 'Cineus',
                movieId: 1,
                neutralData: data,
                cardBuilder: (look) => ResultShareCard(data: data, look: look),
              ),
            ),
          ),
        ),
      );
      await settleCollection(tester);
      expect(find.byType(CineusPoster), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.byType(CineusPoster), findsNothing);
      expect(find.text('5/5 pontos'), findsOneWidget);
    },
  );
}
