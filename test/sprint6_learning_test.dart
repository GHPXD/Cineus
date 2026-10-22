import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/domain/repositories/app_meta_repository.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/database_bootstrap.dart';
import 'package:cineus/presentation/providers/external_links.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/screens/how_to_play_screen.dart';
import 'package:cineus/presentation/widgets/support_card.dart';

class FakeLinks implements ExternalLinks {
  int opens = 0, copies = 0;
  bool available = true, failOpen = false, failCopy = false;
  Completer<bool>? pending;
  @override
  Future<bool> openSupport() async {
    opens++;
    if (failOpen) throw StateError('Browser unavailable');
    return pending == null ? available : await pending!.future;
  }

  @override
  Future<void> copySupport() async {
    copies++;
    if (failCopy) throw StateError('Clipboard unavailable');
  }
}

class FakeGuideMeta implements AppMetaRepository {
  bool seen = false, fail = false;
  int marks = 0;
  Completer<void>? pending;
  @override
  Future<bool> hasSeenOnboarding() async => seen;
  @override
  Future<void> markOnboardingSeen() async {
    marks++;
    if (pending != null) await pending!.future;
    if (fail) throw StateError('Storage failure');
    seen = true;
  }

  @override
  Future<String?> read(String key) async => null;
  @override
  Future<void> write(String key, String value) async {}
}

Future<void> pump6(
  WidgetTester tester,
  Widget home, {
  FakeLinks? links,
  FakeGuideMeta? meta,
  double scale = 1,
  String language = 'pt',
}) async {
  tester.view.physicalSize = const Size(320, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        externalLinksProvider.overrideWithValue(links ?? FakeLinks()),
        appMetaRepositoryProvider.overrideWithValue(meta ?? FakeGuideMeta()),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: Locale(language),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: home,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> reveal6(
  WidgetTester tester,
  Finder target, {
  double step = 160,
}) async {
  await tester.scrollUntilVisible(
    target,
    step,
    maxScrolls: 60,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first,
  );
  await tester.pump();
}

Future<void> guideNext6(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('guide-next')));
  await tester.pump();
}

