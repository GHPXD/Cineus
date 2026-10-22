import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'commercial_product.dart';
import 'player_collection.dart';

class CommerceIdentity {
  final String owner, device, token, recovery;
  final bool registered, recovering;
  const CommerceIdentity(
    this.owner,
    this.device,
    this.token,
    this.recovery, {
    this.registered = false,
    this.recovering = false,
  });
  Map<String, Object> toJson() => {
    'owner': owner,
    'device': device,
    'token': token,
    'recovery': recovery,
    'registered': registered,
    'recovering': recovering,
  };
  factory CommerceIdentity.fromJson(Map<String, dynamic> j) {
    final uuid = RegExp(r'^[a-f0-9]{8}-(?:[a-f0-9]{4}-){3}[a-f0-9]{12}$');
    final token = RegExp(r'^[A-Za-z0-9_-]{43}$');
    if (j['owner'] is! String ||
        !uuid.hasMatch(j['owner']) ||
        j['device'] is! String ||
        !uuid.hasMatch(j['device']) ||
        j['token'] is! String ||
        !token.hasMatch(j['token']) ||
        j['recovery'] is! String ||
        !token.hasMatch(j['recovery']) ||
        j['registered'] is! bool ||
        (j['recovering'] != null && j['recovering'] is! bool)) {
      throw const FormatException('Invalid commercial identity');
    }
    return CommerceIdentity(
      j['owner'],
      j['device'],
      j['token'],
      j['recovery'],
      registered: j['registered'],
      recovering: j['recovering'] as bool? ?? false,
    );
  }
  CommerceIdentity get confirmed =>
      CommerceIdentity(owner, device, token, recovery, registered: true);
}

class CommerceBackendConfiguration {
  final Uri? endpoint;
  final String environment, keyId;
  final List<int> publicKey;
  const CommerceBackendConfiguration({
    this.endpoint,
    required this.environment,
    this.keyId = 'v1',
    this.publicKey = const [],
  });
  factory CommerceBackendConfiguration.fromBuild(String environment) {
    try {
      return CommerceBackendConfiguration(
        environment: environment,
        endpoint: Uri.tryParse(
          const String.fromEnvironment('CINEUS_COMMERCE_URL'),
        ),
        keyId: const String.fromEnvironment(
          'CINEUS_COMMERCE_KEY_ID',
          defaultValue: 'v1',
        ),
        publicKey: base64Decode(
          const String.fromEnvironment('CINEUS_COMMERCE_PUBLIC_KEY'),
        ),
      );
    } catch (_) {
      return CommerceBackendConfiguration(environment: environment);
    }
  }
  bool get enabled =>
      endpoint != null &&
      endpoint!.scheme == 'https' &&
      endpoint!.host.isNotEmpty &&
      endpoint!.userInfo.isEmpty &&
      !endpoint!.hasQuery &&
      !endpoint!.hasFragment &&
      (endpoint!.path.isEmpty || endpoint!.path == '/') &&
      publicKey.length == 32 &&
      {'development', 'sandbox', 'production'}.contains(environment) &&
      keyId.isNotEmpty;
  String get scope => '$environment:${endpoint?.origin ?? ''}';
}

class CommerceGrant {
  final String source, product;
  final int validFrom;
  final int? validUntil;
  final bool revoked;
  final Set<String> items;
  CommerceGrant(
    this.source,
    this.product,
    this.validFrom,
    this.validUntil,
    this.revoked,
    Set<String> items,
  ) : items = Set.unmodifiable(items);
  bool activeAt(int now) =>
      !revoked && validFrom <= now && (validUntil == null || validUntil! > now);
}

class CommerceRewardReceipt {
  final String id;
  final int occurredAt;
  final String? attempt;
  const CommerceRewardReceipt(this.id, this.occurredAt, [this.attempt]);
}

class CommerceSnapshot {
  final CommerceIdentity identity;
  final int revision, issuedAt, rewardedUsedToday;
  final List<CommerceGrant> grants;
  final List<CommerceRewardReceipt> rewards;
  final String envelope;
  CommerceSnapshot._(
    this.identity,
    this.revision,
    this.issuedAt,
    List<CommerceGrant> grants,
    List<CommerceRewardReceipt> rewards,
    this.envelope,
    this.rewardedUsedToday,
  ) : grants = List.unmodifiable(grants),
      rewards = List.unmodifiable(rewards);
}

