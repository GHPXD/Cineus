import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import '../../domain/entities/commercial_product.dart';
import '../../domain/services/commercial_store.dart';
import 'verified_backend_store.dart';

/// The stream is subscribed before querying offers. Unfinished transactions are
/// completed only after the server has durably processed the verified proof.
class NativeCommercialStore extends VerifiedBackendStore {
  final InAppPurchase billing;
  final Map<String, String> products; // native store ID -> internal product ID
  final String platform;
  final bool Function() canPurchase;
  final void Function(String product, CommercialPurchaseStatus? status) changed;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  final Map<String, ProductDetails> _details = {};
  final Map<String, PurchaseDetails> _retry = {};
  final Map<String, Completer<CommercialPurchaseResult>> _waiting = {};
  final Set<String> _pendingProducts = {};
  bool _restoring = false;
  bool get verificationPending =>
      _restoring ||
      _waiting.isNotEmpty ||
      _retry.isNotEmpty ||
      _pendingProducts.isNotEmpty;
  Future<void> _queue = Future.value();
  bool _disposed = false;
  NativeCommercialStore(
    super.synchronizer, {
    required this.billing,
    required this.products,
    required this.platform,
    required this.changed,
    this.canPurchase = _allowPurchase,
  }) {
    _subscription = billing.purchaseStream.listen(
      (batch) {
        _queue = _queue.then((_) => _process(batch)).catchError((Object _) {});
      },
      onError: (Object _) {
        changed('', null);
      },
    );
  }

  static bool _allowPurchase() => true;

  static Map<String, String> configuredProducts() {
    try {
      final raw = defaultTargetPlatform == TargetPlatform.iOS
          ? const String.fromEnvironment(
              'CINEUS_APPLE_PRODUCTS',
              defaultValue: '{}',
            )
          : const String.fromEnvironment(
              'CINEUS_GOOGLE_PRODUCTS',
              defaultValue: '{}',
            );
      final values = jsonDecode(raw) as Map<String, dynamic>;
      if (values.length > 20 || values.values.toSet().length != values.length) {
        return {};
      }
      return {
        for (final entry in values.entries)
          if (entry.key.isNotEmpty &&
              entry.key.length <= 200 &&
              entry.value is String &&
              CommercialCatalog.byId(entry.value) != null)
            entry.key: entry.value as String,
      };
    } catch (_) {
      return {};
    }
  }

  @override
  Future<List<CommercialStoreOffer>> loadOffers() async {
    _details.clear();
    if (products.isEmpty || !await billing.isAvailable()) return [];
    final response = await billing.queryProductDetails(products.keys.toSet());
    if (response.error != null) return [];
    for (final item in response.productDetails) {
      if (products.containsKey(item.id) && _supportedPlan(item)) {
        _details[item.id] = item;
      }
    }
    return [
      for (final item in _details.values)
        CommercialStoreOffer(
          productId: products[item.id]!,
          storeProductId: item.id,
          localizedPrice: item.price,
        ),
    ];
  }

  bool _supportedPlan(ProductDetails item) {
    if (products[item.id] != CommercialCatalog.club.id) return true;
    if (item is GooglePlayProductDetails) {
      final index = item.subscriptionIndex;
      if (index == null) return false;
      final offer = item.productDetails.subscriptionOfferDetails![index];
      return offer.basePlanId ==
              const String.fromEnvironment('CINEUS_GOOGLE_CLUB_BASE_PLAN') &&
          offer.offerId == null &&
          offer.pricingPhases.length == 1 &&
          offer.pricingPhases.single.billingPeriod == 'P1M';
    }
    if (item is AppStoreProduct2Details) {
      final period = item.sk2Product.subscription?.subscriptionPeriod;
      return item.sk2Product.type == SK2ProductType.autoRenewable &&
          period?.value == 1 &&
          period?.unit == SK2SubscriptionPeriodUnit.month;
    }
    return false;
  }

