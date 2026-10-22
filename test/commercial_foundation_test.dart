import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/domain/entities/commercial_configuration.dart';
import 'package:cineus/domain/entities/commercial_product.dart';
import 'package:cineus/data/services/configured_monetization_service.dart';
import 'package:cineus/data/services/disabled_monetization_service.dart';
import 'package:cineus/data/services/unavailable_commercial_store.dart';
import 'package:cineus/domain/entities/monetization.dart';
import 'package:cineus/domain/services/monetization_service.dart';
import 'package:cineus/presentation/providers/commercial_provider.dart';

class _LegacyStore implements MonetizationService {
  var calls = 0;
  @override
  Future<void> initialize() async {
    calls++;
  }

  @override
  Future<bool> isRewardedAvailable() async {
    calls++;
    return true;
  }

  @override
  Future<bool> showRewarded() async {
    calls++;
    return true;
  }

  @override
  Future<PassEntitlement> loadPassEntitlement() async {
    calls++;
    return const PassEntitlement(
      storeAvailable: true,
      active: true,
      displayPrice: 'R\$ 9,90',
    );
  }

  @override
  Future<void> purchasePass() async {
    calls++;
  }

  @override
  Future<void> restorePass() async {
    calls++;
  }
}

void main() {
  final now = DateTime.utc(2026, 10, 14);
  CommercialStoreOffer offer(String id, {String price = 'R\$ 14,90'}) =>
      CommercialStoreOffer(
        productId: id,
        storeProductId: 'store.example',
        localizedPrice: price,
      );

  test(
    'permanent collection does not grant advertising or subscription benefits',
    () {
      final grant = CommercialEntitlement(
        productId: CommercialCatalog.premiere.id,
        verifiedAt: now.subtract(const Duration(days: 1)),
      );
      expect(grant.grants(CommercialBenefit.cosmeticCollection, now), isTrue);
      expect(grant.grants(CommercialBenefit.removeInterruptions, now), isFalse);
      expect(grant.grants(CommercialBenefit.monthlyCollection, now), isFalse);
      expect(
        CommercialEntitlement(
          productId: 'unknown',
          verifiedAt: now,
        ).activeAt(now),
        isFalse,
      );
    },
  );

  test(
    'expired or revoked Club cannot erase an independent permanent Plus',
    () {
      final grants = [
        CommercialEntitlement(
          productId: CommercialCatalog.plus.id,
          verifiedAt: now,
        ),
        CommercialEntitlement(
          productId: CommercialCatalog.club.id,
          verifiedAt: now.subtract(const Duration(days: 30)),
          validUntil: now,
        ),
        CommercialEntitlement(
          productId: CommercialCatalog.club.id,
          verifiedAt: now,
          validUntil: now.add(const Duration(days: 30)),
          revoked: true,
        ),
      ];
      expect(grants[1].activeAt(now), isFalse);
      expect(grants[2].activeAt(now), isFalse);
      expect(
        grants.any((g) => g.grants(CommercialBenefit.removeInterruptions, now)),
        isTrue,
      );
      expect(
        grants.any((g) => g.grants(CommercialBenefit.monthlyCollection, now)),
        isFalse,
      );
      expect(
        CommercialEntitlement(
          productId: CommercialCatalog.club.id,
          verifiedAt: now,
        ).activeAt(now),
        isFalse,
      );
      expect(
        CommercialEntitlement(
          productId: CommercialCatalog.plus.id,
          verifiedAt: now.add(const Duration(days: 1)),
        ).activeAt(now),
        isFalse,
      );
    },
  );

  test(
    'flags never create store availability, reference prices or early Plus offers',
    () {
      const enabled = CommercialConfiguration(
        collections: true,
        plus: true,
        club: true,
      );
      expect(
        enabled.canOffer(
          offer(CommercialCatalog.premiere.id),
          storeReady: false,
        ),
        isFalse,
      );
      expect(
        enabled.canOffer(
          offer(CommercialCatalog.premiere.id, price: ''),
          storeReady: true,
        ),
        isFalse,
      );
      expect(enabled.canOffer(offer('unknown'), storeReady: true), isFalse);
      expect(
        enabled.canOffer(offer(CommercialCatalog.plus.id), storeReady: true),
        isFalse,
      );
      expect(
        enabled.canOffer(
          offer(CommercialCatalog.premiere.id),
          storeReady: true,
        ),
        isTrue,
      );
      expect(
        const CommercialConfiguration().canOffer(
          offer(CommercialCatalog.club.id),
          storeReady: true,
        ),
        isFalse,
      );
    },
  );

  test('default production providers have no purchasable offer', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(commercialOffersProvider.future), isEmpty);
    const store = UnavailableCommercialStore();
    expect(await store.loadEntitlements(), isEmpty);
    expect(store.purchase(CommercialCatalog.premiere.id), throwsStateError);
  });

  test('disabled features do not initialize or invoke legacy SDKs', () async {
    final legacy = _LegacyStore();
    final service = ConfiguredMonetizationService(
      const CommercialConfiguration(),
      legacy,
    );
    await service.initialize();
    expect(await service.isRewardedAvailable(), isFalse);
    expect(await service.showRewarded(), isFalse);
    expect((await service.loadPassEntitlement()).storeAvailable, isFalse);
    await service.purchasePass();
    await service.restorePass();
    expect(legacy.calls, 0);
    final unavailable = ConfiguredMonetizationService(
      const CommercialConfiguration(rewarded: true),
      const DisabledMonetizationService(),
    );
    expect(await unavailable.isRewardedAvailable(), isFalse);
  });
}
