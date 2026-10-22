import 'package:cineus/presentation/widgets/stats_dashboard.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/splash_screen.dart';
import 'package:cineus/presentation/screens/color_training_screen.dart';
import '../test/color_persistence_test.dart' show finishColors;
import '../test/color_integration_ui_test.dart' show colorTap;
import '../test/color_persistence_ui_test.dart'
    show ColorUiFixture, settleColors;
import '../test/color_integration_ui_test.dart' show warmColorIntegration;

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets('render cinematic Home with production router and generated art', (
    tester,
  ) async {
    final root = Directory('docs/preview');
    final boundary = GlobalKey();
    final errors = <String>[];
    final rows = <Map<String, Object?>>[];
    final originalHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
      originalHandler?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalHandler);
    await tester.runAsync(() async {
      await Directory('${root.path}/screens').create(recursive: true);
      for (final entry in {
        'Fredoka': ['Fredoka-600.ttf', 'Fredoka-700.ttf'],
        'Nunito': ['Nunito-400.ttf', 'Nunito-500.ttf', 'Nunito-600.ttf'],
      }.entries) {
        final loader = FontLoader(entry.key);
        for (final font in entry.value) {
          loader.addFont(rootBundle.load('assets/fonts/$font'));
        }
        await loader.load();
      }
      for (final file
          in Directory('assets/generated/icons')
              .listSync()
              .whereType<File>()
              .where((file) => file.path.endsWith('.svg'))) {
        await SvgAssetLoader(file.path.replaceAll('\\', '/')).loadBytes(null);
      }
    });
    const quick = bool.fromEnvironment('HOME_CAPTURE_QUICK');
    final configs = quick
        ? [(390.0, 844.0, 1.0, 'pt')]
        : [
            (360.0, 800.0, 1.0, 'pt'),
            (390.0, 844.0, 1.0, 'pt'),
            (430.0, 932.0, 1.0, 'pt'),
            (1024.0, 768.0, 1.0, 'pt'),
            (320.0, 640.0, 2.0, 'pt'),
            (320.0, 640.0, 2.0, 'en'),
            (320.0, 640.0, 2.0, 'es'),
          ];
    for (final config in configs) {
      tester.view.physicalSize = Size(config.$1, config.$2);
      tester.view.devicePixelRatio = 1;
      late ColorUiFixture fixture;
      await tester.runAsync(() async {
        fixture = await ColorUiFixture.create(
          now: () => DateTime.utc(2026, 10, 13, 20, 31, 37),
        );
        await const DatabaseSeeder().seedFromJsonAsset(fixture.db);
        await const DatabaseSeeder().syncStages(fixture.db);
      });
      await warmColorIntegration(tester, fixture);
      final router = AppRouter.create(initialLocation: '/colors');
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: fixture.routedApp(
            router,
            scale: config.$3,
            language: config.$4,
          ),
        ),
      );
      await settleColors(tester);
      await tester.pumpAndSettle();
      Future<void> capture(String scenario) async {
        await settleColors(tester);
        await tester.pumpAndSettle();
        final name =
            'colors_${scenario}_${config.$1.toInt()}_${config.$3.toInt()}x_${config.$4}.png';
        await tester.runAsync(() async {
          final rendered =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          try {
            final bytes = await rendered.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '${root.path}/screens/$name',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            rendered.dispose();
          }
        });
        rows.add({
          'route': scenario.startsWith('splash')
              ? '/'
              : router.routeInformationProvider.value.uri.path,
          'scenario': scenario,
          'file': name,
          'width': config.$1,
          'height': config.$2,
          'textScale': config.$3,
          'language': config.$4,
          'pixelRatio': 2,
          'errors': List<String>.of(errors),
        });
        expect(errors, isEmpty, reason: '$scenario $config');
        errors.clear();
      }

      await capture('stages');
      router.push('/colors/guide');
      await settleColors(tester);
      await capture('guide');
      router.pop();
      await settleColors(tester);
      router.go('/stats');
      await settleColors(tester);
      await capture('stats');
      router.go('/colors/stats');
      await settleColors(tester);
      expect(
        tester
            .widget<StatsTab>(find.byKey(const ValueKey('stats-mode-colors')))
            .selected,
        true,
      );
      await capture('colors_stats');
      await tester.tap(find.byKey(const ValueKey('stats-achievements')));
      await settleColors(tester);
      await capture('achievements');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('achievement-poster_first')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('stats-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await settleColors(tester);
      await capture('new_achievements');
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('achievement-colors_stages_3')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('stats-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await settleColors(tester);
      await capture('color_achievements');
      router.go('/home');
      await settleColors(tester);
      await capture('home');
      router.go('/stages');
      await settleColors(tester);
      await capture('films');
      await tester.tap(find.byKey(const ValueKey('current-stage')));
      await settleColors(tester);
      await capture('film_matches');
      router.go('/visual');
      await settleColors(tester);
      await capture('posters');
      await tester.tap(find.byKey(const ValueKey('current-stage')));
      await settleColors(tester);
      await capture('poster_matches');
      router.go('/colors');
      await settleColors(tester);
      await colorTap(
        tester,
        'colors-stage-open',
        scrollKey: 'colors-hub-scroll',
      );
      await settleColors(tester);
      await capture('detail');
      await colorTap(
        tester,
        'colors-stage-match-0',
        scrollKey: 'colors-stage-scroll',
      );
      await settleColors(tester);
      await capture('game');
      var controller = tester
          .widget<ColorTrainingScreen>(find.byType(ColorTrainingScreen))
          .controller!;
      await tester.runAsync(
        () => controller.act((game) {
          finishColors(game);
          return true;
        }),
      );
      await settleColors(tester);
      router.pop();
      await settleColors(tester);
      await tester.pumpAndSettle();
      await capture('second_match_unlocked');
      await colorTap(
        tester,
        'colors-stage-match-1',
        scrollKey: 'colors-stage-scroll',
      );
      await settleColors(tester);
      controller = tester
          .widget<ColorTrainingScreen>(find.byType(ColorTrainingScreen))
          .controller!;
      await tester.runAsync(
        () => controller.act((game) {
          finishColors(game);
          return true;
        }),
      );
      await settleColors(tester);
      router.go('/colors');
      await settleColors(tester);
      await capture('next_stage_unlocked');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: fixture.app(
            child: SplashScreen(
              onComplete: () {},
              minimumDuration: const Duration(seconds: 10),
            ),
            scale: config.$3,
            language: config.$4,
          ),
        ),
      );
      if (config.$1 == 390) {
        // These are actual renderer frames; don't settle the animation between them.
        for (var frame = 0; frame < 8; frame++) {
          if (frame > 0) await tester.pump(const Duration(milliseconds: 100));
          final name = 'splash_frame_$frame.png';
          await tester.runAsync(() async {
            final rendered =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final data = await rendered.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '${root.path}/screens/$name',
            ).writeAsBytes(data!.buffer.asUint8List());
            rendered.dispose();
          });
        }
      } else {
        await tester.pump(const Duration(milliseconds: 700));
      }
      await capture('splash');
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      await tester.runAsync(fixture.db.close);
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    await tester.runAsync(
      () => File(
        '${root.path}/layout_diagnostics.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(rows)),
    );
  }, timeout: const Timeout(Duration(minutes: 5)));
}
