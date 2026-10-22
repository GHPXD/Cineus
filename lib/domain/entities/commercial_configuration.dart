import 'commercial_product.dart';

enum CommercialEnvironment { development, sandbox, production }

/// Build-time switches express intent, never provider availability or consent.
/// No credentials, store products or monetization SDK are shipped in sprint 1.
class CommercialConfiguration {
  final CommercialEnvironment environment;
  final bool collections,
      plus,
      club,
      rewarded,
      interstitials,
      localMetrics,
      banners,
      nativeAds,
      tickets;

  const CommercialConfiguration({
    this.environment = CommercialEnvironment.development,
    this.collections = false,
    this.plus = false,
    this.club = false,
    this.rewarded = false,
    this.interstitials = false,
    this.localMetrics = false,
    this.banners = false,
    this.nativeAds = false,
    this.tickets = false,
  });

  factory CommercialConfiguration.fromBuild() {
    const name = String.fromEnvironment(
      'CINEUS_ENV',
      defaultValue: 'production',
    );
    if (!{'development', 'sandbox', 'production'}.contains(name)) {
      return const CommercialConfiguration(
        environment: CommercialEnvironment.production,
      );
    }
    return CommercialConfiguration(
      environment: switch (name) {
        'sandbox' => CommercialEnvironment.sandbox,
        'production' => CommercialEnvironment.production,
        _ => CommercialEnvironment.development,
      },
      // Legacy ownership/restoration remain supported; new cosmetic sales and
      // subscriptions are paused until recurring demand is demonstrated.
      collections: false,
      plus: const bool.fromEnvironment('CINEUS_PLUS'),
      club: false,
      rewarded: const bool.fromEnvironment('CINEUS_REWARDED'),
      interstitials: const bool.fromEnvironment('CINEUS_INTERSTITIALS'),
      localMetrics: const bool.fromEnvironment('CINEUS_LOCAL_METRICS'),
      banners: const bool.fromEnvironment('CINEUS_BANNERS'),
      nativeAds: const bool.fromEnvironment('CINEUS_NATIVE_ADS'),
      tickets: const bool.fromEnvironment('CINEUS_TICKET_PACKS'),
    );
  }

  bool canOffer(CommercialStoreOffer offer, {required bool storeReady}) {
    if (!storeReady || !offer.isUsable) return false;
    return switch (CommercialCatalog.byId(offer.productId)!.kind) {
      CommercialProductKind.permanentCollection => collections,
      CommercialProductKind.permanentPlus =>
        plus && (interstitials || nativeAds || banners),
      CommercialProductKind.subscription => club,
      CommercialProductKind.consumableTickets => tickets,
    };
  }
}