Future<void> finishPages6(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await guideNext6(tester);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'Nunito': 'Nunito-400.ttf',
      'Fredoka': 'Fredoka-700.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load('assets/fonts/${entry.value}'))).load();
    }
  });
  for (final language in ['pt', 'en', 'es']) {
    testWidgets(
      '$language tutorial shows 10 clues and 5 poster levels with text 200%',
      (tester) async {
        await pump6(
          tester,
          HowToPlayScreen(onDismiss: () {}),
          scale: 2,
          language: language,
        );
        final l = await AppL10n.delegate.load(Locale(language));
        await reveal6(tester, find.text(l.guideCluesTitle));
        expect(find.text(l.guideCluesTitle), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        await reveal6(
          tester,
          find.byKey(const ValueKey('guide-mode-poster')),
          step: -160,
        );
        await tester.tap(find.byKey(const ValueKey('guide-mode-poster')));
        await tester.pump();
        await reveal6(tester, find.text(l.guidePosterTitle));
        expect(find.text(l.guidePosterTitle), findsOneWidget);
        expect(find.text('10'), findsNothing);
        expect(find.text('5'), findsOneWidget);
        expect(find.byKey(const ValueKey('guide-demo-reveal')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('guide demos update score, search selection and confirmation', (
    tester,
  ) async {
    await pump6(tester, HowToPlayScreen(onDismiss: () {}));
    await reveal6(tester, find.byKey(const ValueKey('guide-demo-reveal')));
    await tester.tap(find.byKey(const ValueKey('guide-demo-reveal')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('guide-demo-score'))).data,
      'Vale 9 pts',
    );
    await guideNext6(tester);
    expect(find.byKey(const ValueKey('guide-demo-confirm')), findsNothing);
    await reveal6(tester, find.byKey(const ValueKey('guide-demo-answer-1')));
    await tester.tap(find.byKey(const ValueKey('guide-demo-answer-1')));
    await tester.pump();
    expect(find.byKey(const ValueKey('guide-demo-feedback')), findsNothing);
    await reveal6(tester, find.byKey(const ValueKey('guide-demo-confirm')));
    await tester.tap(find.byKey(const ValueKey('guide-demo-confirm')));
    await tester.pump();
    expect(find.textContaining('Christopher Nolan'), findsOneWidget);
    await guideNext6(tester);
    expect(find.textContaining('meia-noite UTC'), findsOneWidget);
    await guideNext6(tester);
    expect(find.textContaining('Retomar é grátis'), findsOneWidget);
    expect(find.textContaining('volta a 10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('onboarding saves once before dismissing, even with rapid taps', (
    tester,
  ) async {
    final meta = FakeGuideMeta()..pending = Completer<void>();
    var dismissed = 0;
    await pump6(
      tester,
      HowToPlayScreen(isOnboarding: true, onDismiss: () => dismissed++),
      meta: meta,
    );
    await finishPages6(tester);
    final done = find.byKey(const ValueKey('guide-done'));
    await tester.tap(done);
    await tester.tap(done);
    await tester.pump();
    expect(meta.marks, 1);
    expect(dismissed, 0);
    meta.pending!.complete();
    await tester.pump();
    await tester.pump();
    expect(meta.seen, isTrue);
    expect(dismissed, 1);
  });
  testWidgets(
    'onboarding persistence failure stays in the guide and can retry',
    (tester) async {
      final meta = FakeGuideMeta()..fail = true;
      var dismissed = 0;
      await pump6(
        tester,
        HowToPlayScreen(isOnboarding: true, onDismiss: () => dismissed++),
        meta: meta,
      );
      await finishPages6(tester);
      await tester.tap(find.byKey(const ValueKey('guide-done')));
      await tester.pump();
      await tester.pump();
      expect(dismissed, 0);
      expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
      meta.fail = false;
      await tester.tap(find.byKey(const ValueKey('guide-done')));
      await tester.pump();
      await tester.pump();
      expect(meta.marks, 2);
      expect(dismissed, 1);
    },
  );
  testWidgets('help mode dismisses without writing onboarding state', (
    tester,
  ) async {
    final meta = FakeGuideMeta();
    var dismissed = 0;
    await pump6(
      tester,
      HowToPlayScreen(onDismiss: () => dismissed++),
      meta: meta,
    );
    await finishPages6(tester);
    await tester.tap(find.byKey(const ValueKey('guide-done')));
    await tester.pump();
    expect(meta.marks, 0);
    expect(dismissed, 1);
  });
  for (final throws in [false, true]) {
    testWidgets(
      'support ${throws ? 'exception' : 'unavailable browser'} offers explicit copy fallback',
      (tester) async {
        final links = FakeLinks()
          ..available = false
          ..failOpen = throws;
        await pump6(
          tester,
          const Scaffold(body: SingleChildScrollView(child: SupportCard())),
          links: links,
          scale: 2,
        );
        await reveal6(tester, find.byKey(const ValueKey('support-open')));
        await tester.tap(find.byKey(const ValueKey('support-open')));
        await tester.pump();
        await tester.pump();
        expect(links.opens, 1);
        expect(links.copies, 0);
        expect(
          find.textContaining('Não foi possível abrir o navegador'),
          findsOneWidget,
        );
        await reveal6(tester, find.byKey(const ValueKey('support-copy')));
        await tester.tap(find.byKey(const ValueKey('support-copy')));
        await tester.pump();
        await tester.pump();
        expect(links.copies, 1);
        expect(find.text('Link de suporte copiado.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('copy failure keeps a selectable URL and recoverable feedback', (
    tester,
  ) async {
    final links = FakeLinks()..failCopy = true;
    await pump6(
      tester,
      const Scaffold(body: SingleChildScrollView(child: SupportCard())),
      links: links,
    );
    await tester.tap(find.byKey(const ValueKey('support-copy')));
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Não foi possível copiar'), findsOneWidget);
    expect(
      find.widgetWithText(SelectableText, PlatformExternalLinks.supportUrl),
      findsOneWidget,
    );
    expect(links.opens, 0);
  });
  testWidgets(
    'support locks duplicate launches and is safe when closed during await',
    (tester) async {
      final links = FakeLinks()..pending = Completer<bool>();
      await pump6(
        tester,
        const Scaffold(body: SingleChildScrollView(child: SupportCard())),
        links: links,
      );
      final open = find.byKey(const ValueKey('support-open'));
      await tester.tap(open);
      await tester.tap(open);
      await tester.pump();
      expect(links.opens, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      links.pending!.complete(true);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('bootstrap repair cancellation never touches storage', (
    tester,
  ) async {
    var repairs = 0;
    await tester.pumpWidget(
      DatabaseBootstrap(
        initialize: () async => throw StateError('audit'),
        repair: () async {
          repairs++;
        },
        child: const Text('READY'),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Repair database'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not restored automatically'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repairs, 0);
  });
  testWidgets(
    'failed repair explains possible changes instead of claiming intact data',
    (tester) async {
      await tester.pumpWidget(
        DatabaseBootstrap(
          initialize: () async => throw StateError('audit'),
          repair: () async => throw StateError('repair failed'),
          child: const Text('READY'),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Repair database'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Repair database'));
      await tester.pump();
      await tester.pump();
      expect(
        find.textContaining('Data may have been partially recreated'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Your local data has not been changed'),
        findsNothing,
      );
    },
  );
  testWidgets(
    'bootstrap support works without database initialization and can return',
    (tester) async {
      final links = FakeLinks();
      await tester.pumpWidget(
        DatabaseBootstrap(
          initialize: () async => throw StateError('audit'),
          repair: () async {},
          support: links,
          child: const Text('READY'),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Support'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('support-open')));
      await tester.pump();
      expect(links.opens, 1);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Your data could not be opened'), findsOneWidget);
    },
  );
}
