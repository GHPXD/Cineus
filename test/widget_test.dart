// Smoke test for the splash screen.
//
// The previous version pumped the whole `CineusApp`, which boots the router,
// opens the real SQLite database and starts the home screen's periodic
// countdown timer. It failed with "A Timer is still pending even after the
// widget tree was disposed" and could never have passed. Covering the app shell
// properly needs injectable repositories (the notifiers currently reach the
// concrete `DatabaseHelper` singleton), so this keeps to what can be tested
// honestly today: the splash screen in isolation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/constants/app_constants.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/screens/splash_screen.dart';

void main() {
  /// Wraps a screen with the localisation delegates it now needs.
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

    // Let the entry animation and the splash delay run out so no timer leaks.
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

  testWidgets('SplashScreen renders in every supported language', (
    tester,
  ) async {
    const expected = {
      'pt': 'Adivinha o filme',
      'en': 'Guess the film',
      'es': 'Adivina la película',
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
}
