import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/core/theme/app_theme.dart';
import 'package:cineus/domain/entities/commercial_product.dart';
import 'package:cineus/domain/entities/player_collection.dart';
import 'package:cineus/domain/entities/player_audience.dart';
import 'package:cineus/presentation/providers/audience_provider.dart';
import 'package:cineus/presentation/screens/journey_screen.dart';
import 'package:cineus/domain/services/commercial_store.dart';
import 'package:cineus/l10n/app_l10n.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'package:cineus/presentation/providers/commerce_content_provider.dart';
import 'package:cineus/presentation/providers/commercial_provider.dart';
import 'package:cineus/presentation/providers/monetization_notifier.dart';
import 'package:cineus/presentation/providers/player_collection_provider.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/routes/app_router.dart';
import 'package:cineus/presentation/screens/seasons_screen.dart';
import 'package:cineus/presentation/widgets/commerce_placeholders.dart';
import 'package:cineus/presentation/widgets/commercial_offers_panel.dart';
import 'package:cineus/presentation/widgets/ticket_details_sheet.dart';
import 'monetization_experience_test.dart'
    show experience, warmExperience, captureExperience;
import 'player_collection_ui_test.dart' show collectionApp, settleCollection;
import 'sprint4_ui_test.dart' show fixture, tapVisible, settleChanges;

class PreviewStore implements CommercialStore {
  List<CommercialEntitlement> rights = [];
  List<CommercialStoreOffer> offers = [];
  bool failOffers = false;
  bool failRights = false;
  int restores = 0, purchases = 0;
  Completer<List<CommercialEntitlement>>? rightsGate;
  Completer<CommercialPurchaseResult>? purchaseGate;
  @override
  Future<List<CommercialEntitlement>> loadEntitlements() async {
    if (failRights) throw StateError('Ownership check failed');
    return rightsGate?.future ?? rights;
  }

  @override
  Future<List<CommercialStoreOffer>> loadOffers() async {
    if (failOffers) throw StateError('Offline test store');
    return offers;
  }

  @override
  Future<CommercialPurchaseResult> purchase(String id) async {
    purchases++;
    return purchaseGate?.future ??
        const CommercialPurchaseResult(CommercialPurchaseStatus.cancelled);
  }

  @override
  Future<List<CommercialEntitlement>> restore() async {
    restores++;
    return rights;
  }
}