  @override
  Future<CommercialPurchaseResult> purchase(String productId) async {
    if (!canPurchase()) throw StateError('Adult purchase eligibility required');
    if (_waiting.isNotEmpty) throw StateError('Purchase already in progress');
    if (_details.isEmpty) await loadOffers();
    final entry = _details.values
        .where((p) => products[p.id] == productId)
        .firstOrNull;
    if (entry == null) throw StateError('Store offer unavailable');
    await synchronizer.synchronize();
    final identity = synchronizer.identity;
    if (identity == null || !identity.registered) {
      throw StateError('Commercial identity unavailable');
    }
    if (!canPurchase()) throw StateError('Adult purchase eligibility required');
    final pending = Completer<CommercialPurchaseResult>();
    _waiting[entry.id] = pending;
    try {
      final parameter = PurchaseParam(
        productDetails: entry,
        applicationUserName: identity.owner,
      );
      final consumable =
          CommercialCatalog.byId(productId)!.kind ==
          CommercialProductKind.consumableTickets;
      final launched = consumable
          ? await billing.buyConsumable(
              purchaseParam: parameter,
              autoConsume: false,
            )
          : await billing.buyNonConsumable(purchaseParam: parameter);
      if (!launched) throw StateError('Store did not start purchase');
      return await pending.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () =>
            const CommercialPurchaseResult(CommercialPurchaseStatus.pending),
      );
    } finally {
      _waiting.remove(entry.id);
    }
  }

  void _finish(PurchaseDetails item, CommercialPurchaseStatus status) {
    if (_disposed) return;
    changed(products[item.productID] ?? '', status);
    final waiting = _waiting[item.productID];
    if (waiting != null && !waiting.isCompleted) {
      waiting.complete(CommercialPurchaseResult(status));
    }
  }

  Future<void> _process(List<PurchaseDetails> batch) async {
    for (final item in batch) {
      if (_disposed || !products.containsKey(item.productID)) continue;
      if (item.status == PurchaseStatus.pending) {
        _pendingProducts.add(item.productID);
      } else {
        _pendingProducts.remove(item.productID);
      }
      if (item.status == PurchaseStatus.pending) {
        _finish(item, CommercialPurchaseStatus.pending);
      } else if (item.status == PurchaseStatus.canceled) {
        _finish(item, CommercialPurchaseStatus.cancelled);
      } else if (item.status == PurchaseStatus.error) {
        changed(products[item.productID]!, null);
        final waiting = _waiting[item.productID];
        if (waiting != null && !waiting.isCompleted) {
          waiting.completeError(StateError('Store purchase failed'));
        }
        _waiting.remove(item.productID);
      } else {
        final key =
            '${item.productID}:${item.purchaseID ?? item.transactionDate}';
        _retry[key] = item;
        try {
          // Apple SDK defaults to StoreKit 2. Server fetches and verifies JWS
          // using the numeric transaction ID; Google uses its purchase token.
          final proof = platform == 'apple'
              ? item.purchaseID
              : item.verificationData.serverVerificationData;
          if (proof == null || proof.isEmpty) {
            throw StateError('Missing purchase proof');
          }
          final snapshot = await synchronizer.verifyPurchase(platform, proof);
          final matching = snapshot.grants.where(
            (g) => g.product == products[item.productID],
          );
          if (matching.isEmpty) {
            throw StateError('Server did not verify this product');
          }
          final consumable =
              CommercialCatalog.byId(products[item.productID]!)!.kind ==
              CommercialProductKind.consumableTickets;
          if (consumable &&
              platform == 'google' &&
              matching.any((g) => g.activeAt(snapshot.issuedAt))) {
            // Credit is already durable on the server. Consumption allows a
            // second pack; redelivery can only re-verify the same ledger source.
            final response = await billing
                .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
                .consumePurchase(item);
            if (response.responseCode != BillingResponse.ok &&
                response.responseCode != BillingResponse.itemNotOwned) {
              throw StateError('Consumption pending');
            }
          }
          if (item.pendingCompletePurchase) {
            await billing.completePurchase(item);
          }
          _retry.remove(key);
          final active = matching.any((g) => g.activeAt(snapshot.issuedAt));
          _finish(
            item,
            active
                ? CommercialPurchaseStatus.verified
                : CommercialPurchaseStatus.cancelled,
          );
        } catch (_) {
          // Keep transaction unfinished. The native queue redelivers after a
          // process crash; foreground retries also recover a transient failure.
          changed(products[item.productID]!, null);
          final waiting = _waiting.remove(item.productID);
          if (waiting != null && !waiting.isCompleted) {
            waiting.completeError(
              StateError('Verification pending; retry restore'),
            );
          }
        }
      }
    }
  }

  Future<void> retryPending() async {
    final batch = _retry.values.toList();
    _queue = _queue.then((_) => _process(batch));
    await _queue;
  }

  @override
  Future<List<CommercialEntitlement>> restore() async {
    _restoring = true;
    try {
      await synchronizer.synchronize();
      await billing.restorePurchases(
        applicationUserName: synchronizer.identity!.owner,
      );
      await _queue;
      await retryPending();
      return await super.restore();
    } finally {
      _restoring = false;
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await _subscription.cancel();
    for (final waiting in _waiting.values) {
      if (!waiting.isCompleted) {
        waiting.completeError(StateError('Store disposed'));
      }
    }
    _waiting.clear();
  }
}
