import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/screens/main_scaffold.dart';

GoRouter _router({String initialLocation = '/stages'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const Center(child: Text('HOME_ROOT')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stages',
                builder: (context, state) => Center(
                  child: ElevatedButton(
                    onPressed: () => context.push('/stages/7'),
                    child: const Text('OPEN_STAGE'),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) => Center(
                      child: Text('STAGE_${state.pathParameters['id']}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/visual',
                builder: (_, __) => const Center(child: Text('POSTER_ROOT')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/colors',
                builder: (_, __) => const Center(child: Text('COLORS_ROOT')),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (_, __) =>
                        const Center(child: Text('COLORS_HISTORY')),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

Widget _app(GoRouter router, {double textScale = 1}) {
  return MaterialApp.router(
    locale: const Locale('pt'),
    localizationsDelegates: const [
      AppL10n.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppL10n.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    routerConfig: router,
  );
}

void main() {
  testWidgets(
    'Cores preserva histórico ao trocar de aba e re-seleção volta ao hub',
    (tester) async {
      final router = _router(initialLocation: '/colors/history');
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();
      expect(find.text('COLORS_HISTORY'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-home')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-colors')));
      await tester.pumpAndSettle();
      expect(find.text('COLORS_HISTORY'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nav-colors')));
      await tester.pumpAndSettle();
      expect(find.text('COLORS_ROOT'), findsOneWidget);
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(1024, 768),
    const Size(1024, 320),
  ]) {
    testWidgets('quatro destinos acessíveis em $size com fonte 200%', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = _router(initialLocation: '/colors');
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router, textScale: 2));
      await tester.pumpAndSettle();
      for (final label in ['Início', 'Filmes', 'Posters', 'Cores']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('COLORS_ROOT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tabs preservam a própria pilha e re-seleção volta à raiz', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OPEN_STAGE'));
    await tester.pumpAndSettle();
    expect(find.text('STAGE_7'), findsOneWidget);

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(find.text('HOME_ROOT'), findsOneWidget);

    await tester.tap(find.text('Filmes'));
    await tester.pumpAndSettle();
    expect(
      find.text('STAGE_7'),
      findsOneWidget,
      reason: 'trocar de tab deve restaurar a pilha anterior',
    );

    await tester.tap(find.text('Filmes'));
    await tester.pumpAndSettle();
    expect(
      find.text('OPEN_STAGE'),
      findsOneWidget,
      reason: 're-selecionar a tab ativa deve voltar à raiz',
    );
  });

  testWidgets('bottom navigation não estoura com texto em 200%', (
    tester,
  ) async {
    final router = _router(initialLocation: '/home');
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, textScale: 2));
    await tester.pumpAndSettle();

    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Filmes'), findsOneWidget);
    expect(find.text('Posters'), findsOneWidget);
    expect(find.text('Cores'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destinos principais expõem rótulos semânticos acionáveis', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final router = _router(initialLocation: '/home');
      addTearDown(router.dispose);

      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Início'), findsOneWidget);
      expect(find.bySemanticsLabel('Filmes'), findsOneWidget);
      expect(find.bySemanticsLabel('Posters'), findsOneWidget);
      expect(find.bySemanticsLabel('Cores'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Filmes'));
      await tester.pumpAndSettle();
      expect(find.text('OPEN_STAGE'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
