import 'package:cineus/presentation/widgets/stats_dashboard.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cineus/domain/entities/color_training_session.dart';
import 'package:cineus/presentation/providers/result_share_service.dart';
import 'package:cineus/presentation/screens/color_session_screen.dart';
import 'package:cineus/presentation/screens/color_training_screen.dart';
import 'package:cineus/presentation/screens/color_tutorial_screen.dart';
import 'package:cineus/presentation/screens/stats_screen.dart';
import 'package:cineus/presentation/widgets/color_character_art.dart';
import 'package:cineus/presentation/widgets/color_share_card.dart';
import 'package:cineus/data/repositories/color_repository.dart';
import 'color_persistence_ui_test.dart'
    show ColorUiFixture, settleColors, warmPersistenceAssets;
import 'color_integration_test.dart' show statisticFixture;
import 'sprint4_ui_test.dart' show FakeShare;

Future<void> warmColorIntegration(WidgetTester tester, ColorUiFixture f) async {
  await warmPersistenceAssets(tester, f.catalog);
  await tester.runAsync(() async {
    await rootBundle.loadString('assets/colors/stages_v1.json');
    await rootBundle.loadString('assets/credits/colors_sources.json');
    for (final id in [
      'settings',
      'challenge',
      'modeClues',
      'modePoster',
      'loss',
      'video',
    ]) {
      for (final suffix in ['', '_ink']) {
        await SvgAssetLoader(
          'assets/generated/icons/$id$suffix.svg',
        ).loadBytes(null);
      }
    }
  });
}

Future<void> colorScrollTo(
  WidgetTester tester,
  Finder finder,
  String key, {
  double step = 140,
}) async {
  await tester.scrollUntilVisible(
    finder,
    step,
    scrollable: find
        .descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: .12);
  await tester.pumpAndSettle();
}