class CommerceSnapshotVerifier {
  final CommerceBackendConfiguration configuration;
  final DateTime Function() now;
  CommerceSnapshotVerifier(this.configuration, {DateTime Function()? now})
    : now = now ?? DateTime.now;
  Future<CommerceSnapshot> verify(
    String raw,
    CommerceIdentity identity, {
    bool cached = false,
  }) async {
    try {
      return await _verify(raw, identity, cached: cached);
    } catch (_) {
      throw const FormatException('Invalid or untrusted commercial snapshot');
    }
  }

  Future<CommerceSnapshot> _verify(
    String raw,
    CommerceIdentity identity, {
    bool cached = false,
  }) async {
    if (!configuration.enabled || raw.length > 262144) {
      throw const FormatException('Invalid snapshot');
    }
    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    if (envelope['key_id'] != configuration.keyId ||
        envelope.keys.toSet().difference({
          'key_id',
          'payload',
          'signature',
        }).isNotEmpty) {
      throw const FormatException('Untrusted signing key');
    }
    final payload = base64Url.decode(
      base64Url.normalize(envelope['payload'] as String),
    );
    final signature = base64Url.decode(
      base64Url.normalize(envelope['signature'] as String),
    );
    final valid = await Ed25519().verify(
      payload,
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(
          configuration.publicKey,
          type: KeyPairType.ed25519,
        ),
      ),
    );
    if (!valid) throw const FormatException('Invalid snapshot signature');
    final j = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    int integer(dynamic value) {
      if (value is! int || value < 0 || value > 9007199254740991) {
        throw const FormatException('Invalid integer');
      }
      return value;
    }

    final issued = integer(j['issued_at']), revision = integer(j['revision']);
    final current = now().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (j['version'] is! int ||
        j['version'] != 1 ||
        j['environment'] != configuration.environment ||
        j['audience'] != 'cineus.commerce.v1' ||
        j['owner'] != identity.owner ||
        j['device'] != identity.device ||
        issued > current + 300 ||
        (!cached && issued < current - 600)) {
      throw const FormatException('Snapshot scope/freshness mismatch');
    }
    final grants = <CommerceGrant>[], sources = <String>{};
    for (final value in j['grants'] as List) {
      final g = value as Map<String, dynamic>;
      final product = CommercialCatalog.byId(g['product'] as String);
      if (product == null ||
          g['source'] is! String ||
          !RegExp(r'^(google|apple):[a-f0-9]{64}$').hasMatch(g['source']) ||
          !sources.add(g['source']) ||
          g['revoked'] is! bool) {
        throw const FormatException('Invalid grant');
      }
      final items = (g['items'] as List).cast<String>();
      final expected = product.collectionId == null
          ? <String>{}
          : PlayerCollectionCatalog.items
                .where((i) => i.collectionId == product.collectionId)
                .map((i) => i.id)
                .toSet();
      if (items.length != items.toSet().length ||
          items.toSet().difference(expected).isNotEmpty ||
          expected.difference(items.toSet()).isNotEmpty) {
        throw const FormatException('Unexpected collection contents');
      }
      final start = integer(g['valid_from']);
      final end = g['valid_until'] == null ? null : integer(g['valid_until']);
      if (start > 253402300799 ||
          (end != null && end > 253402300799) ||
          (end != null && end < start) ||
          (product.kind == CommercialProductKind.subscription && end == null)) {
        throw const FormatException('Invalid grant validity');
      }
      grants.add(
        CommerceGrant(
          g['source'],
          product.id,
          start,
          end,
          g['revoked'],
          items.toSet(),
        ),
      );
    }
    final rewards = <CommerceRewardReceipt>[], ids = <String>{};
    for (final value in j['rewards'] as List) {
      final r = value as Map<String, dynamic>;
      if (r['id'] is! String ||
          !RegExp(r'^admob:[a-f0-9]{64}$').hasMatch(r['id']) ||
          r['amount'] is! int ||
          r['amount'] != 2 ||
          !ids.add(r['id'])) {
        throw const FormatException('Invalid reward receipt');
      }
      final stamp = integer(r['occurred_at']);
      if (stamp > issued + 300) {
        throw const FormatException('Invalid reward timestamp');
      }
      final attempt = r['attempt'];
      if (attempt != null &&
          (attempt is! String ||
              !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(attempt))) {
        throw const FormatException('Invalid reward attempt');
      }
      rewards.add(CommerceRewardReceipt(r['id'], stamp, attempt as String?));
    }
    final used = integer(j['rewarded_used_today'] ?? 0);
    if (used > 3) throw const FormatException('Invalid reward quota');
    return CommerceSnapshot._(
      identity,
      revision,
      issued,
      grants,
      rewards,
      raw,
      used,
    );
  }
}
