import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/domain/entities/color_question.dart';
import 'package:cineus/domain/entities/color_training_session.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/screens/color_training_screen.dart';
import 'package:cineus/presentation/widgets/color_character_art.dart';
import 'color_training_session_test.dart' show trainingFixture, fixedTraining;

Future<void> warmTrainingAssets(
  WidgetTester tester,
  ColorPilotCatalog catalog,
) async {
  await tester.runAsync(() async {
    for (final id in [
      'modeColors',
      'back',
      'retry',
      'help',
      'reveal',
      'enter',
      'chevron',
    ]) {
      for (final suffix in ['', '_ink']) {
        await SvgAssetLoader(
          'assets/generated/icons/$id$suffix.svg',
        ).loadBytes(null);
      }
    }
    for (final char in catalog.questions.map((q) => q.characterId).toSet()) {
      final parts = {
        'base',
        ...catalog.questions
            .where((q) => q.characterId == char)
            .map((q) => q.artPart)
            .whereType<String>(),
      };
      for (final part in parts) {
        await SvgAssetLoader(
          'assets/colors/art/${char}_$part.svg',
        ).loadBytes(null);
      }
    }
  });
}

Future<ColorTrainingSession> pumpTraining(
  WidgetTester tester, {
  double width = 390,
  double height = 844,
  double scale = 1,
  String language = 'pt',
  VoidCallback? onBack,
}) async {
  final catalog = trainingFixture(), game = fixedTraining(catalog);
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await warmTrainingAssets(tester, catalog);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: Locale(language),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: ColorTrainingScreen(
        catalog: catalog,
        session: game,
        onBack: onBack ?? () {},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return game;
}

Future<void> gameTap(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> bodyScrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    100,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('colors-game-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'dominant art and integrated full-width panel keep all three channels editable',
    (tester) async {
      final game = await pumpTraining(tester);
      final studio = tester.getRect(
        find.byKey(const ValueKey('colors-studio')),
      );
      final panel = tester.getRect(
        find.byKey(const ValueKey('colors-studio-panel')),
      );
      final art = tester.getRect(
        find.byKey(const ValueKey('colors-live-character')),
      );
      expect(art.height, greaterThanOrEqualTo(280));
      expect(art.height, greaterThan(panel.height));
      expect(panel.right, lessThanOrEqualTo(studio.right));
      expect(panel.right, closeTo(studio.right - 13.5, .1));
      expect(panel.width, closeTo(studio.width - 27, .1));
      expect(art.bottom, lessThanOrEqualTo(panel.top));
      expect(find.textContaining('Lembre a cor:'), findsNothing);
      expect(find.textContaining('fica definitiva'), findsNothing);
      expect(find.byType(Slider), findsOneWidget);
      await bodyScrollTo(
        tester,
        find.byKey(const ValueKey('colors-channel-1')),
      );
      await gameTap(tester, 'colors-channel-1');
      tester
          .widget<Slider>(find.byKey(const ValueKey('colors-saturation')))
          .onChanged!(80);
      await tester.pumpAndSettle();
      expect(game.selection.saturation, 80);
      expect(game.selection.hue, 200);
      await gameTap(tester, 'colors-channel-2');
      tester
          .widget<Slider>(find.byKey(const ValueKey('colors-brightness')))
          .onChanged!(70);
      await tester.pumpAndSettle();
      expect(game.selection.brightness, 70);
      expect(game.selection.saturation, 80);
      expect(game.answers, isEmpty);
      expect(find.text(game.question.target.hex), findsNothing);
    },
  );
  testWidgets(
    'live sprite changes, hint charges once, confirmation reveals and locks',
    (tester) async {
      final game = await pumpTraining(tester);
      final before = tester
          .widget<ColorCharacterArt>(
            find.byKey(const ValueKey('colors-live-character')),
          )
          .choice
          .rgb;
      await bodyScrollTo(tester, find.byKey(const ValueKey('colors-hue')));
      tester
          .widget<Slider>(find.byKey(const ValueKey('colors-hue')))
          .onChanged!(56);
      await tester.pumpAndSettle();
      expect(game.selection.hue, 56);
      // Body virtualization may dispose the offscreen art; the authoritative colour
      // still matches the same live choice on returning to the question.
      final scroll = tester
          .widget<ListView>(find.byKey(const ValueKey('colors-game-scroll')))
          .controller!;
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ColorCharacterArt>(
              find.byKey(const ValueKey('colors-live-character')),
            )
            .choice
            .rgb,
        isNot(before),
      );
      expect(find.text(game.question.target.hex), findsNothing);
      await bodyScrollTo(tester, find.byKey(const ValueKey('colors-use-hint')));
      await gameTap(tester, 'colors-use-hint');
      expect(game.hintUsed, isTrue);
      expect(find.byKey(const ValueKey('colors-use-hint')), findsNothing);
      expect(find.byKey(const ValueKey('colors-active-hint')), findsOneWidget);
      final confirm = tester
          .widget<FilledButton>(find.byKey(const ValueKey('colors-confirm')))
          .onPressed!;
      confirm();
      confirm();
      await tester.pumpAndSettle();
      expect(game.answers.length, 1);
      expect(game.phase, ColorRoundPhase.review);
      expect(find.byType(Slider), findsNothing);
      expect(find.text(game.question.target.hex), findsOneWidget);
      expect(find.byKey(const ValueKey('colors-round-score')), findsOneWidget);
      final next = tester
          .widget<FilledButton>(find.byKey(const ValueKey('colors-next-round')))
          .onPressed!;
      next();
      next();
      await tester.pumpAndSettle();
      expect(game.round, 2);
      expect(game.hintUsed, isFalse);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'all five rounds end in a formatted average and restart creates a fresh game',
    (tester) async {
      final game = await pumpTraining(tester);
      for (var round = 1; round <= 5; round++) {
        await gameTap(tester, 'colors-confirm');
        await gameTap(tester, 'colors-next-round');
      }
      expect(game.phase, ColorRoundPhase.finished);
      expect(game.answers.length, 5);
      expect(
        find.byKey(const ValueKey('colors-final-average')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('colors-play-again')), findsOneWidget);
      await gameTap(tester, 'colors-play-again');
      expect(find.text('Rodada 1/5'), findsOneWidget);
      expect(find.byKey(const ValueKey('colors-confirm')), findsOneWidget);
      expect(find.byKey(const ValueKey('colors-final-average')), findsNothing);
      expect(game.answers.length, 5);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'cancel keeps the current answer; explicit discard restarts round one',
    (tester) async {
      final game = await pumpTraining(tester);
      await gameTap(tester, 'colors-confirm');
      await gameTap(tester, 'colors-next-round');
      await gameTap(tester, 'colors-restart');
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Continuar jogando'));
      await tester.pumpAndSettle();
      expect(game.round, 2);
      await gameTap(tester, 'colors-restart');
      await tester.tap(find.text('Descartar partida'));
      await tester.pumpAndSettle();
      expect(find.text('Rodada 1/5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'system back asks once, cancel preserves the route, discard pops to Home',
    (tester) async {
      final catalog = trainingFixture();
      await warmTrainingAssets(tester, catalog);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () => context.push('/colors/train'),
                child: const Text('Start training'),
              ),
            ),
          ),
          GoRoute(
            path: '/colors/train',
            builder: (context, state) => ColorTrainingScreen(
              catalog: catalog,
              session: fixedTraining(catalog),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.dark,
          locale: const Locale('pt'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start training'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Continuar jogando'));
      await tester.pumpAndSettle();
      // Imperative GoRouter pushes do not update the address by default.
      expect(find.byType(ColorTrainingScreen), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      final back = tester
          .widget<IconButton>(
            find
                .ancestor(
                  of: find.byTooltip('Voltar'),
                  matching: find.byType(IconButton),
                )
                .first,
          )
          .onPressed!;
      back();
      back();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Descartar partida'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/');
      expect(find.byType(ColorTrainingScreen), findsNothing);
      expect(find.text('Start training'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final config in [
    (390.0, 844.0, 1.0, 'pt'),
    (320.0, 640.0, 2.0, 'pt'),
    (1024.0, 768.0, 1.0, 'pt'),
    (320.0, 640.0, 2.0, 'en'),
    (320.0, 640.0, 2.0, 'es'),
  ]) {
    testWidgets(
      'complete flow fits $config, including hints, comparison, rules and final',
      (tester) async {
        final game = await pumpTraining(
          tester,
          width: config.$1,
          height: config.$2,
          scale: config.$3,
          language: config.$4,
        );
        final semantics = tester.ensureSemantics();
        try {
          await gameTap(tester, 'colors-help');
          expect(find.byType(BottomSheet), findsOneWidget);
          final l = AppL10n.of(
            tester.element(find.byType(ColorTrainingScreen)),
          );
          await tester.tap(find.text(l.colorClose));
          await tester.pumpAndSettle();
          await bodyScrollTo(
            tester,
            find.byKey(const ValueKey('colors-channel-2')),
          );
          await gameTap(tester, 'colors-channel-2');
          await bodyScrollTo(
            tester,
            find.byKey(const ValueKey('colors-brightness')),
          );
          expect(
            tester
                .widget<Slider>(find.byKey(const ValueKey('colors-brightness')))
                .semanticFormatterCallback,
            isNotNull,
          );
          await bodyScrollTo(
            tester,
            find.byKey(const ValueKey('colors-use-hint')),
          );
          await gameTap(tester, 'colors-use-hint');
          for (var round = 1; round <= 5; round++) {
            await gameTap(tester, 'colors-confirm');
            await gameTap(tester, 'colors-next-round');
          }
          expect(game.phase, ColorRoundPhase.finished);
          expect(game.averageCents, isNotNull);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
