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
    expect(find.textContaining('Adivinha o filme'), findsOneWidget);

    await tester.pump(AppConstants.splashDuration);
    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen calls onComplete after splashDuration',
      (tester) async {
    var completed = false;
    await tester.pumpWidget(
      localized(SplashScreen(onComplete: () => completed = true)),
    );

    expect(completed, isFalse, reason: 'não deve completar imediatamente');

    await tester.pump(AppConstants.splashDuration);
    expect(completed, isTrue);

    await tester.pumpAndSettle();
  });

  testWidgets('SplashScreen cancela onComplete quando é desmontada cedo',
      (tester) async {
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

  testWidgets('SplashScreen renders in every supported language',
      (tester) async {
    const expected = {
      'pt': 'Adivinha o filme',
      'en': 'Guess the film',
      'es': 'Adivina la película',
    };

    for (final entry in expected.entries) {
      await tester.pumpWidget(
        localized(
          SplashScreen(onComplete: () {}),
          locale: Locale(entry.key),
        ),
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
}
