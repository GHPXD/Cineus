import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/utils/challenge_code.dart';
import 'package:cineus/presentation/deep_link_handler.dart';

class _FakeDeepLinkSource implements DeepLinkSource {
  final Future<Uri?> Function() initial;
  final StreamController<Uri> controller = StreamController<Uri>.broadcast();

  _FakeDeepLinkSource({required this.initial});

  @override
  Future<Uri?> getInitialLink() => initial();

  @override
  Stream<Uri> get uriLinkStream => controller.stream;

  Future<void> close() => controller.close();
}

Widget _app({
  required DeepLinkSource source,
  required void Function(int movieId) onChallenge,
}) {
  return MaterialApp(
    home: DeepLinkHandler(
      source: source,
      onChallenge: onChallenge,
      child: const Scaffold(body: Text('CINEUS_READY')),
    ),
  );
}

void main() {
  testWidgets('cold-start válido abre o desafio', (tester) async {
    final source = _FakeDeepLinkSource(
      initial: () async => ChallengeCode.linkFor(42),
    );
    addTearDown(source.close);
    final opened = <int>[];

    await tester.pumpWidget(_app(source: source, onChallenge: opened.add));
    await tester.pump();

    expect(opened, [42]);
    expect(find.text('CINEUS_READY'), findsOneWidget);
  });

  testWidgets('falha no cold-start do plugin não derruba o app', (tester) async {
    final source = _FakeDeepLinkSource(
      initial: () async => throw StateError('platform unavailable'),
    );
    addTearDown(source.close);
    final opened = <int>[];

    await tester.pumpWidget(_app(source: source, onChallenge: opened.add));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(opened, isEmpty);
    expect(find.text('CINEUS_READY'), findsOneWidget);
  });

  testWidgets('link recebido com o app aberto é roteado e inválido é ignorado',
      (tester) async {
    final source = _FakeDeepLinkSource(initial: () async => null);
    addTearDown(source.close);
    final opened = <int>[];

    await tester.pumpWidget(_app(source: source, onChallenge: opened.add));
    await tester.pump();

    source.controller.add(Uri.parse('https://example.com/not-cineus'));
    source.controller.add(ChallengeCode.linkFor(77));
    await tester.pump();

    expect(opened, [77]);
  });

  testWidgets('cold-start resolvido depois do dispose não navega', (tester) async {
    final initial = Completer<Uri?>();
    final source = _FakeDeepLinkSource(initial: () => initial.future);
    addTearDown(source.close);
    final opened = <int>[];

    await tester.pumpWidget(_app(source: source, onChallenge: opened.add));
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: Text('OTHER_SCREEN')));
    initial.complete(ChallengeCode.linkFor(99));
    await tester.pump();

    expect(opened, isEmpty);
    expect(find.text('OTHER_SCREEN'), findsOneWidget);
  });

  testWidgets('eventos do stream depois do dispose não navegam', (tester) async {
    final source = _FakeDeepLinkSource(initial: () async => null);
    addTearDown(source.close);
    final opened = <int>[];

    await tester.pumpWidget(_app(source: source, onChallenge: opened.add));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: Text('OTHER_SCREEN')));

    source.controller.add(ChallengeCode.linkFor(123));
    await tester.pump();

    expect(opened, isEmpty);
  });
}
