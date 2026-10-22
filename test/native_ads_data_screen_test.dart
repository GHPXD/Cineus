import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/data/services/growth_gateway.dart';
import 'package:cineus/data/services/local_product_telemetry.dart';
import 'package:cineus/data/services/population_telemetry.dart';
import 'package:cineus/data/services/mobile_ads_service.dart';
import 'package:cineus/domain/entities/commercial_configuration.dart';
import 'package:cineus/domain/entities/commercial_product.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/entities/product_event.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/commercial_provider.dart';
import 'package:cineus/presentation/providers/growth_provider.dart';
import 'package:cineus/presentation/providers/monetization_notifier.dart';
import 'package:cineus/presentation/providers/player_data_provider.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/telemetry_provider.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/widgets/stage_native_ad.dart';
import 'monetization_experience_test.dart' show experience, warmExperience;
import 'player_collection_ui_test.dart' show settleCollection;
import 'support/test_database.dart';

const nativeAds = MobileAdsConfiguration(
  rewardedUnit: '',
  interstitialUnit: '',
  nativeUnit: 'ca-app-pub-3940256099942544/2247696110',
  audience: 'general',
  reviewed: true,
  nativeConfigured: true,
);

class _PendingAds extends Fake implements VerifiedMobileAdsService {
  int calls = 0;
  final pending = Completer<void>();
  @override
  MobileAdsConfiguration get ads => nativeAds;
  @override
  Future<void> initialize() {
    calls++;
    return pending.future;
  }

  @override
  Stream<void> get privacyChanges => const Stream.empty();
  @override
  bool get ready => true;
  @override
  bool get privacyUpdating => false;
}

class _BackupApi extends Fake implements GrowthGateway {
  final actions = <String>[];
  int revision = 1;
  @override
  Future<Map<String, dynamic>> command(
    String action, [
    Map<String, Object?> data = const {},
  ]) async {
    actions.add(action);
    if (action == 'backup_delete') {
      revision = 0;
      return {'deleted': true};
    }
    return {
      'revision': revision,
      'updated_at': revision == 0 ? null : 1792540800,
    };
  }
}

