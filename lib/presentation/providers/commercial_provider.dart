import 'dart:async';
import 'audience_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/commercial_configuration.dart';
import '../../domain/entities/commercial_product.dart';
import '../../domain/entities/player_audience.dart';
import '../../domain/services/commercial_store.dart';
import '../../data/services/unavailable_commercial_store.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/commerce_snapshot.dart';
import '../../data/services/commerce_gateway.dart';
import '../../data/services/commerce_synchronizer.dart';
import '../../data/services/verified_backend_store.dart';
import '../../data/services/native_commercial_store.dart';
import '../../data/services/mobile_ads_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'telemetry_provider.dart';
import '../../data/repositories/commerce_cache_repository.dart';
import '../../data/repositories/rewarded_help_repository.dart';
import 'providers.dart';
import 'player_collection_provider.dart';
import 'app_clock.dart';
import 'commerce_content_provider.dart';

final commercialConfigurationProvider = Provider<CommercialConfiguration>(
  (_) => CommercialConfiguration.fromBuild(),
);

final commerceBackendConfigurationProvider =
    Provider<CommerceBackendConfiguration>((ref) {
      final environment = ref
          .watch(commercialConfigurationProvider)
          .environment
          .name;
      return kIsWeb
          ? CommerceBackendConfiguration(environment: environment)
          : CommerceBackendConfiguration.fromBuild(environment);
    });

final Provider<CommerceSynchronizer?> commerceSynchronizerProvider =
    Provider<CommerceSynchronizer?>((ref) {
      final configuration = ref.watch(commerceBackendConfigurationProvider);
      if (!configuration.enabled) return null;
      final client = http.Client();
      var disposed = false;
      ref.onDispose(() {
        disposed = true;
        client.close();
      });
      final verifier = CommerceSnapshotVerifier(
        configuration,
        now: ref.read(appClockProvider),
      );
      final cache = CommerceCacheRepository(
        ref.read(databaseProvider),
        verifier,
      );
      final help = RewardedHelpRepository(
        ref.read(databaseProvider),
        ref.read(appClockProvider),
      );
      return CommerceSynchronizer(
        gateway: CommerceGateway(configuration, client, verifier),
        identityStorage: SecureCommerceIdentityStorage(configuration.scope),
        cache: cache,
        credit: (identity, receipt) async {
          if (disposed) throw StateError('Commercial scope disposed');
          await ref
              .read(ticketNotifierProvider.notifier)
              .creditOnce(
                key: cache.rewardKey(identity, receipt.id),
                amount: 2,
                verify: (db) => cache.verifyReward(db, identity, receipt.id),
              );
          await help.delivered(receipt.attempt);
        },
        onChanged: () async {
          if (!disposed && ref.exists(playerCollectionProvider)) {
            await ref.read(playerCollectionProvider.notifier).load();
          }
        },
      );
    });

final Provider<CommercialStore> commercialStoreProvider =
    Provider<CommercialStore>((ref) {
      final synchronizer = ref.watch(commerceSynchronizerProvider);
      if (synchronizer == null) return const UnavailableCommercialStore();
      final products = NativeCommercialStore.configuredProducts();
      if (kIsWeb ||
          products.isEmpty ||
          !{
            TargetPlatform.android,
            TargetPlatform.iOS,
          }.contains(defaultTargetPlatform)) {
        return VerifiedBackendStore(synchronizer);
      }
      final telemetry = ref.read(productTelemetryProvider);
      final store = NativeCommercialStore(
        synchronizer,
        billing: InAppPurchase.instance,
        products: products,
        canPurchase: () =>
            ref.read(playerAudienceProvider).valueOrNull?.canPurchase == true,
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'apple'
            : 'google',
        changed: (product, status) {
          ref.read(commercialOperationProvider.notifier).state =
              status?.name ?? 'failed';
          if (status == CommercialPurchaseStatus.verified) {
            telemetry.record(
              'purchase_verified',
              properties: {'product_id': product},
            );
          }
          ref.invalidate(commercialEntitlementsProvider);
        },
      );
      ref.onDispose(store.dispose);
      return store;
    });

final commercialOperationProvider = StateProvider<String?>((_) => null);

final commercialEntitlementsProvider =
    FutureProvider<List<CommercialEntitlement>>(
      (ref) => ref.watch(commercialStoreProvider).loadEntitlements(),
    );

/// Shared presentation snapshot. Expiring benefits must not stay visible just
/// because the store FutureProvider still contains the same cached response.
final activeCommercialEntitlementsProvider =
    Provider<AsyncValue<List<CommercialEntitlement>>>((ref) {
      final rights = ref.watch(commercialEntitlementsProvider);
      final now = ref.watch(appClockProvider)();
      final boundaries = <DateTime>[
        for (final right in rights.asData?.value ?? <CommercialEntitlement>[])
          if (!right.revoked) ...[
            if (right.verifiedAt.isAfter(now)) right.verifiedAt,
            if (right.validUntil?.isAfter(now) ?? false) right.validUntil!,
          ],
      ]..sort();
      if (boundaries.isNotEmpty) {
        final timer = Timer(
          boundaries.first.difference(now) + const Duration(milliseconds: 1),
          ref.invalidateSelf,
        );
        ref.onDispose(timer.cancel);
      }
      return rights.whenData(
        (items) => items.where((right) => right.activeAt(now)).toList(),
      );
    });

/// No offer without both explicit feature configuration and a store price.
final commercialOffersProvider = FutureProvider<List<CommercialStoreOffer>>((
  ref,
) async {
  final configuration = ref.watch(commercialConfigurationProvider);
  final audience = ref.watch(playerAudienceProvider).valueOrNull;
  if (audience?.canPurchase != true) return const [];
  final store = ref.watch(commercialStoreProvider);
  final offers = await store.loadOffers();
  if (offers.isEmpty) return const [];
  final content = await ref.watch(commerceContentProvider.future);
  final now = ref.read(appClockProvider)();
  return offers
      .where(
        (offer) =>
            configuration.canOffer(offer, storeReady: true) &&
            (!{
                  CommercialCatalog.night.id,
                  CommercialCatalog.city.id,
                }.contains(offer.productId) ||
                content.collections.any(
                  (c) => c.product == offer.productId && c.visible(now),
                )) &&
            (offer.productId != CommercialCatalog.club.id ||
                (const bool.fromEnvironment('CINEUS_CLUB_APPROVED') &&
                    content.clubReady(now))) &&
            (offer.productId != CommercialCatalog.plus.id ||
                _regularAdsAvailable(configuration, audience)),
      )
      .toList();
});

bool _regularAdsAvailable(CommercialConfiguration c, PlayerAudience? audience) {
  final ads = MobileAdsConfiguration.fromBuild().forAudience(audience);
  return ads.enabled(c) &&
      ((c.nativeAds && ads.validUnit(ads.nativeUnit, c.environment)) ||
          (c.banners && ads.validUnit(ads.bannerUnit, c.environment)) ||
          (c.interstitials &&
              const bool.fromEnvironment('CINEUS_INTERSTITIAL_APPROVED') &&
              ads.validUnit(ads.interstitialUnit, c.environment)));
}
