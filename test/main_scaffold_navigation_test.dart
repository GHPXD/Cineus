import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/screens/main_scaffold.dart';

void main() {
  testWidgets('tabs preservam a própria pilha e re-seleção volta à raiz',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/stages',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainScaffold(
            navigationShell: navigationShell,
          ),
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
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('pt'),
        localizationsDelegates: const [
          AppL10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppL10n.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OPEN_STAGE'));
    await tester.pumpAndSettle();
    expect(find.text('STAGE_7'), findsOneWidget);

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    expect(find.text('HOME_ROOT'), findsOneWidget);

    await tester.tap(find.text('Filmes'));
    await tester.pumpAndSettle();
    expect(find.text('STAGE_7'), findsOneWidget,
        reason: 'trocar de tab deve restaurar a pilha anterior');

    await tester.tap(find.text('Filmes'));
    await tester.pumpAndSettle();
    expect(find.text('OPEN_STAGE'), findsOneWidget,
        reason: 're-selecionar a tab ativa deve voltar à raiz');
  });
}