Future<void> capture(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  await settleCollection(tester);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: name);
  if (!const bool.fromEnvironment('CINEUS_CAPTURE_DATA_NATIVE')) return;
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('docs/preview/data-native-2026-10-21/screens/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Widget app(
  ProviderContainer c,
  GlobalKey boundary,
  router, {
  String language = 'pt',
  double scale = 1,
}) => RepaintBoundary(
  key: boundary,
  child: UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: Locale(language),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    ),
  ),
);
void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  test(
    'opt-out erases both diagnostics and outbox atomically against in-flight tracking',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final metrics = PopulationTelemetry(
        TestDatabaseProvider(db),
        () => DateTime.utc(2026, 10, 21),
        () => null,
        localEnabled: true,
      );
      await metrics.record('app_active');
      expect(
        await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE name='product_events'",
        ),
        isEmpty,
      );
      await metrics.setConsent(true);
      await metrics.record('app_active');
      expect(await db.query('product_events'), hasLength(1));
      await Future.wait([
        for (var i = 0; i < 20; i++) metrics.record('app_active'),
        metrics.setConsent(false),
        for (var i = 0; i < 20; i++) metrics.record('app_active'),
      ]);
      expect(await db.query('product_events'), isEmpty);
      expect(await db.query('metrics_outbox'), isEmpty);
      expect(await metrics.preferencePending(), isTrue);
    },
  );
  test(
    'native slots count stage cards rather than grid rows, locks or progress',
    () {
      expect(
        [
          for (var i = 0; i <= 51; i++)
            if (StageAdPolicy.after(i)) i,
        ],
        [10, 20, 30, 40, 50],
      );
      expect(
        [
          for (var i = 0; i <= 11; i++)
            if (StageAdPolicy.after(i, colors: true)) i,
        ],
        [5, 10],
      );
      expect(StageAdPolicy.after(-10), false);
      expect(ProductEvents.sanitize('ad_shown', {'placement': 'native'}), {
        'placement': 'native',
      });
    },
  );
  test('native format has its own feature flag and verified test units', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(
      nativeAds.enabled(
        const CommercialConfiguration(
          environment: CommercialEnvironment.sandbox,
          nativeAds: true,
        ),
      ),
      true,
    );
    expect(
      nativeAds.enabled(
        const CommercialConfiguration(
          environment: CommercialEnvironment.sandbox,
          banners: true,
        ),
      ),
      false,
    );
    expect(
      nativeAds.enabled(
        const CommercialConfiguration(
          environment: CommercialEnvironment.production,
          nativeAds: true,
        ),
      ),
      false,
    );
  });
  for (final suppressed in ['offscreen', 'holdout', 'plus', 'dispose']) {
    testWidgets('native SDK does not load after $suppressed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final service = _PendingAds();
      final c = ProviderContainer(
        overrides: [
          commercialConfigurationProvider.overrideWithValue(
            const CommercialConfiguration(
              environment: CommercialEnvironment.sandbox,
              nativeAds: true,
            ),
          ),
          mobileAdsConfigurationProvider.overrideWithValue(nativeAds),
          monetizationServiceProvider.overrideWithValue(service),
          growthConfigurationProvider.overrideWith(
            (_) => GrowthConfiguration(
              ready: true,
              bannerHoldout: suppressed == 'holdout',
            ),
          ),
          activeCommercialEntitlementsProvider.overrideWithValue(
            AsyncData([
              if (suppressed == 'plus')
                CommercialEntitlement(
                  productId: CommercialCatalog.plus.id,
                  verifiedAt: DateTime.utc(2026, 1, 1),
                ),
            ]),
          ),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    if (suppressed == 'offscreen') const SizedBox(height: 2000),
                    const SizedBox(width: 360, child: StageNativeAd()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(service.calls, suppressed == 'dispose' ? 1 : 0);
      await tester.pumpWidget(const SizedBox.shrink());
      service.pending.complete();
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
      expect(tester.takeException(), isNull);
    });
  }
  for (final cfg in [
    (390.0, 1.0, 'pt'),
    (320.0, 2.0, 'pt'),
    (320.0, 2.0, 'en'),
    (320.0, 2.0, 'es'),
  ]) {
    testWidgets('data controls stay compact and above system navbar $cfg', (
      tester,
    ) async {
      tester.view.physicalSize = Size(cfg.$1, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 40);
      tester.view.viewPadding = const FakeViewPadding(bottom: 40);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await warmExperience(tester);
      final c = await experience(tester);
      await tester.runAsync(() => c.read(usageDataServiceProvider).consented());
      final router = AppRouter.create(initialLocation: '/data');
      addTearDown(router.dispose);
      final boundary = GlobalKey();
      await tester.pumpWidget(
        app(c, boundary, router, language: cfg.$3, scale: cfg.$2),
      );
      await settleCollection(tester);
      expect(find.byKey(const ValueKey('backup-save')), findsNothing);
      await capture(
        tester,
        boundary,
        'data_${cfg.$1.toInt()}_${cfg.$2.toInt()}x_${cfg.$3}',
      );
      final deletion = find.byKey(const ValueKey('usage-delete'));
      await tester.scrollUntilVisible(
        deletion,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(deletion);
      await tester.pumpAndSettle();
      expect(tester.getRect(deletion).bottom, lessThanOrEqualTo(804));
      expect(deletion.hitTestable(), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('manage-progress')),
        -180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('manage-progress')));
      await settleCollection(tester);
      expect(find.byKey(const ValueKey('backup-save')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('backup-key')).hitTestable(),
        findsNothing,
      );
      if (cfg.$1 == 390) {
        await capture(tester, boundary, 'progress_options_390_pt');
      }
    });
  }
  testWidgets(
    'erasing usage works without backend and preserves gameplay and balance',
    (tester) async {
      await warmExperience(tester);
      final c = await experience(tester);
      await tester.runAsync(() async {
        await c
            .read(gameRepositoryProvider)
            .saveSession(
              GameSession.daily(
                mode: GameMode.clue,
                date: '2026-10-20',
                movieId: 1,
              ),
            );
        final db = c.read(databaseProvider);
        await LocalProductTelemetry(db).record('app_active');
        final metrics = c.read(usageDataServiceProvider);
        await metrics.setConsent(true);
        await metrics.record('app_active');
      });
      final router = AppRouter.create(initialLocation: '/data');
      addTearDown(router.dispose);
      await tester.pumpWidget(app(c, GlobalKey(), router));
      await settleCollection(tester);
      final deletion = find.byKey(const ValueKey('usage-delete'));
      await tester.ensureVisible(deletion);
      await tester.tap(deletion);
      await settleCollection(tester);
      await tester.runAsync(() async {
        final db = await c.read(databaseProvider).database;
        expect(await db.query('product_events'), isEmpty);
        expect(await db.query('metrics_outbox'), isEmpty);
        expect((await db.query('metrics_preferences')).single['enabled'], 0);
        expect(await db.query('game_sessions'), hasLength(1));
        expect(c.read(ticketNotifierProvider).total, 10);
      });
      await settleCollection(tester);
      expect(
        find.text('Dados de uso deste aparelho apagados.'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'cloud status reveals no payload; deleting backup refreshes state and keeps local games',
    (tester) async {
      final api = _BackupApi();
      await warmExperience(tester);
      final c = await experience(
        tester,
        overrides: [growthGatewayProvider.overrideWithValue(api)],
      );
      await tester.runAsync(() async {
        await c.read(usageDataServiceProvider).consented();
        await c.read(cloudBackupStatusProvider.future);
      });
      final router = AppRouter.create(initialLocation: '/data');
      addTearDown(router.dispose);
      await tester.pumpWidget(app(c, GlobalKey(), router));
      await settleCollection(tester);
      expect(find.textContaining('Na nuvem'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('manage-progress')));
      await settleCollection(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('backup-advanced')));
      await tester.tap(find.byKey(const ValueKey('backup-advanced')));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('backup-delete'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 350));
      expect(api.actions, isNot(contains('backup_delete')));
      await tester.tap(
        find.widgetWithText(FilledButton, 'Apagar backup da nuvem'),
      );
      await settleCollection(tester);
      expect(api.actions.where((a) => a == 'backup_delete'), hasLength(1));
      expect(api.actions, isNot(contains('backup_get')));
      expect(find.textContaining('Você ainda não tem'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  for (final (route, mode, slot) in [
    ('/stages', 'clue', 10),
    ('/visual', 'poster', 10),
    ('/colors', 'colors', 5),
  ]) {
    testWidgets(
      'native card follows stage $slot in $mode without opening locked stages',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await warmExperience(tester);
        final c = await experience(tester, movies: true);
        final router = AppRouter.create(initialLocation: route);
        addTearDown(router.dispose);
        final boundary = GlobalKey();
        await tester.pumpWidget(app(c, boundary, router));
        await settleCollection(tester);
        final ad = find.byKey(ValueKey('stage-native-$mode-$slot'));
        await tester.scrollUntilVisible(
          ad,
          450,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(ad);
        await Scrollable.ensureVisible(tester.element(ad), alignment: .5);
        await settleCollection(tester);
        expect(ad.hitTestable(), findsOneWidget);
        expect(c.read(ticketNotifierProvider).total, 10);
        await capture(tester, boundary, 'native_${mode}_390_pt');
      },
    );
  }
}
