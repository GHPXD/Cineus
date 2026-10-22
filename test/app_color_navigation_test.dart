import 'package:cineus/presentation/widgets/stats_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/main_scaffold.dart';
import 'package:cineus/presentation/screens/color_training_screen.dart';
import 'package:cineus/presentation/screens/stats_screen.dart';
import 'package:cineus/presentation/screens/color_tutorial_screen.dart';
import 'package:cineus/presentation/screens/how_to_play_screen.dart';
import 'package:cineus/presentation/screens/settings_screen.dart';
import 'package:cineus/presentation/providers/providers.dart'
    show appMetaRepositoryProvider, ticketNotifierProvider;
import 'package:cineus/presentation/providers/journey_provider.dart';
import 'package:cineus/presentation/providers/progress_provider.dart';
import 'package:cineus/presentation/providers/monetization_notifier.dart';
import 'package:cineus/presentation/providers/color_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'color_persistence_ui_test.dart' show ColorUiFixture, settleColors;
import 'color_integration_ui_test.dart' show warmColorIntegration, colorTap;
import 'color_persistence_test.dart' show finishColors;

Future<void> productionNavigation(
  WidgetTester tester,
  String route,
  Future<void> Function(ColorUiFixture, GoRouter) action, {
  DateTime Function()? now,
}) async {
  final semantics = tester.ensureSemantics();
  late ColorUiFixture fixture;
  await tester.runAsync(() async {
    fixture = await ColorUiFixture.create(now: now);
    await fixture.seed();
  });
  final router = AppRouter.create(initialLocation: route);
  await warmColorIntegration(tester, fixture);
  final scope = fixture.routedApp(router) as ProviderScope;
  final container = ProviderContainer(overrides: scope.overrides);
  await tester.runAsync(() async {
    await container.read(ticketNotifierProvider.notifier).ready;
    await container.read(monetizationNotifierProvider.notifier).load();
    await container.read(journeyProgressProvider.future);
    await container.read(presenceProvider.future);
    await container.read(continuingGameProvider.future);
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: scope.child),
  );
  await settleColors(tester);
  try {
    await action(fixture, router);
    expect(tester.takeException(), isNull);
  } finally {
    // SQLite operations use the real event loop. Finish foreground loads before
    // closing the fixture, even when navigation starts them on the final frame.
    await tester.runAsync(() async {
      if (container.exists(ticketNotifierProvider)) {
        await container.read(ticketNotifierProvider.notifier).ready;
      }
      if (container.exists(journeyProgressProvider)) {
        await container.read(journeyProgressProvider.future);
      }
      if (container.exists(presenceProvider)) {
        await container.read(presenceProvider.future);
      }
      if (container.exists(continuingGameProvider)) {
        await container.read(continuingGameProvider.future);
      }
      if (container.exists(monetizationNotifierProvider)) {
        await container.read(monetizationNotifierProvider.notifier).load();
      }
    });
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    container.dispose();
    semantics.dispose();
    await tester.runAsync(fixture.db.close);
  }
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'voltar à aba após meia-noite preserva os estágios sem mostrar um diário',
    (tester) async {
      var instant = DateTime.utc(2026, 10, 13, 23, 59, 59);
      await productionNavigation(tester, '/colors', (f, router) async {
        expect(find.byKey(const ValueKey('colors-stage-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('colors-daily-action')), findsNothing);
        router.go('/home');
        await settleColors(tester);
        instant = DateTime.utc(2026, 10, 14);
        router.go('/colors');
        await settleColors(tester);
        expect(find.byKey(const ValueKey('colors-stage-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('colors-countdown')), findsNothing);
      }, now: () => instant);
    },
  );
  testWidgets('guia de Cores nas configurações volta à tela de origem', (
    tester,
  ) async {
    await productionNavigation(tester, '/home', (f, router) async {
      router.push('/settings');
      await settleColors(tester);
      await tester.scrollUntilVisible(
        find.text('Como jogar Cores'),
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Como jogar Cores'));
      await settleColors(tester);
      expect(find.byType(ColorGuideScreen), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar').hitTestable().first);
      await settleColors(tester);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(ColorGuideScreen), findsNothing);
      expect(find.text('Como jogar Cores'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    'consultar Cores durante onboarding mantém o guia inicial pendente',
    (tester) async {
      await productionNavigation(tester, '/how-to-play?first=1', (
        f,
        router,
      ) async {
        await tester.tap(find.byKey(const ValueKey('guide-mode-colors')));
        await settleColors(tester);
        await tester.ensureVisible(
          find.byKey(const ValueKey('guide-open-colors')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('guide-open-colors')));
        await settleColors(tester);
        expect(find.byType(ColorGuideScreen), findsOneWidget);
        await tester.tap(find.byTooltip('Voltar').first);
        await settleColors(tester);
        expect(
          tester
              .widget<HowToPlayScreen>(find.byType(HowToPlayScreen))
              .isOnboarding,
          true,
        );
        final container = ProviderScope.containerOf(
          tester.element(find.byType(HowToPlayScreen)),
        );
        expect(
          await tester.runAsync(
            () => container.read(appMetaRepositoryProvider).hasSeenOnboarding(),
          ),
          false,
        );
      });
    },
  );

  testWidgets(
    'estatísticas abertas pelo resultado selecionam a aba Cores sem duplicar navegadores',
    (tester) async {
      await productionNavigation(tester, '/colors', (f, router) async {
        router.push('/colors/train');
        await settleColors(tester);
        final controller = tester
            .widget<ColorTrainingScreen>(find.byType(ColorTrainingScreen))
            .controller!;
        expect(
          await tester.runAsync(
            () => controller.act((game) {
              finishColors(game);
              return true;
            }),
          ),
          true,
        );
        await settleColors(tester);
        await colorTap(
          tester,
          'colors-result-stats',
          scrollKey: 'colors-game-scroll',
        );
        await settleColors(tester);
        expect(find.byType(StatsScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('nav-colors')).hitTestable(),
          findsNothing,
        );
        expect(
          router.routeInformationProvider.value.uri.toString(),
          '/stats?mode=colors',
        );
      });
    },
  );

  testWidgets(
    'hub é a quarta aba; subpáginas mantêm a navegação e partidas ocupam a tela',
    (tester) async {
      await productionNavigation(tester, '/colors', (f, router) async {
        expect(find.byType(MainScaffold), findsOneWidget);
        expect(find.byKey(const ValueKey('nav-colors')), findsOneWidget);
        expect(find.byTooltip('Voltar'), findsNothing);
        for (final path in ['/colors/history', '/colors/credits']) {
          router.go(path);
          await settleColors(tester);
          expect(find.byType(MainScaffold), findsOneWidget);
          expect(find.byKey(const ValueKey('nav-colors')), findsOneWidget);
          router.pop();
          await settleColors(tester);
          expect(router.routeInformationProvider.value.uri.path, '/colors');
        }
        router.push('/colors/train');
        await settleColors(tester);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('nav-colors')).hitTestable(),
          findsNothing,
        );
        expect(find.byType(ColorTrainingScreen), findsOneWidget);
      });
    },
  );

  testWidgets(
    'resultado confirmado atualiza o hub e estatísticas ao voltar pelo sistema',
    (tester) async {
      await productionNavigation(tester, '/colors', (f, router) async {
        router.push('/colors/train');
        await settleColors(tester);
        final controller = tester
            .widget<ColorTrainingScreen>(find.byType(ColorTrainingScreen))
            .controller!;
        final saved = await tester.runAsync(
          () => controller.act((game) {
            finishColors(game);
            return true;
          }),
        );
        expect(saved, true);
        await settleColors(tester);
        await tester.binding.handlePopRoute();
        await settleColors(tester);
        expect(router.routeInformationProvider.value.uri.path, '/colors');
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MainScaffold)),
        );
        final overview = await tester.runAsync(
          () => container.read(colorHomeOverviewProvider.future),
        );
        expect(overview!.training, isNull);
        expect(overview.trainingStats.games, 1);
        router.go('/colors/stats');
        await settleColors(tester);
        await tester.tap(find.byKey(const ValueKey('stats-mode-colors')));
        await settleColors(tester);
        expect(find.text('1'), findsWidgets);
      });
    },
  );

  testWidgets(
    'estatísticas gerais têm acesso a Cores e voltar sem pilha abre Início',
    (tester) async {
      await productionNavigation(tester, '/stats', (f, router) async {
        expect(find.byKey(const ValueKey('stats-mode-colors')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('stats-mode-colors')));
        await settleColors(tester);
        expect(find.byType(StatsScreen), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'abrir Cores a partir das estatísticas',
        );
        router.go('/stats?mode=colors');
        await settleColors(tester);
        expect(
          tester
              .widget<StatsTab>(find.byKey(const ValueKey('stats-mode-colors')))
              .selected,
          true,
        );
        router.go('/stats?mode=poster');
        await settleColors(tester);
        expect(
          tester
              .widget<StatsTab>(find.byKey(const ValueKey('stats-mode-poster')))
              .selected,
          true,
        );
        router.go('/stats');
        await settleColors(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'abrir estatísticas diretamente após Cores',
        );
        await tester.tap(find.byKey(const ValueKey('stats-back')));
        await settleColors(tester);
        expect(router.routeInformationProvider.value.uri.path, '/home');
      });
    },
  );
}
