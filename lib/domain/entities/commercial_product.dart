enum CommercialProductKind {
  permanentCollection,
  permanentPlus,
  subscription,
  consumableTickets,
}

enum CommercialBenefit {
  cosmeticCollection,
  removeInterruptions,
  monthlyCollection,
  tickets,
}

/// Internal IDs are stable. Store identifiers are assigned independently by
/// each adapter; none of these IDs implies a product already exists in a store.
class CommercialProduct {
  final String id;
  final CommercialProductKind kind;
  final Set<CommercialBenefit> benefits;
  final String? collectionId;
  final int ticketAmount;

  const CommercialProduct({
    required this.id,
    required this.kind,
    required this.benefits,
    this.collectionId,
    this.ticketAmount = 0,
  });
}

abstract final class CommercialCatalog {
  static const version = 1;
  static const premiere = CommercialProduct(
    id: 'cineus.collection.premiere.v1',
    kind: CommercialProductKind.permanentCollection,
    benefits: {CommercialBenefit.cosmeticCollection},
    collectionId: 'premiere_v1',
  );
  static const plus = CommercialProduct(
    id: 'cineus.plus.permanent.v1',
    kind: CommercialProductKind.permanentPlus,
    benefits: {
      CommercialBenefit.cosmeticCollection,
      CommercialBenefit.removeInterruptions,
    },
    collectionId: 'plus_v1',
  );
  static const club = CommercialProduct(
    id: 'cineus.club.monthly.v1',
    kind: CommercialProductKind.subscription,
    benefits: {
      CommercialBenefit.removeInterruptions,
      CommercialBenefit.monthlyCollection,
    },
  );
  static const night = CommercialProduct(
    id: 'cineus.collection.night.v1',
    kind: CommercialProductKind.permanentCollection,
    benefits: {CommercialBenefit.cosmeticCollection},
    collectionId: 'night_v1',
  );
  static const city = CommercialProduct(
    id: 'cineus.collection.city.v1',
    kind: CommercialProductKind.permanentCollection,
    benefits: {CommercialBenefit.cosmeticCollection},
    collectionId: 'city_v1',
  );
  static const tickets20 = CommercialProduct(
    id: 'cineus.tickets.20.v1',
    kind: CommercialProductKind.consumableTickets,
    benefits: {CommercialBenefit.tickets},
    ticketAmount: 20,
  );
  static const tickets60 = CommercialProduct(
    id: 'cineus.tickets.60.v1',
    kind: CommercialProductKind.consumableTickets,
    benefits: {CommercialBenefit.tickets},
    ticketAmount: 60,
  );
  static const products = [
    premiere,
    plus,
    club,
    night,
    city,
    tickets20,
    tickets60,
  ];

  static CommercialProduct? byId(String id) =>
      products.where((p) => p.id == id).firstOrNull;
}

/// This is a value returned by a future trusted store/backend adapter, never
/// evidence that a client-supplied boolean or local preference proves payment.
class CommercialEntitlement {
  final String productId;
  final DateTime verifiedAt;
  final DateTime? validUntil;
  final bool revoked;

  const CommercialEntitlement({
    required this.productId,
    required this.verifiedAt,
    this.validUntil,
    this.revoked = false,
  });

  bool activeAt(DateTime now) {
    final product = CommercialCatalog.byId(productId);
    if (product == null || revoked || now.isBefore(verifiedAt)) return false;
    if (product.kind == CommercialProductKind.subscription) {
      return validUntil != null && now.isBefore(validUntil!);
    }
    return validUntil == null;
  }

  bool grants(CommercialBenefit benefit, DateTime now) =>
      activeAt(now) &&
      CommercialCatalog.byId(productId)!.benefits.contains(benefit);
}

/// Display price must come from a store response, not the planning reference.
class CommercialStoreOffer {
  final String productId;
  final String storeProductId;
  final String localizedPrice;

  const CommercialStoreOffer({
    required this.productId,
    required this.storeProductId,
    required this.localizedPrice,
  });

  bool get isUsable =>
      CommercialCatalog.byId(productId) != null &&
      storeProductId.trim().isNotEmpty &&
      localizedPrice.trim().isNotEmpty;
}
