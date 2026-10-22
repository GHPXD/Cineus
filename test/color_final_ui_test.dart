import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/domain/entities/color_training_session.dart';
import 'package:cineus/presentation/widgets/color_controls.dart';
import 'package:cineus/presentation/screens/color_session_screen.dart';
import 'package:cineus/presentation/screens/color_training_screen.dart';
import 'package:cineus/presentation/screens/color_credits_screen.dart';
import 'color_persistence_ui_test.dart' show ColorUiFixture, settleColors;
import 'color_integration_ui_test.dart'
    show colorTap, colorScrollTo, warmColorIntegration;
import 'color_training_session_test.dart' show trainingFixture;

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  test(
    'credits match all characters, original art origin and public HTTPS sources',
    () {
      final decoded =
          jsonDecode(
                File('assets/credits/colors_sources.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final rows = (decoded['characters'] as List).cast<Map<String, dynamic>>();
      expect(rows.length, 50);
      expect(
        rows.map((r) => r['id']).toSet(),
        trainingFixture().questions.map((q) => q.characterId).toSet(),
      );
      expect(rows.where((r) => r['art_origin'] == 'generated').length, 26);
      expect(
        rows
            .where((r) => r['art_origin'] == 'reference')
            .every((r) => (r['art_urls'] as List).length == 2),
        true,
      );
      for (final r in rows) {
        for (final url in [r['study_url'], ...r['art_urls'] as List]) {
          expect(Uri.parse(url as String).scheme, 'https');
        }
        expect(r.containsKey('target_hex'), false);
        expect(jsonEncode(r), isNot(contains('C:\\Users')));
        for (final lang in ['pt', 'en', 'es']) {
          expect(r['copy'][lang]['character'], isNotEmpty);
          expect(r['copy'][lang]['work'], isNotEmpty);
        }
      }
    },
  );
  testWidgets(
    'exact comma decimal persists and a cancelled edit never changes the answer',
    (tester) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
        await f.seed();
      });
      await warmColorIntegration(tester, f);
      await tester.pumpWidget(
        f.app(child: const ColorSessionScreen(sessionId: 'training:fixture')),
      );
      await settleColors(tester);
      await colorTap(
        tester,
        'colors-hue-exact',
        scrollKey: 'colors-game-scroll',
      );
      await tester.enterText(
        find.byKey(const ValueKey('colors-hue-input')),
        '56,25',
      );
      await colorTap(tester, 'colors-exact-apply');
      final c = tester
          .widget<ColorTrainingScreen>(find.byType(ColorTrainingScreen))
          .controller!;
      expect(c.game.selection.hue, 56.25);
      expect(c.game.phase, ColorRoundPhase.answering);
      expect(c.game.answers, isEmpty);
      await tester.runAsync(() async {
        expect(
          (await f.repo.load('training:fixture'))!.game.selection.hue,
          56.25,
        );
      });
      await colorTap(
        tester,
        'colors-hue-exact',
        scrollKey: 'colors-game-scroll',
      );
      await tester.enterText(
        find.byKey(const ValueKey('colors-hue-input')),
        '123',
      );
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(c.game.selection.hue, 56.25);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(f.db.close);
    },
  );
  testWidgets(
    'invalid numeric input remains editable and never confirms a round',
    (tester) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
        await f.seed();
      });
      await warmColorIntegration(tester, f);
      await tester.pumpWidget(
        f.app(child: const ColorSessionScreen(sessionId: 'training:fixture')),
      );
      await settleColors(tester);
      await colorTap(
        tester,
        'colors-hue-exact',
        scrollKey: 'colors-game-scroll',
      );
      for (final input in ['NaN', 'Infinity', '-1', '361', 'abc']) {
        await tester.enterText(
          find.byKey(const ValueKey('colors-hue-input')),
          input,
        );
        await colorTap(tester, 'colors-exact-apply');
        expect(find.text('Digite um número entre 0 e 360.'), findsOneWidget);
      }
      final c = tester
          .widget<ColorTrainingScreen>(find.byType(ColorTrainingScreen))
          .controller!;
      expect(c.game.selection.hue, 200);
      expect(c.game.answers, isEmpty);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(f.db.close);
    },
  );
  testWidgets(
    'nudge bounds and disabled controls have matching callbacks and labels',
    (tester) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
      });
      await warmColorIntegration(tester, f);
      ColorSelection choice = ColorSelection(0, 100, 0);
      int writes = 0;
      await tester.pumpWidget(
        f.app(
          child: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (c, update) => ColorControls(
                  selection: choice,
                  onChanged: (s) => update(() => choice = s),
                  onChangeEnd: () => writes++,
                ),
              ),
            ),
          ),
        ),
      );
      await settleColors(tester);
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('colors-hue-less')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('colors-saturation-more')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('colors-hue-more')));
      await tester.pump();
      expect(choice.hue, 1);
      expect(writes, 1);
      expect(find.byTooltip('Aumentar Tom'), findsOneWidget);
      await tester.pumpWidget(
        f.app(
          child: Scaffold(
            body: ColorControls(
              selection: choice,
              onChanged: (_) => writes++,
              enabled: false,
            ),
          ),
        ),
      );
      await tester.pump();
      for (final slider in tester.widgetList<Slider>(find.byType(Slider))) {
        expect(slider.onChanged, isNull);
      }
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('colors-hue-exact')))
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(f.db.close);
    },
  );
  for (final lang in ['pt', 'en', 'es']) {
    testWidgets('precision dialog and credits fit 320px / 200% in $lang', (
      tester,
    ) async {
      late ColorUiFixture f;
      await tester.runAsync(() async {
        f = await ColorUiFixture.create();
        await f.seed();
      });
      await warmColorIntegration(tester, f);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        f.app(
          child: const ColorSessionScreen(sessionId: 'training:fixture'),
          scale: 2,
          language: lang,
        ),
      );
      await settleColors(tester);
      await colorTap(
        tester,
        'colors-hue-exact',
        scrollKey: 'colors-game-scroll',
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey('colors-hue-input')),
        '56.25',
      );
      await colorTap(tester, 'colors-exact-apply');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        f.app(child: const ColorCreditsScreen(), scale: 2, language: lang),
      );
      await settleColors(tester);
      expect(
        find.byKey(const ValueKey('colors-credits-scroll')),
        findsOneWidget,
        reason: tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data)
            .join(' | '),
      );
      await colorScrollTo(tester, find.text('Aang'), 'colors-credits-scroll');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(f.db.close);
    });
  }
}