Future<void> colorTap(
  WidgetTester tester,
  String key, {
  String? scrollKey,
}) async {
  final finder = find.byKey(ValueKey(key));
  if (scrollKey != null) {
    await colorScrollTo(tester, finder, scrollKey);
  } else {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }
  await settleColors(tester);
  await Scrollable.ensureVisible(tester.element(finder), alignment: .12);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await settleColors(tester);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'first game has interactive guide; finishing records it once before creating the daily',
    (tester) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create(guideSeen: false);
      });
      await warmColorIntegration(tester, f);
      await tester.pumpWidget(
        f.app(child: const ColorSessionScreen(kind: ColorSessionKind.daily)),
      );
      await settleColors(tester);
      expect(find.byType(ColorTutorialScreen), findsOneWidget);
      await tester.runAsync(() async {
        expect(await f.repo.list(), isEmpty);
      });
      await colorScrollTo(
        tester,
        find.byKey(const ValueKey('colors-hue')),
        'colors-guide-scroll',
      );
      tester
          .widget<Slider>(find.byKey(const ValueKey('colors-hue')))
          .onChanged!(56);
      await tester.pump();
      await colorScrollTo(
        tester,
        find.byType(ColorCharacterArt),
        'colors-guide-scroll',
        step: -140,
      );
      final tutorialArt = tester.widget<ColorCharacterArt>(
        find.byType(ColorCharacterArt),
      );
      expect(tutorialArt.choice.rgb, ColorSelection(56, 50, 50).rgb.rgb);
      await colorTap(tester, 'colors-guide-next');
      await colorScrollTo(
        tester,
        find.byKey(const ValueKey('colors-guide-score')),
        'colors-guide-scroll',
      );
      expect(find.byKey(const ValueKey('colors-guide-score')), findsOneWidget);
      await colorTap(tester, 'colors-guide-next');
      await colorTap(
        tester,
        'colors-guide-stage-demo',
        scrollKey: 'colors-guide-scroll',
      );
      expect(find.text('Estágio 2 liberado no exemplo.'), findsNothing);
      await colorTap(
        tester,
        'colors-guide-stage-demo',
        scrollKey: 'colors-guide-scroll',
      );
      expect(find.text('Estágio 2 liberado no exemplo.'), findsOneWidget);
      await tester.runAsync(() async {
        expect(await f.repo.list(), isEmpty);
        expect(await f.repo.guideSeen(), false);
      });
      await colorTap(tester, 'colors-guide-next');
      await settleColors(tester);
      expect(find.byType(ColorTrainingScreen), findsOneWidget);
      await tester.runAsync(() async {
        expect(await f.repo.guideSeen(), true);
        expect((await f.repo.list()).length, 1);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(f.app(child: const ColorSessionScreen()));
      await settleColors(tester);
      expect(find.byType(ColorTutorialScreen), findsNothing);
      expect(find.byType(ColorTrainingScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(f.db.close);
    },
  );
  testWidgets('guide write failure can retry without spending a daily attempt', (
    tester,
  ) async {
    late ColorUiFixture f;
    await tester.runAsync(() async {
      f = await ColorUiFixture.create(guideSeen: false);
      await f.db.execute(
        "CREATE TRIGGER fail_guide BEFORE INSERT ON app_meta WHEN NEW.key='colors_guide_v1' BEGIN SELECT RAISE(ABORT,'write failed'); END",
      );
    });
    await warmColorIntegration(tester, f);
    await tester.pumpWidget(f.app(child: const ColorSessionScreen()));
    await settleColors(tester);
    for (var i = 0; i < 3; i++) {
      await colorTap(tester, 'colors-guide-next');
    }
    expect(find.textContaining('Não foi possível registrar'), findsOneWidget);
    await tester.runAsync(() async {
      expect(await f.repo.list(), isEmpty);
      await f.db.execute('DROP TRIGGER fail_guide');
    });
    await colorTap(tester, 'colors-guide-next');
    await settleColors(tester);
    expect(find.byType(ColorTrainingScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(f.db.close);
  });
  testWidgets(
    'daily result recovers credit failure and reopening never pays twice',
    (tester) async {
      late ColorUiFixture f;
      late SavedColorSession result;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
        result = statisticFixture(id: 'daily:2026-10-13', date: '2026-10-13');
        await f.db.insert('color_sessions', result.toRow());
        await f.db.execute(
          "CREATE TRIGGER fail_reward BEFORE UPDATE OF extra_tickets ON player_tickets BEGIN SELECT RAISE(ABORT,'write failed'); END",
        );
      });
      await warmColorIntegration(tester, f);
      await tester.pumpWidget(
        f.app(child: const ColorSessionScreen(sessionId: 'daily:2026-10-13')),
      );
      await settleColors(tester);
      // Native SQLite work must be allowed to finish outside FakeAsync before
      // waiting for animated loading indicators to settle.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('colors-reward-status')),
        140,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('colors-game-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      for (
        var i = 0;
        i < 10 &&
            find
                .byKey(const ValueKey('colors-reward-retry'))
                .evaluate()
                .isEmpty;
        i++
      ) {
        await settleColors(tester);
      }
      expect(find.byKey(const ValueKey('colors-reward-retry')), findsOneWidget);
      expect(find.textContaining('Seu resultado está salvo.'), findsOneWidget);
      await tester.runAsync(() async {
        expect(await f.db.query('ticket_rewards'), isEmpty);
        await f.db.execute('DROP TRIGGER fail_reward');
      });
      final retry = tester
          .widget<TextButton>(find.byKey(const ValueKey('colors-reward-retry')))
          .onPressed!;
      retry();
      retry();
      await settleColors(tester);
      for (
        var i = 0;
        i < 10 &&
            find.textContaining('+2 tickets recebidos').evaluate().isEmpty;
        i++
      ) {
        await settleColors(tester);
      }
      expect(find.textContaining('+2 tickets recebidos'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        f.app(child: const ColorSessionScreen(sessionId: 'daily:2026-10-13')),
      );
      await settleColors(tester);
      await tester.runAsync(() async {
        expect((await f.db.query('ticket_rewards')).length, 1);
        expect((await f.db.query('player_tickets')).single['extra_tickets'], 2);
        expect((await f.repo.load(result.id))!.game.averageCents, 300);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(f.db.close);
    },
  );
  testWidgets(
    'share exports a real PNG without answers; cancellation, failure and explicit copy are distinct',
    (tester) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
      });
      await warmColorIntegration(tester, f);
      final share = FakeShare();
      final result = statisticFixture(id: 'private-daily', date: '2026-10-13');
      await tester.pumpWidget(
        f.app(
          child: Scaffold(
            body: ColorSharePanel(data: ColorShareData.fromSession(result)),
          ),
          overrides: [resultShareServiceProvider.overrideWithValue(share)],
        ),
      );
      await settleColors(tester);
      for (final q in result.game.questions) {
        expect(find.textContaining(q.text('character', 'pt')), findsNothing);
        expect(find.text(q.target.hex), findsNothing);
      }
      await colorTap(
        tester,
        'colors-share-image',
        scrollKey: 'colors-share-scroll',
      );
      await settleColors(tester);
      expect(share.png!.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(share.copies, 0);
      expect(find.text('Resultado compartilhado!'), findsNothing);
      expect(share.text, isNot(contains('Bob Esponja')));
      expect(share.origin!.width, greaterThan(0));
      share.status = ShareResultStatus.unavailable;
      await colorTap(
        tester,
        'colors-share-text',
        scrollKey: 'colors-share-scroll',
      );
      expect(find.byKey(const ValueKey('colors-share-error')), findsOneWidget);
      share.throwsCopy = true;
      await colorTap(
        tester,
        'colors-copy-text',
        scrollKey: 'colors-share-scroll',
      );
      expect(
        find.text('Não foi possível copiar. Tente novamente.'),
        findsOneWidget,
      );
      share.throwsCopy = false;
      await colorTap(
        tester,
        'colors-copy-text',
        scrollKey: 'colors-share-scroll',
      );
      expect(share.copies, 2);
      expect(find.text('Resultado copiado!'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(f.db.close);
    },
  );
  testWidgets(
    'rapid share taps make one platform call while awaiting its result',
    (tester) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
      });
      await warmColorIntegration(tester, f);
      final share = FakeShare()..gate = Completer<void>();
      await tester.pumpWidget(
        f.app(
          child: Scaffold(
            body: ColorSharePanel(
              data: ColorShareData.fromSession(statisticFixture(id: 'test')),
            ),
          ),
          overrides: [resultShareServiceProvider.overrideWithValue(share)],
        ),
      );
      await settleColors(tester);
      await colorScrollTo(
        tester,
        find.byKey(const ValueKey('colors-share-text')),
        'colors-share-scroll',
      );
      final action = tester
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('colors-share-text')),
          )
          .onPressed!;
      action();
      action();
      await tester.pump();
      expect(share.shares, 1);
      share.gate!.complete();
      await settleColors(tester);
      await tester.pumpWidget(const SizedBox.shrink());
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
    testWidgets('home, stats, tutorial and share card fit $config', (
      tester,
    ) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
        await f.db.insert(
          'color_sessions',
          statisticFixture(id: 'daily:2026-10-13', date: '2026-10-13').toRow(),
        );
        await f.db.insert(
          'color_sessions',
          statisticFixture(
            id: 'training:complete',
            mean: 900,
            scores: [800, 900, 900, 900, 1000],
          ).toRow(),
        );
      });
      await warmColorIntegration(tester, f);
      tester.view.physicalSize = Size(config.$1, config.$2);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = f.router(initial: '/home', realHome: true);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        f.routedApp(router, scale: config.$3, language: config.$4),
      );
      await settleColors(tester);
      if (find
          .byKey(const ValueKey('home-select-colors'))
          .evaluate()
          .isNotEmpty) {
        await colorTap(tester, 'home-select-colors', scrollKey: 'home-scroll');
        await tester.pumpAndSettle();
      }
      await colorScrollTo(
        tester,
        find.byKey(const ValueKey('home-colors-card')),
        'home-scroll',
      );
      expect(tester.takeException(), isNull);
      await colorTap(tester, 'home-colors-daily', scrollKey: 'home-scroll');
      await tester.pumpAndSettle();
      expect(find.byType(ColorTrainingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        f.app(
          child: StatsScreen(initialColors: true, onBack: () {}),
          scale: config.$3,
          language: config.$4,
        ),
      );
      await settleColors(tester);
      final mean = find.descendant(
        of: find.byType(StatsGrid),
        matching: find.text(config.$4 == 'en' ? '6.00' : '6,00'),
      );
      await colorScrollTo(tester, mean, 'stats-scroll');
      expect(mean, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        f.app(
          child: ColorTutorialScreen(
            catalog: f.catalog,
            onBack: () {},
            onDone: () async {},
          ),
          scale: config.$3,
          language: config.$4,
        ),
      );
      await settleColors(tester);
      await colorTap(tester, 'colors-guide-next');
      await colorTap(tester, 'colors-guide-next');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        f.app(
          child: Scaffold(
            body: SingleChildScrollView(
              child: ColorShareCard(
                data: ColorShareData.fromSession(
                  statisticFixture(id: 'export'),
                ),
              ),
            ),
          ),
          scale: config.$3,
          language: config.$4,
        ),
      );
      await settleColors(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(f.db.close);
    });
  }
}
