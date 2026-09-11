import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/presentation/database_bootstrap.dart';

void main() {
  testWidgets('falha de bootstrap mostra recuperação e retry pode concluir',
      (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      DatabaseBootstrap(
        initialize: () async {
          attempts++;
          if (attempts == 1) throw StateError('boom');
        },
        repair: () async {},
        child: const MaterialApp(home: Text('APP_READY')),
      ),
    );
    await tester.pump();

    expect(find.text('Your data could not be opened'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Repair database'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('APP_READY'), findsOneWidget);
  });

  testWidgets('repair exige confirmação antes de executar', (tester) async {
    var repairs = 0;
    final never = Completer<void>();

    await tester.pumpWidget(
      DatabaseBootstrap(
        initialize: () async => throw StateError('broken'),
        repair: () async {
          repairs++;
          await never.future;
        },
        child: const MaterialApp(home: Text('APP_READY')),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Repair database'));
    await tester.pumpAndSettle();

    expect(find.text('Repair local data?'), findsOneWidget);
    expect(repairs, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Repair database'));
    await tester.pump();

    expect(repairs, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    never.completeError(StateError('still broken'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Your data could not be opened'), findsOneWidget);
  });
}
