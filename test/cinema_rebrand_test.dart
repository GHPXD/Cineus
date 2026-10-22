import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/data/repositories/cinema_showcase_repository.dart';
import 'package:cineus/data/repositories/game_repository_impl.dart';
import 'package:cineus/data/services/mobile_ads_service.dart';
import 'package:cineus/data/services/native_commercial_store.dart';
import 'package:cineus/data/services/commerce_synchronizer.dart';
import 'package:cineus/domain/entities/cinema_showcase.dart';
import 'package:cineus/domain/entities/commercial_configuration.dart';
import 'package:cineus/domain/entities/commercial_product.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/entities/player_audience.dart';
import 'package:cineus/domain/entities/player_collection.dart';
import 'package:cineus/presentation/providers/audience_provider.dart';
import 'package:cineus/presentation/screens/splash_screen.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';
import 'package:cineus/presentation/providers/commercial_provider.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/telemetry_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/game_screen.dart';
import 'package:cineus/presentation/widgets/collection_artwork.dart';
import 'support/test_database.dart';
import 'native_commerce_test.dart' show Billing;
import 'monetization_experience_test.dart' show experience, warmExperience;
import 'player_collection_ui_test.dart' show settleCollection;
import 'native_ads_data_screen_test.dart' show app;

class _NoCommerce extends Fake implements CommerceSynchronizer {}

