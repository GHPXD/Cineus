import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/domain/entities/extra_hint.dart';
import 'package:cineus/domain/entities/saved_color_session.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/color_providers.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'package:cineus/presentation/providers/color_session_controller.dart';
import 'package:cineus/presentation/providers/monetization_notifier.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/color_training_screen.dart';
import 'package:cineus/presentation/visuals/cineus_assets.dart';
import 'package:cineus/presentation/widgets/round_help_sheet.dart';
import 'package:cineus/presentation/widgets/ticket_details_sheet.dart';
import 'color_training_session_test.dart' show trainingFixture;
import 'color_training_screen_test.dart' show warmTrainingAssets;
import 'monetization_experience_test.dart' show experience, warmExperience;
import 'player_collection_ui_test.dart' show collectionApp, settleCollection;
import 'round_help_test.dart' show HelpAds;

Future<void> captureHelp(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CINEUS_CAPTURE_UI')) return;
  await settleCollection(tester);
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('help-capture')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/preview/round-help/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void handset(WidgetTester tester, {double width = 390}) {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> routedHelp(
  WidgetTester tester,
  ProviderContainer c,
  String location,
) async {
  final router = AppRouter.create(initialLocation: location);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('help-capture'),
      child: UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: const Locale('pt'),
          supportedLocales: AppL10n.supportedLocales,
          localizationsDelegates: AppL10n.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    ),
  );
  await settleCollection(tester);
  final entry = find.byKey(const ValueKey('round-help-entry'));
  await tester.ensureVisible(entry);
  await settleCollection(tester);
  await tester.tap(entry);
  await settleCollection(tester);
}

void main() {
  for (final poster in [false, true]) {
    testWidgets(
      'real ${poster ? "poster" : "clue"} help uses one ticket and leaves normal scoring untouched',
      (tester) async {
        handset(tester);
        final c = await experience(
          tester,
          movies: true,
          overrides: [appClockProvider.overrideWithValue(DateTime.now)],
        );
        await warmExperience(tester);
        final provider = poster ? posterGameProvider : clueGameProvider;
        await tester.runAsync(() => c.read(provider.notifier).loadDaily());
        final before = c.read(provider).session!.potentialScore;
        expect(c.read(ticketNotifierProvider).total, 10);
        await routedHelp(tester, c, poster ? '/visual/play' : '/game');
        expect(find.byType(RoundHelpSheet), findsOneWidget);
        expect(
          tester
              .widget<OutlinedButton>(
                find.byKey(const ValueKey('help-watch-video')),
              )
              .onPressed,
          isNull,
        );
        await captureHelp(tester, poster ? '02-help-poster' : '01-help-clues');
        await tester.tap(find.byKey(const ValueKey('help-option-year')));
        await tester.tap(find.byKey(const ValueKey('help-pay-ticket')));
        await settleCollection(tester);
        expect(c.read(provider).purchasedHints, contains(ExtraHint.year));
        expect(c.read(provider).session!.potentialScore, before);
        expect(c.read(ticketNotifierProvider).total, 9);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'real Colors studio offers paid guidance and keeps free hint, persists guidance and its penalty',
    (tester) async {
      handset(tester);
      final c = await experience(tester);
      final catalog = trainingFixture();
      await warmExperience(tester);
      await warmTrainingAssets(tester, catalog);
      final record = (await tester.runAsync(
        () => c
            .read(colorRepositoryProvider)
            .start(catalog, ColorSessionKind.training),
      ))!;
      final controller = ColorSessionController(
        c.read(colorRepositoryProvider),
        record,
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('help-capture'),
          child: collectionApp(
            c,
            child: ColorTrainingScreen(
              catalog: catalog,
              controller: controller,
            ),
          ),
        ),
      );
      await settleCollection(tester);
      await tester.tap(find.byKey(const ValueKey('colors-use-hint')));
      await settleCollection(tester);
      expect(find.byKey(const ValueKey('help-free-hint')), findsOneWidget);
      await captureHelp(tester, '03-help-colors');
      await tester.tap(find.byKey(const ValueKey('help-pay-ticket')));
      await settleCollection(tester);
      expect(controller.game.guidanceAt, isNotNull);
      expect(controller.game.hintUsed, isTrue);
      expect(c.read(ticketNotifierProvider).total, 9);
      final saved = await tester.runAsync(
        () => c.read(colorRepositoryProvider).load(record.id),
      );
      expect(saved!.game.guidanceAt, isNotNull);
      await captureHelp(tester, '04-colors-guidance');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'controlled rewarded video unlocks help plus one ticket, never a production preview grant',
    (tester) async {
      handset(tester);
      final ads = HelpAds()
        ..available = true
        ..completed = true;
      final c = await experience(
        tester,
        movies: true,
        overrides: [
          monetizationServiceProvider.overrideWithValue(ads),
          appClockProvider.overrideWithValue(DateTime.now),
        ],
      );
      await warmExperience(tester);
      await tester.runAsync(
        () => c.read(clueGameProvider.notifier).loadDaily(),
      );
      await routedHelp(tester, c, '/game');
      await tester.tap(find.byKey(const ValueKey('help-option-year')));
      await captureHelp(tester, '06-help-video-test');
      await tester.tap(find.byKey(const ValueKey('help-watch-video')));
      for (
        var i = 0;
        c.read(clueGameProvider).purchasedHints.isEmpty && i < 25;
        i++
      ) {
        await settleCollection(tester);
      }
      expect(c.read(clueGameProvider).purchasedHints, contains(ExtraHint.year));
      expect(c.read(ticketNotifierProvider).total, 11);
      expect(ads.shown, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(
        () => c.read(monetizationNotifierProvider.notifier).load(),
      );
    },
  );

  testWidgets('wallet renders new ten-ticket allowance', (tester) async {
    handset(tester);
    final c = await experience(tester);
    await warmExperience(tester);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('help-capture'),
        child: collectionApp(
          c,
          child: const Scaffold(body: TicketDetailsSheet()),
        ),
      ),
    );
    await settleCollection(tester);
    expect(find.text('10 de 10'), findsOneWidget);
    await captureHelp(tester, '05-balance-10');
    expect(tester.takeException(), isNull);
  });

  for (final lang in ['pt', 'en', 'es']) {
    testWidgets('help sheet fits 320px at 200% in $lang', (tester) async {
      handset(tester, width: 320);
      final c = await experience(tester);
      await tester.pumpWidget(
        collectionApp(
          c,
          language: lang,
          scale: 2,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                final l = AppL10n.of(context);
                return RoundHelpSheet(
                  gameKey: 'clue:1',
                  options: [
                    RoundHelpOption(
                      id: 'director',
                      title: l.hintDirector,
                      asset: CineusAssetId.hintDirector,
                      purchase: () async => false,
                    ),
                    RoundHelpOption(
                      id: 'year',
                      title: l.hintYear,
                      asset: CineusAssetId.hintYear,
                      purchase: () async => false,
                    ),
                  ],
                  freeHint: () async => false,
                );
              },
            ),
          ),
        ),
      );
      await settleCollection(tester);
      await tester.drag(
        find.byKey(const ValueKey('round-help-scroll')),
        const Offset(0, -600),
      );
      await settleCollection(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
