import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:cineus/data/services/native_commercial_store.dart';
import 'package:cineus/data/services/commerce_synchronizer.dart';
import 'package:cineus/domain/entities/commerce_snapshot.dart';
import 'package:cineus/domain/entities/commercial_product.dart';
import 'package:cineus/domain/services/commercial_store.dart';

class Billing extends Fake implements InAppPurchase {
  final events = StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  int completed = 0, restores = 0;
  PurchaseParam? sent;
  bool available = true;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => events.stream;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
        productDetails: [
          ProductDetails(
            id: 'native.premiere',
            title: 'Estreia',
            description: 'Six items',
            price: 'R\$ 14,90',
            rawPrice: 14.90,
            currencyCode: 'BRL',
          ),
        ],
        notFoundIDs: [],
      );
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    sent = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed++;
    purchase.pendingCompletePurchase = false;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restores++;
    events.add([purchase(PurchaseStatus.restored)]);
  }
}

PurchaseDetails purchase(PurchaseStatus status) => PurchaseDetails(
  purchaseID: '1234567',
  productID: 'native.premiere',
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: 'google-token',
    source: 'google_play',
  ),
  transactionDate: '1791979200000',
  status: status,
)..pendingCompletePurchase = true;

class Sync extends Fake implements CommerceSynchronizer {
  final CommerceSnapshot value;
  bool fail = false;
  int checks = 0;
  String? proof, platform;
  Sync(this.value);
  @override
  CommerceIdentity? get identity => value.identity;
  @override
  CommerceSnapshot? get current => value;
  @override
  Future<CommerceSnapshot?> synchronize({bool reconcile = false}) async =>
      value;
  @override
  Future<CommerceSnapshot> verifyPurchase(String p, String token) async {
    checks++;
    proof = token;
    platform = p;
    if (fail) throw StateError('Network lost');
    return value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Billing billing;
  late Sync sync;
  late NativeCommercialStore store;
  final states = <CommercialPurchaseStatus?>[];
  setUp(() async {
    final fixture =
        jsonDecode(
              File(
                'test/fixtures/commerce_snapshot_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final verifier = CommerceSnapshotVerifier(
      CommerceBackendConfiguration(
        endpoint: Uri.parse('https://commerce.test'),
        environment: 'sandbox',
        publicKey: base64Decode(fixture['public_key']),
      ),
      now: () =>
          DateTime.fromMillisecondsSinceEpoch(1791979200000, isUtc: true),
    );
    final value = await verifier.verify(
      jsonEncode(fixture['envelope']),
      CommerceIdentity.fromJson(fixture['identity']),
    );
    billing = Billing();
    sync = Sync(value);
    states.clear();
    store = NativeCommercialStore(
      sync,
      billing: billing,
      products: {'native.premiere': CommercialCatalog.premiere.id},
      platform: 'google',
      changed: (_, s) => states.add(s),
    );
  });
  tearDown(() async {
    await store.dispose();
    await billing.events.close();
  });
  test(
    'offer uses native localized price and missing store hides it',
    () async {
      expect((await store.loadOffers()).single.localizedPrice, 'R\$ 14,90');
      billing.available = false;
      expect(await store.loadOffers(), isEmpty);
    },
  );
  test(
    'purchase binds the technical owner; pending/cancel never verify or complete',
    () async {
      final result = store.purchase(CommercialCatalog.premiere.id);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(billing.sent!.applicationUserName, sync.identity!.owner);
      billing.events.add([purchase(PurchaseStatus.pending)]);
      expect((await result).status, CommercialPurchaseStatus.pending);
      expect(store.verificationPending, isTrue);
      billing.events.add([purchase(PurchaseStatus.canceled)]);
      await store.retryPending();
      expect(sync.checks, 0);
      expect(billing.completed, 0);
      expect(store.verificationPending, isFalse);
    },
  );
  test(
    'server failure leaves transaction unfinished; retry verifies before completion',
    () async {
      sync.fail = true;
      billing.events.add([purchase(PurchaseStatus.purchased)]);
      await store.retryPending();
      expect(billing.completed, 0);
      expect(store.verificationPending, isTrue);
      expect(states, contains(null));
      sync.fail = false;
      await store.retryPending();
      expect(billing.completed, 1);
      expect(store.verificationPending, isFalse);
      expect(sync.proof, 'google-token');
      expect(states.last, CommercialPurchaseStatus.verified);
    },
  );
  test(
    'native restore is verified and emits ownership only after processing',
    () async {
      await store.restore();
      expect(billing.restores, 1);
      expect(sync.checks, 1);
      expect(billing.completed, 1);
      expect(states.last, CommercialPurchaseStatus.verified);
    },
  );
  test(
    'Apple sends transaction ID, never a decoded-only client receipt',
    () async {
      await store.dispose();
      store = NativeCommercialStore(
        sync,
        billing: billing,
        products: {'native.premiere': CommercialCatalog.premiere.id},
        platform: 'apple',
        changed: (_, s) => states.add(s),
      );
      billing.events.add([purchase(PurchaseStatus.purchased)]);
      await store.retryPending();
      expect(sync.proof, '1234567');
      expect(sync.platform, 'apple');
      expect(billing.completed, 1);
    },
  );
}
