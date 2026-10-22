import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/domain/entities/color_daily_selector.dart';
import 'package:cineus/presentation/screens/color_training_screen.dart';
import 'package:cineus/presentation/widgets/color_character_art.dart';
import 'color_persistence_ui_test.dart' show ColorUiFixture, settleColors;
import 'color_integration_ui_test.dart' show warmColorIntegration, colorTap;
import 'color_training_session_test.dart' show trainingFixture, fixedTraining;

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  test(
    'every original question remains byte-equivalent as JSON after expansion',
    () {
      final old =
          jsonDecode(
                File('test/fixtures/color_training_v1.json').readAsStringSync(),
              )
              as Map;
      final current =
          jsonDecode(File('assets/colors/training_v1.json').readAsStringSync())
              as Map;
      expect(
        (current['questions'] as List).take(50).toList(),
        old['questions'],
      );
      expect(old['pack_version'], 'training-1');
      expect(current['pack_version'], 'training-3');
    },
  );
  test(
    'the expanded daily draw is deterministic, distinct and reaches the full roster',
    () {
      final catalog = trainingFixture();
      final seen = <String>{};
      for (var day = 0; day < 366; day++) {
        final date = DateTime.utc(
          2026,
        ).add(Duration(days: day)).toIso8601String().substring(0, 10);
        final a = ColorDailySelector.draw(catalog, date);
        final b = ColorDailySelector.draw(catalog, date);
        expect(a.questions.map((q) => q.id), b.questions.map((q) => q.id));
        expect(a.questions.map((q) => q.characterId).toSet().length, 5);
        seen.addAll(a.questions.map((q) => q.characterId));
      }
      expect(seen.length, 50);
    },
  );
  test('new part labels identify the region without giving away its hue', () {
    final catalog = trainingFixture();
    final colourWords = RegExp(
      r'\b(azul|azuis|verde|cinza|amarelo|dourada|vermelha|rosa|blue|green|grey|gray|yellow|golden|red|pink|rojo|roja|gris|amarillo|dorado|rosado)\b',
    );
    for (final question in catalog.questions.skip(50)) {
      for (final lang in ['pt', 'en', 'es']) {
        expect(
          colourWords.hasMatch(question.text('part', lang).toLowerCase()),
          false,
          reason: '${question.id}/$lang',
        );
      }
    }
  });
  for (final language in ['pt', 'en', 'es']) {
    testWidgets(
      'zoom keeps the chosen colour and leaves the round untouched at 320px / 200% in $language',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        late ColorUiFixture fixture;
        await tester.runAsync(
          () async => fixture = await ColorUiFixture.create(),
        );
        await warmColorIntegration(tester, fixture);
        final game = fixedTraining(fixture.catalog);
        final before = jsonEncode(game.toJson());
        await tester.pumpWidget(
          fixture.app(
            child: ColorTrainingScreen(
              catalog: fixture.catalog,
              session: game,
              onBack: () {},
            ),
            scale: 2,
            language: language,
          ),
        );
        await settleColors(tester);
        await colorTap(
          tester,
          'colors-enlarge',
          scrollKey: 'colors-game-scroll',
        );
        await tester.pumpAndSettle();
        final viewer = find.byKey(const ValueKey('colors-character-zoom'));
        expect(viewer, findsOneWidget);
        expect(tester.widget<InteractiveViewer>(viewer).maxScale, 5);
        final art = tester.widget<ColorCharacterArt>(
          find.descendant(of: viewer, matching: find.byType(ColorCharacterArt)),
        );
        expect(art.choice.hex, game.selection.rgb.hex);
        await tester.tap(
          find.byKey(const ValueKey('colors-character-zoom-close')),
        );
        await tester.pumpAndSettle();
        expect(viewer, findsNothing);
        expect(jsonEncode(game.toJson()), before);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(fixture.db.close);
      },
    );
  }
}