Future<void> shot(WidgetTester tester, GlobalKey boundary, String name) async {
  await settleCollection(tester);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  if (!const bool.fromEnvironment('CINEUS_CAPTURE_REBRAND')) return;
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    const directory = String.fromEnvironment(
      'CINEUS_REBRAND_CAPTURE_DIRECTORY',
      defaultValue: 'docs/preview/cinema-rebrand-2026-10-21/screens',
    );
    final file = File('$directory/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all twelve avatar slots use cinema art without changing saved IDs', () {
    final avatars = PlayerCollectionCatalog.items
        .where((i) => i.kind == CollectionItemKind.avatar)
        .toList();
    expect(avatars.length, 12);
    expect(avatars.map((a) => a.asset).toSet().length, 12);
    expect(
      avatars.every(
        (a) =>
            a.asset.startsWith('assets/collection/cinema_') &&
            a.asset.endsWith('.png'),
      ),
      isTrue,
    );
    expect(avatars.where((a) => a.starter).map((a) => a.id).toSet(), {
      'avatar_owl_v1',
      'avatar_fox_v1',
    });
  });
  test(
    'unknown and under16 never enable ads; teens cannot purchase or profile',
    () {
      const ads = MobileAdsConfiguration(
        rewardedUnit: '',
        interstitialUnit: '',
        audience: 'general',
        reviewed: true,
        nativeConfigured: true,
      );
      for (final audience in [
        null,
        PlayerAudience.unknown,
        PlayerAudience.under16,
      ]) {
        expect(ads.forAudience(audience).audience, '');
      }
      expect(ads.forAudience(PlayerAudience.teen).audience, 'teen');
      expect(PlayerAudience.teen.canPurchase, isFalse);
      expect(PlayerAudience.teen.canMeasureCommerce, isFalse);
      expect(PlayerAudience.adult.canPurchase, isTrue);
      expect(ads.forAudience(PlayerAudience.unrestricted).audience, 'teen');
      expect(PlayerAudience.unrestricted.canPurchase, isTrue);
      expect(PlayerAudience.unrestricted.canMeasureCommerce, isFalse);
      expect(PlayerAudience.parse('fake'), PlayerAudience.unknown);
    },
  );
  test(
    'removing the age question preserves earlier restrictions without declaring adulthood',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
        ],
      );
      addTearDown(c.dispose);
      expect(
        await c.read(playerAudienceProvider.future),
        PlayerAudience.unrestricted,
      );
      expect(
        await c.read(appMetaRepositoryProvider).read('player_audience_v1'),
        isNull,
      );
      await c
          .read(appMetaRepositoryProvider)
          .write('player_audience_v1', 'teen');
      c.invalidate(playerAudienceProvider);
      expect(await c.read(playerAudienceProvider.future), PlayerAudience.teen);
      expect(c.read(playerAudienceProvider).requireValue.canPurchase, isFalse);
    },
  );
  for (final seen in [false, true]) {
    testWidgets(
      'startup opens ${seen ? "home" : "tutorial"} without asking for age',
      (tester) async {
        await warmExperience(tester);
        final c = await experience(
          tester,
          movies: true,
          overrides: [onboardingSeenProvider.overrideWith((_) async => seen)],
        );
        final router = AppRouter.create(initialLocation: '/');
        addTearDown(router.dispose);
        await tester.runAsync(() => c.read(onboardingSeenProvider.future));
        await tester.pumpWidget(app(c, GlobalKey(), router));
        await tester.pump();
        tester.widget<SplashScreen>(find.byType(SplashScreen)).onComplete();
        await tester.pump();
        expect(
          router.routeInformationProvider.value.uri.path,
          seen ? '/home' : '/how-to-play',
        );
        expect(find.text('Sua faixa etária'), findsNothing);
        expect(find.text('Tenho 18 anos ou mais'), findsNothing);
        expect(tester.takeException(), isNull);
        // This test verifies the splash routing decision; home has its own
        // integration coverage. Dispose before starting its database loads.
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  test(
    'minor commercial metrics stay disabled even with a previous opt-in',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
          commercialConfigurationProvider.overrideWithValue(
            const CommercialConfiguration(localMetrics: true),
          ),
          playerAudienceProvider.overrideWith((_) async => PlayerAudience.teen),
        ],
      );
      addTearDown(container.dispose);
      await container.read(playerAudienceProvider.future);
      await container.read(usageDataServiceProvider).setConsent(true);
      await container
          .read(productTelemetryProvider)
          .record('game_opened', properties: {'mode': 'clue', 'kind': 'stage'});
      expect(await db.query('metrics_outbox'), isEmpty);
    },
  );
  test('purchase age gate runs before billing or server access', () async {
    final billing = Billing();
    final store = NativeCommercialStore(
      _NoCommerce(),
      billing: billing,
      products: {},
      platform: 'google',
      changed: (_, __) {},
      canPurchase: () => false,
    );
    addTearDown(() async {
      await store.dispose();
      await billing.events.close();
    });
    await expectLater(
      store.purchase(CommercialCatalog.tickets20.id),
      throwsStateError,
    );
    expect(billing.sent, isNull);
  });
  test('Plus can cover natives or banners without interstitials', () {
    const offer = CommercialStoreOffer(
      productId: 'cineus.plus.permanent.v1',
      storeProductId: 'plus',
      localizedPrice: 'R\$ 9,90',
    );
    expect(
      const CommercialConfiguration(
        plus: true,
        nativeAds: true,
      ).canOffer(offer, storeReady: true),
      isTrue,
    );
    expect(
      const CommercialConfiguration(
        plus: true,
        banners: true,
      ).canOffer(offer, storeReady: true),
      isTrue,
    );
    expect(
      const CommercialConfiguration(
        plus: true,
      ).canOffer(offer, storeReady: true),
      isFalse,
    );
    expect(CommercialConfiguration.fromBuild().collections, isFalse);
    expect(CommercialConfiguration.fromBuild().club, isFalse);
  });
  test(
    'showcase resumes saved answers and separates modes and versions',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final provider = TestDatabaseProvider(db),
          games = GameRepositoryImpl(TestDatabaseProvider(db));
      final repo = CinemaShowcaseRepository(provider, games);
      const theme = CinemaShowcase('classics', 'themes-v1', [1, 2]);
      final first = await repo.open(theme, GameMode.clue, 1);
      await games.saveSession(
        first.copyWith(revealedClues: 3, guesses: ['an attempt']),
      );
      final resumed = await repo.open(theme, GameMode.clue, 1);
      expect(resumed.id, first.id);
      expect(resumed.guesses, ['an attempt']);
      expect((await repo.open(theme, GameMode.poster, 1)).id, isNot(first.id));
      expect(
        (await repo.open(
          const CinemaShowcase('classics', 'themes-v2', [1, 2]),
          GameMode.clue,
          1,
        )).id,
        isNot(first.id),
      );
      await expectLater(
        repo.open(theme, GameMode.clue, 3),
        throwsArgumentError,
      );
    },
  );
  test(
    'Cores keeps its known characters and no memory-preview replacement',
    () async {
      final catalog = jsonDecode(
        await rootBundle.loadString('assets/colors/training_v1.json'),
      );
      final questions = catalog['questions'] as List;
      expect(questions.map((q) => q['character_id']).toSet().length, 50);
      expect(
        questions.any(
          (q) => (q['character_id'] as String).startsWith('cinema_'),
        ),
        isFalse,
      );
      expect(questions.any((q) => q['memory_preview'] == true), isFalse);
    },
  );
  for (final route in [
    '/collection',
    '/seasons',
    '/showcase/classics',
    '/audience',
  ]) {
    testWidgets('cinema rebrand renders $route without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      rootBundle.clear();
      await warmExperience(tester);
      final c = await experience(
        tester,
        movies: true,
        overrides: [
          playerAudienceProvider.overrideWith(
            (_) async => PlayerAudience.adult,
          ),
        ],
      );
      final router = AppRouter.create(initialLocation: route);
      final boundary = GlobalKey();
      addTearDown(router.dispose);
      await tester.pumpWidget(app(c, boundary, router));
      await shot(tester, boundary, route.replaceAll('/', '_'));
      if (route == '/collection' &&
          const bool.fromEnvironment('CINEUS_CAPTURE_REBRAND')) {
        for (final item in [
          'premiere_avatar_cat_v1',
          'mission_avatar_capybara_v1',
          'night_avatar_otter_v1',
        ]) {
          final tile = find.byKey(ValueKey('collection-item-$item'));
          await tester.scrollUntilVisible(tile, 280);
          await Scrollable.ensureVisible(tester.element(tile), alignment: .5);
          await tester.pumpAndSettle();
          expect(tile.hitTestable(), findsOneWidget);
          await tester.tap(tile);
          await settleCollection(tester);
          await tester.scrollUntilVisible(find.byType(CollectionPreview), -300);
          expect(
            tester
                .widget<CollectionPreview>(find.byType(CollectionPreview))
                .candidate
                ?.id,
            item,
          );
          await Scrollable.ensureVisible(
            tester.element(find.byType(CollectionPreview)),
            alignment: 0,
          );
          await tester.pumpAndSettle();
          await shot(tester, boundary, 'preview_$item');
        }
        for (final kind in CollectionItemKind.values) {
          final tab = find.byKey(ValueKey('collection-tab-${kind.name}'));
          await tester.scrollUntilVisible(tab, 250);
          await Scrollable.ensureVisible(tester.element(tab), alignment: .06);
          await tester.pumpAndSettle();
          await tester.tap(tab);
          await shot(tester, boundary, 'catalog_${kind.name}');
        }
      }
      if (route == '/showcase/classics') {
        await tester.tap(find.text('Filme 1'));
        await settleCollection(tester);
        expect(find.byType(GameScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        final movie = c.read(clueGameProvider).movie!;
        await tester.runAsync(
          () => c
              .read(clueGameProvider.notifier)
              .submitGuess(movie.acceptedTitles.first),
        );
        await settleCollection(tester);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('next-showcase-film')),
          350,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const ValueKey('next-showcase-film')));
        await settleCollection(tester);
        expect(find.byType(GameScreen), findsOneWidget);
        expect(c.read(clueGameProvider).session!.movieId, isNot(movie.id));
        expect(c.read(clueGameProvider).session!.date, startsWith('showcase:'));
        expect(tester.takeException(), isNull);
      }
    });
  }
}
