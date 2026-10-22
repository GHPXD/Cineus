import '../entities/commercial_product.dart';

enum CommercialPurchaseStatus { pending, cancelled, verified }

/// Platform/backend adapter contract for sprints 4–5. A verified result must
/// contain trusted grants, not a UI flag. Restore returns a complete snapshot;
/// callers reconcile grants by origin instead of blindly appending inventory.
class CommercialPurchaseResult {
  final CommercialPurchaseStatus status;
  final List<CommercialEntitlement> entitlements;
  const CommercialPurchaseResult(this.status, {this.entitlements = const []});
}

abstract class CommercialStore {
  Future<List<CommercialStoreOffer>> loadOffers();
  Future<List<CommercialEntitlement>> loadEntitlements();
  Future<CommercialPurchaseResult> purchase(String productId);
  Future<List<CommercialEntitlement>> restore();
}
