// Smoke tests for the splash screen.
//
// The splash is deliberately tested in isolation so this file does not boot the
// router or the concrete database singleton. Phase 3 also verifies its delayed
// navigation is lifecycle-safe when the widget is removed early.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/constants/app_constants.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/screens/splash_screen.dart';

void main() {
  Widget localized(Widget child, {Locale locale = const Locale('pt')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: child,
    );
  }

  testWidgets('SplashScreen renders without crashing', (tester) async {
    await tester.pumpWidget(localized(SplashScreen(onComplete: () {})));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.textContaining('Adivinhe filmes'), findsOneWidget);

    await tester.pump(AppConstants.splashDuration);
    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen calls onComplete after splashDuration', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      localized(SplashScreen(onComplete: () => completed = true)),
    );

    expect(completed, isFalse, reason: 'não deve completar imediatamente');

    await tester.pump(AppConstants.splashDuration);
    expect(completed, isTrue);

    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen cancela onComplete quando é desmontada cedo', (
    tester,
  ) async {
    var completed = false;
    await tester.pumpWidget(
      localized(SplashScreen(onComplete: () => completed = true)),
    );

    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(AppConstants.splashDuration);

    expect(
      completed,
      isFalse,
      reason: 'um splash já descartado não pode navegar depois',
    );
  });

  testWidgets('SplashScreen renders in every supported language', (
    tester,
  ) async {
    const expected = {
      'pt': 'Adivinhe filmes',
      'en': 'Guess movies',
      'es': 'Adivina películas',
    };

    for (final entry in expected.entries) {
      await tester.pumpWidget(
        localized(SplashScreen(onComplete: () {}), locale: Locale(entry.key)),
      );
      expect(
        find.textContaining(entry.value),
        findsOneWidget,
        reason: 'locale ${entry.key}',
      );
      await tester.pump(AppConstants.splashDuration);
      await tester.pumpAndSettle();
    }
  });
  testWidgets(
    'cinematic logo moves, settles and completes once without adding startup delay',
    (tester) async {
      var completions = 0;
      await tester.pumpWidget(
        localized(SplashScreen(onComplete: () => completions++)),
      );
      final logo = find.byKey(const ValueKey('splash-animated-logo'));
      final transform = find
          .ancestor(of: logo, matching: find.byType(Transform))
          .first;
      final initial = tester.widget<Transform>(transform).transform.clone();
      await tester.pump(const Duration(milliseconds: 240));
      final middle = tester.widget<Transform>(transform).transform.clone();
      expect(middle, isNot(initial));
      await tester.pump(const Duration(milliseconds: 460));
      expect(completions, 1);
      expect(tester.widget<Transform>(transform).transform, isNot(middle));
      await tester.pump(const Duration(seconds: 2));
      expect(completions, 1);
    },
  );
  testWidgets('reduced motion displays the complete brand immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        locale: const Locale('pt'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: SplashScreen(onComplete: () {}),
      ),
    );
    final transform = find
        .ancestor(
          of: find.byKey(const ValueKey('splash-animated-logo')),
          matching: find.byType(Transform),
        )
        .first;
    final finalTransform = tester
        .widget<Transform>(transform)
        .transform
        .clone();
    await tester.pump(const Duration(milliseconds: 240));
    expect(tester.widget<Transform>(transform).transform, finalTransform);
    final fades = tester.widgetList<Opacity>(find.byType(Opacity));
    expect(fades.every((fade) => fade.opacity == 1), true);
    await tester.pump(AppConstants.splashDuration);
  });
}
