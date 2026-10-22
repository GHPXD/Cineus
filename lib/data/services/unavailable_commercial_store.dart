import '../../domain/entities/commercial_product.dart';
import '../../domain/services/commercial_store.dart';

/// No production store product exists until configured and validated externally.
class UnavailableCommercialStore implements CommercialStore {
  const UnavailableCommercialStore();
  @override
  Future<List<CommercialStoreOffer>> loadOffers() async => const [];
  @override
  Future<List<CommercialEntitlement>> loadEntitlements() async => const [];
  @override
  Future<CommercialPurchaseResult> purchase(String productId) async =>
      throw StateError('Commercial store unavailable');
  @override
  Future<List<CommercialEntitlement>> restore() async => const [];
}