List<Override> storeOverrides(PreviewStore store) => [
  playerAudienceProvider.overrideWith((_) async => PlayerAudience.adult),
  commercialStoreProvider.overrideWithValue(store),
  commercialOffersProvider.overrideWith((ref) => store.loadOffers()),
];

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets(
    'complete cosmetics kept from Club are not offered for purchase again',
    (tester) async {
      final store = PreviewStore()
        ..offers = [
          CommercialStoreOffer(
            productId: CommercialCatalog.night.id,
            storeProductId: 'test-only',
            localizedPrice: 'PREÇO DE TESTE',
          ),
        ];
      final c = await experience(tester, overrides: storeOverrides(store));
      await tester.runAsync(() async {
        final db = await c.read(databaseProvider).database;
        for (final item in PlayerCollectionCatalog.items.where(
          (item) => item.collectionId == 'night_v1',
        )) {
          await db.insert('collection_ownership', {
            'item_id': item.id,
            'source_id': 'verified-monthly-fixture',
            'granted_at': '2026-10-01T00:00:00Z',
          });
        }
        await c.read(playerCollectionProvider.notifier).load();
      });
      await tester.pumpWidget(
        collectionApp(
          c,
          child: const Scaffold(
            body: SingleChildScrollView(child: CommercialOffersPanel()),
          ),
        ),
      );
      await settleCollection(tester);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNull,
      );
      expect(find.textContaining('PREÇO DE TESTE'), findsNothing);
      expect(store.purchases, 0);
    },
  );

  testWidgets(
    'failed ownership check disables checkout until a successful retry',
    (tester) async {
      final store = PreviewStore()
        ..failRights = true
        ..offers = [
          CommercialStoreOffer(
            productId: CommercialCatalog.premiere.id,
            storeProductId: 'test-only',
            localizedPrice: 'PREÇO DE TESTE',
          ),
        ];
      final c = await experience(tester, overrides: storeOverrides(store));
      await tester.pumpWidget(
        collectionApp(
          c,
          child: const Scaffold(
            body: SingleChildScrollView(child: CommercialOffersPanel()),
          ),
        ),
      );
      await settleCollection(tester);
      expect(
        find.text('Não foi possível verificar suas compras.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNull,
      );
      store.failRights = false;
      await tester.tap(find.byKey(const ValueKey('commerce-retry')));
      await settleCollection(tester);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).first).onPressed,
        isNotNull,
      );
      expect(store.purchases, 0);
    },
  );

  testWidgets(
    'wallet refreshes daily tickets after returning across midnight and preserves extras',
    (tester) async {
      var now = DateTime.utc(2026, 10, 15, 23, 59);
      final c = await experience(
        tester,
        overrides: [appClockProvider.overrideWithValue(() => now)],
      );
      await tester.runAsync(() async {
        final balance = c.read(ticketNotifierProvider.notifier);
        await balance.debitTickets(count: 10);
        await balance.addTickets(3);
      });
      await tester.pumpWidget(
        collectionApp(c, child: const Scaffold(body: TicketDetailsSheet())),
      );
      await settleCollection(tester);
      expect(c.read(ticketNotifierProvider).total, 3);
      await tester.runAsync(() async {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        now = DateTime.utc(2026, 10, 16, 0, 1);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await c.read(monetizationNotifierProvider.notifier).load();
      });
      await settleCollection(tester);
      expect(c.read(ticketNotifierProvider).total, 13);
      expect(c.read(ticketNotifierProvider).extraTickets, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'active Plus hides paid upsell and ad inventory, keeps optional video',
    (tester) async {
      phone(tester);
      final store = PreviewStore()
        ..rights = [
          CommercialEntitlement(
            productId: CommercialCatalog.plus.id,
            verifiedAt: DateTime.utc(2026, 10, 14),
          ),
        ];
      final c = await experience(tester, overrides: storeOverrides(store));
      await warmExperience(tester);
      await tester.pumpWidget(
        collectionApp(
          c,
          child: const RepaintBoundary(
            key: ValueKey('experience-capture'),
            child: Scaffold(
              body: Column(
                children: [
                  AdvertisementPlaceholder(),
                  Expanded(child: TicketDetailsSheet()),
                ],
              ),
            ),
          ),
        ),
      );
      await settleCollection(tester);
      expect(find.text('Publicidade'), findsNothing);
      expect(
        find.byKey(const ValueKey('rewarded-ticket-placement')),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const ValueKey('ticket-details-scroll')),
        const Offset(0, -800),
      );
      await settleCollection(tester);
      expect(
        find.byKey(const ValueKey('commerce-active-benefits')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('plus-offer-placeholder')),
        findsNothing,
      );
      await captureExperience(tester, '09-benefits-active');
      expect(store.purchases, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'subscription expiry removes benefits without a new store response',
    (tester) async {
      var now = DateTime.utc(2026, 10, 15, 18);
      final until = now.add(const Duration(seconds: 2));
      final c = ProviderContainer(
        overrides: [
          appClockProvider.overrideWithValue(() => now),
          commercialEntitlementsProvider.overrideWith(
            (ref) async => [
              CommercialEntitlement(
                productId: CommercialCatalog.club.id,
                verifiedAt: now.subtract(const Duration(days: 1)),
                validUntil: until,
              ),
              CommercialEntitlement(
                productId: CommercialCatalog.plus.id,
                verifiedAt: now,
                revoked: true,
              ),
            ],
          ),
        ],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        c.dispose();
      });
      await tester.pumpWidget(
        collectionApp(
          c,
          child: const Scaffold(body: AdvertisementPlaceholder()),
        ),
      );
      await settleCollection(tester);
      expect(find.text('Publicidade'), findsNothing);
      now = until;
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('Publicidade'), findsOneWidget);
      expect(
        c.read(activeCommercialEntitlementsProvider).requireValue,
        isEmpty,
      );
    },
  );

  testWidgets(
    'store failure is retryable instead of coming soon; restore finishes',
    (tester) async {
      phone(tester);
      final store = PreviewStore()..failOffers = true;
      final c = await experience(tester, overrides: storeOverrides(store));
      await warmExperience(tester);
      await tester.pumpWidget(
        collectionApp(
          c,
          child: const RepaintBoundary(
            key: ValueKey('experience-capture'),
            child: Scaffold(body: TicketDetailsSheet()),
          ),
        ),
      );
      await settleCollection(tester);
      await tester.drag(
        find.byKey(const ValueKey('ticket-details-scroll')),
        const Offset(0, -800),
      );
      await settleCollection(tester);
      expect(find.text('Não foi possível carregar a loja.'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('plus-offer-placeholder')),
        findsNothing,
      );
      await captureExperience(tester, '10-store-retry');
      store.failOffers = false;
      await tester.tap(find.byKey(const ValueKey('commerce-retry')));
      await settleCollection(tester);
      expect(
        find.byKey(const ValueKey('plus-offer-placeholder')),
        findsOneWidget,
      );
      await tester.pumpWidget(
        collectionApp(
          c,
          child: const Scaffold(
            body: SingleChildScrollView(child: CommercialOffersPanel()),
          ),
        ),
      );
      await settleCollection(tester);
      await tester.tap(find.byKey(const ValueKey('commerce-restore')));
      await settleCollection(tester);
      expect(find.text('Nenhuma compra ativa confirmada.'), findsOneWidget);
      expect(c.read(commercialOperationProvider), 'restoreEmpty');
      store.rights = [
        CommercialEntitlement(
          productId: CommercialCatalog.plus.id,
          verifiedAt: DateTime.utc(2026, 10, 14),
        ),
      ];
      await tester.tap(find.byKey(const ValueKey('commerce-restore')));
      await settleCollection(tester);
      expect(find.text('Compras restauradas.'), findsOneWidget);
      expect(store.restores, 2);
      expect(store.purchases, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'purchase waits for verified ownership and tolerates closing checkout',
    (tester) async {
      final store = PreviewStore()
        ..rightsGate = Completer<List<CommercialEntitlement>>()
        ..purchaseGate = Completer<CommercialPurchaseResult>()
        ..offers = [
          CommercialStoreOffer(
            productId: CommercialCatalog.premiere.id,
            storeProductId: 'test-only',
            localizedPrice: 'PREÇO DE TESTE',
          ),
        ];
      final c = await experience(tester, overrides: storeOverrides(store));
      await tester.pumpWidget(
        collectionApp(
          c,
          child: const Scaffold(
            body: SingleChildScrollView(child: CommercialOffersPanel()),
          ),
        ),
      );
      await settleCollection(tester);
      final buttons = find.byType(FilledButton);
      expect(tester.widget<FilledButton>(buttons.first).onPressed, isNull);
      store.rightsGate!.complete([]);
      await settleCollection(tester);
      expect(tester.widget<FilledButton>(buttons.first).onPressed, isNotNull);
      // The localized price is supplied exclusively by the fake store.
      expect(find.textContaining('PREÇO DE TESTE'), findsOneWidget);
      await tester.tap(buttons.first);
      await settleCollection(tester);
      expect(store.purchases, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      store.purchaseGate!.complete(
        const CommercialPurchaseResult(CommercialPurchaseStatus.cancelled),
      );
      await settleCollection(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'collection explains locked items and filters owned inventory without granting previews',
    (tester) async {
      phone(tester);
      final c = await experience(tester);
      await warmExperience(tester);
      final before = c.read(playerCollectionProvider).profile!;
      final router = AppRouter.create(initialLocation: '/collection');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('experience-capture'),
          child: UncontrolledProviderScope(
            container: c,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              locale: const Locale('pt'),
              supportedLocales: AppL10n.supportedLocales,
              localizationsDelegates: AppL10n.localizationsDelegates,
              routerConfig: router,
            ),
          ),
        ),
      );
      await settleCollection(tester);
      final locked = find.byKey(
        const ValueKey('collection-item-night_avatar_raccoon_v1'),
      );
      for (var i = 0; locked.hitTestable().evaluate().isEmpty && i < 20; i++) {
        await tester.drag(
          find.byKey(const ValueKey('collection-scroll')),
          const Offset(0, -220),
        );
        await settleCollection(tester);
      }
      expect(locked.hitTestable(), findsOneWidget);
      await tester.tap(locked);
      await settleCollection(tester);
      await tester.tap(find.byKey(const ValueKey('collection-apply')));
      await settleCollection(tester);
      expect(
        find.text('Conclua missões da semana para desbloquear este visual.'),
        findsOneWidget,
      );
      await captureExperience(tester, '11-item-how-to-get');
      expect(c.read(playerCollectionProvider).profile!.owned, before.owned);
      expect(
        c.read(playerCollectionProvider).profile!.equipped,
        before.equipped,
      );
      await tester.tap(find.byKey(const ValueKey('collection-unlock-action')));
      await settleCollection(tester);
      expect(find.byType(JourneyScreen), findsOneWidget);
      router.pop();
      await tester.pump(const Duration(seconds: 1));
      await settleCollection(tester);
      final ownFilter = find.byKey(const ValueKey('collection-filter-true'));
      for (
        var i = 0;
        ownFilter.hitTestable().evaluate().isEmpty && i < 20;
        i++
      ) {
        await tester.drag(
          find.byKey(const ValueKey('collection-scroll')),
          const Offset(0, 220),
        );
        await settleCollection(tester);
      }
      expect(ownFilter.hitTestable(), findsOneWidget);
      await tester.tap(ownFilter);
      await settleCollection(tester);
      expect(
        find.byKey(const ValueKey('collection-item-night_avatar_raccoon_v1')),
        findsNothing,
      );
      await captureExperience(tester, '12-owned-collection');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'archived looks keep their mission reward path without coming soon',
    (tester) async {
      final c = await experience(tester);
      final content = (await tester.runAsync(
        () => c.read(commerceContentProvider.future),
      ))!;
      final season = content.collections.first;
      await tester.pumpWidget(
        collectionApp(
          c,
          child: Scaffold(
            body: SeasonPreviewSheet(collection: season, now: season.until),
          ),
        ),
      );
      await settleCollection(tester);
      await tester.drag(
        find.byKey(const ValueKey('season-preview-scroll')),
        const Offset(0, -1000),
      );
      await settleCollection(tester);
      expect(
        find.text(
          'Os visuais entram na rotação das missões. O que você já conquistou continua seu.',
        ),
        findsOneWidget,
      );
      expect(find.text('Em breve'), findsNothing);
    },
  );

  testWidgets(
    'next with no tickets opens wallet without changing result or charging',
    (tester) async {
      await fixture(tester, (c, db, share, router) async {
        await tester.runAsync(() async {
          final n = c.read(ticketNotifierProvider.notifier);
          await n.debitTickets(count: c.read(ticketNotifierProvider).total);
        });
        await settleChanges(tester);
        await tapVisible(tester, find.byKey(const ValueKey('next-stage-film')));
        await settleCollection(tester);
        expect(find.byType(TicketDetailsSheet), findsOneWidget);
        expect(c.read(ticketNotifierProvider).total, 0);
        expect(router.routeInformationProvider.value.uri.path, '/result');
      });
    },
  );
}
