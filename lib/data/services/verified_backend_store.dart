import '../../domain/entities/commercial_product.dart';
import '../../domain/services/commercial_store.dart';
import 'commerce_synchronizer.dart';

/// Verified rights, including a bounded offline window for temporary benefits.
class VerifiedBackendStore implements CommercialStore {
  final CommerceSynchronizer synchronizer;
  VerifiedBackendStore(this.synchronizer);
  @override
  Future<List<CommercialStoreOffer>> loadOffers() async => const [];
  @override
  Future<CommercialPurchaseResult> purchase(String productId) =>
      Future.error(StateError('Native store purchase is not configured'));
  List<CommercialEntitlement> _current() => [
    for (final grant in synchronizer.current?.grants ?? [])
      CommercialEntitlement(
        productId: grant.product,
        verifiedAt: DateTime.fromMillisecondsSinceEpoch(
          grant.validFrom * 1000,
          isUtc: true,
        ),
        validUntil: grant.validUntil == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (grant.product == CommercialCatalog.club.id &&
                            grant.validUntil! >
                                synchronizer.current!.issuedAt + 86400
                        ? synchronizer.current!.issuedAt + 86400
                        : grant.validUntil!) *
                    1000,
                isUtc: true,
              ),
        revoked: grant.revoked,
      ),
  ];
  @override
  Future<List<CommercialEntitlement>> loadEntitlements() async {
    try {
      await synchronizer.synchronize();
    } catch (_) {
      if (synchronizer.current == null) rethrow;
    }
    return _current();
  }

  @override
  Future<List<CommercialEntitlement>> restore() async {
    await synchronizer.synchronize(reconcile: true);
    return _current();
  }
}
