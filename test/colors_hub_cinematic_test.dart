import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/screens/color_stages_screen.dart';
import 'package:cineus/presentation/screens/color_training_screen.dart';
import 'package:cineus/presentation/screens/stats_screen.dart';
import 'package:cineus/presentation/providers/color_providers.dart';
import 'color_persistence_ui_test.dart' show ColorUiFixture, settleColors;
import 'color_integration_ui_test.dart' show warmColorIntegration;
import 'color_persistence_test.dart' show finishColors;

Future<void> withCinematicColors(
  WidgetTester tester,
  Future<void> Function(ColorUiFixture, ProviderContainer, GoRouter) action, {
  DateTime Function()? now,
  Future<void> Function(ColorUiFixture)? seed,
  double scale = 1,
  String language = 'pt',
  double width = 390,
}) async {
  late ColorUiFixture f;
  await tester.runAsync(() async {
    f = await ColorUiFixture.create(now: now);
    if (seed != null) await seed(f);
  });
  await warmColorIntegration(tester, f);
  final router = AppRouter.create(initialLocation: '/colors');
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    RepaintBoundary(
      key: const ValueKey('stage-list-capture'),
      child: f.routedApp(router, scale: scale, language: language),
    ),
  );
  final c = ProviderScope.containerOf(
    tester.element(find.byType(ColorStagesScreen)),
  );
  await settleColors(tester);
  await tester.runAsync(() async {
    await c.read(ticketNotifierProvider.notifier).ready;
  });
  await settleColors(tester);
  try {
    await settleColors(tester);
    expect(
      c.read(colorStageProgressProvider).hasError,
      false,
      reason: c.read(colorStageProgressProvider).error.toString(),
    );
    expect(
      c.read(colorStageProgressProvider).hasValue,
      true,
      reason:
          'catalog=${c.read(colorStageCatalogProvider)} sessions=${c.read(colorSessionsProvider)} progress=${c.read(colorStageProgressProvider)}',
    );
    await action(f, c, router);
    expect(tester.takeException(), isNull);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await tester.runAsync(f.db.close);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }
}

Future<void> tapHub(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    finder,
    140,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('colors-hub-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pump();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await settleColors(tester);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'stage browsing is free; rapid start charges once; completion unlocks following match and stage',
    (tester) async {
      await withCinematicColors(tester, (f, c, router) async {
        expect(find.byKey(const ValueKey('colors-daily-action')), findsNothing);
        expect(
          find.byKey(const ValueKey('colors-training-action')),
          findsNothing,
        );
        await tapHub(tester, 'colors-stage-1');
        expect(c.read(ticketNotifierProvider).total, 10);
        expect(
          find.byKey(const ValueKey('colors-stage-match-0')),
          findsOneWidget,
        );
        final button = tester.widget<FilledButton>(
          find.byKey(const ValueKey('colors-stage-match-0')),
        );
        button.onPressed!();
        button.onPressed!();
        for (
          var i = 0;
          i < 8 && find.byType(ColorTrainingScreen).evaluate().isEmpty;
          i++
        ) {
          await settleColors(tester);
        }
        expect(find.byType(ColorTrainingScreen), findsOneWidget);
        expect(c.read(ticketNotifierProvider).total, 9);
        var controller = tester
            .widget<ColorTrainingScreen>(find.byType(ColorTrainingScreen))
            .controller!;
        expect(controller.record.stageId, 1);
        expect(
          controller.record.game.questions.map((q) => q.characterId).toSet(),
          hasLength(5),
        );
        expect(find.byKey(const ValueKey('colors-restart')), findsNothing);
        router.pop();
        await settleColors(tester);
        await tester.pumpAndSettle();
        final resume = tester.widget<FilledButton>(
          find.byKey(const ValueKey('colors-stage-match-0')),
        );
        resume.onPressed!();
        await settleColors(tester);
        expect(c.read(ticketNotifierProvider).total, 9);
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
        router.pop();
        await settleColors(tester);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('colors-stage-match-1')),
          140,
          scrollable: find
              .descendant(
                of: find.byKey(const ValueKey('colors-stage-scroll')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        final second = tester.widget<FilledButton>(
          find.byKey(const ValueKey('colors-stage-match-1')),
        );
        expect(second.onPressed, isNotNull);
        second.onPressed!();
        await settleColors(tester);
        controller = tester
            .widget<ColorTrainingScreen>(find.byType(ColorTrainingScreen))
            .controller!;
        expect(controller.record.stageMatch, 1);
        expect(c.read(ticketNotifierProvider).total, 8);
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
        expect(
          (await tester.runAsync(
            () => c.read(colorStageProgressProvider.future),
          ))![1].locked,
          false,
        );
        router.pop();
        await settleColors(tester);
        await tester.pumpAndSettle();
        expect(find.byType(ColorStagesScreen), findsOneWidget);
        expect(c.read(ticketNotifierProvider).total, 8);
      });
    },
  );
  testWidgets(
    'legacy training remains resumable from stages and statistics are reachable',
    (tester) async {
      await withCinematicColors(
        tester,
        (f, c, router) async {
          final legacy = find.text('Retomar treino anterior');
          await tester.scrollUntilVisible(
            legacy,
            140,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('colors-hub-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await Scrollable.ensureVisible(tester.element(legacy), alignment: .5);
          await tester.pump();
          await tester.tap(legacy);
          await settleColors(tester);
          expect(find.byType(ColorTrainingScreen), findsOneWidget);
          expect((await tester.runAsync(f.repo.list))!.length, 1);
          expect(c.read(ticketNotifierProvider).total, 10);
          router.pop();
          await settleColors(tester);
          await tester.pumpAndSettle();
          await tester.drag(
            find.byKey(const ValueKey('colors-hub-scroll')),
            const Offset(0, -1800),
          );
          await tester.pump();
          expect(find.text('Ver minhas estatísticas'), findsNothing);
          expect(find.text('Ver meu histórico'), findsNothing);
          expect(
            find.text('Os desafios diários estão no Início.'),
            findsNothing,
          );
          router.go('/stats');
          await settleColors(tester);
          await tester.tap(find.byKey(const ValueKey('stats-mode-colors')));
          await settleColors(tester);
          expect(find.byType(StatsScreen), findsOneWidget);
        },
        seed: (f) async {
          await f.seed();
        },
      );
    },
  );
  for (final config in [
    (390.0, 1.0, 'pt'),
    (320.0, 2.0, 'pt'),
    (320.0, 2.0, 'en'),
    (320.0, 2.0, 'es'),
    (1024.0, 1.0, 'pt'),
  ]) {
    testWidgets('stages and match actions fit $config', (tester) async {
      await withCinematicColors(
        tester,
        (f, c, router) async {
          await tapHub(tester, 'colors-stage-1');
          expect(
            find.byKey(const ValueKey('colors-daily-action')),
            findsNothing,
          );
          final button = find.byKey(const ValueKey('colors-stage-match-0'));
          await tester.scrollUntilVisible(
            button,
            140,
            scrollable: find
                .descendant(
                  of: find.byKey(const ValueKey('colors-stage-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await Scrollable.ensureVisible(tester.element(button), alignment: .5);
          await tester.pump();
          expect(button.hitTestable(), findsOneWidget);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          expect(c.read(ticketNotifierProvider).total, 10);
        },
        width: config.$1,
        scale: config.$2,
        language: config.$3,
      );
    });
  }
}
