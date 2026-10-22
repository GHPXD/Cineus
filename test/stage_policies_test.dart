import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'film_stages_cinematic_test.dart' show withFilmScreen;
import 'colors_hub_cinematic_test.dart' show withCinematicColors;

Future<void> compactStageCapture(WidgetTester tester, String mode) async {
  if (!const bool.fromEnvironment('CINEUS_CAPTURE_COMPACT_STAGES')) return;
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('stage-list-capture')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/preview/compact-stages-2026-10-22/$mode.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  for (final config in [(390.0, 1.0), (320.0, 2.0)]) {
    testWidgets(
      'three category lists reclaim the removed header space $config',
      (tester) async {
        await tester.runAsync(() async {
          for (final font in ['Nunito', 'Fredoka']) {
            final loader = FontLoader(font);
            for (final weight in font == 'Nunito' ? [400, 600] : [600, 700]) {
              loader.addFont(rootBundle.load('assets/fonts/$font-$weight.ttf'));
            }
            await loader.load();
          }
        });
        Future<void> inspect(String mode) async {
          for (final key in [
            'stage-policy-0',
            'stage-policy-1',
            'films-featured',
            'posters-featured',
            'colors-featured-stage',
            'current-stage',
          ]) {
            expect(find.byKey(ValueKey(key)), findsNothing);
          }
          expect(find.text('SEU PRÓXIMO ESTÁGIO'), findsNothing);
          expect(find.text('Ver partidas'), findsNothing);
          expect(find.text('1 ticket'), findsNothing);
          final first = find.byKey(
            ValueKey(mode == 'colors' ? 'colors-stage-1' : 'stage-1'),
          );
          expect(first.hitTestable(), findsOneWidget);
          if (config.$2 == 1) {
            expect(tester.getTopLeft(first).dy, lessThan(300));
            await compactStageCapture(tester, mode);
          }
          expect(tester.takeException(), isNull);
        }

        await withFilmScreen(
          tester,
          (f, c, repo, router) async => inspect('films'),
          width: config.$1,
          scale: config.$2,
        );
        await withFilmScreen(
          tester,
          (f, c, repo, router) async => inspect('posters'),
          width: config.$1,
          scale: config.$2,
          poster: true,
        );
        await withCinematicColors(
          tester,
          (f, c, router) async => inspect('colors'),
          width: config.$1,
          scale: config.$2,
        );
      },
    );
  }
}
