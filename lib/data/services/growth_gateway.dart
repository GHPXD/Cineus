import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'commerce_synchronizer.dart';

/// Signed, nonce-bound responses also bootstrap time when the device clock is wrong.
class GrowthGateway {
  final CommerceSynchronizer synchronizer;
  GrowthGateway(this.synchronizer);
  Future<Map<String, dynamic>> command(
    String action, [
    Map<String, Object?> data = const {},
  ]) async {
    if (synchronizer.identity == null || !synchronizer.identity!.registered) {
      try {
        await synchronizer.synchronize();
      } on FormatException {
        // The registration may already have committed. Authenticate time using
        // the fresh nonce below before retrying the time-sensitive snapshot.
      }
    }
    final identity = synchronizer.identity;
    if (identity == null) throw StateError('Identity unavailable');
    final random = Random.secure();
    final nonce = base64Url
        .encode(List.generate(32, (_) => random.nextInt(256)))
        .replaceAll('=', '');
    final raw = await synchronizer.gateway.request(
      'POST',
      '/v1/growth',
      identity: identity,
      body: {'action': action, 'nonce': nonce, 'payload': data},
    );
    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    final config = synchronizer.gateway.configuration;
    if (envelope['key_id'] != config.keyId || envelope.length != 3) {
      throw const FormatException('Untrusted growth key');
    }
    final payload = base64Url.decode(
      base64Url.normalize(envelope['payload'] as String),
    );
    final signature = base64Url.decode(
      base64Url.normalize(envelope['signature'] as String),
    );
    if (!await Ed25519().verify(
      payload,
      signature: Signature(
        signature,
        publicKey: SimplePublicKey(config.publicKey, type: KeyPairType.ed25519),
      ),
    )) {
      throw const FormatException('Untrusted growth response');
    }
    final j = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    if (j['version'] != 1 ||
        j['audience'] != 'cineus.growth.v1' ||
        j['environment'] != config.environment ||
        j['owner'] != identity.owner ||
        j['device'] != identity.device ||
        j['nonce'] != nonce ||
        j['action'] != action ||
        j['issued_at'] is! int ||
        (j['issued_at'] as int) < 0 ||
        (j['issued_at'] as int) > 253402300799 ||
        j['data'] is! Map<String, dynamic>) {
      throw const FormatException('Growth scope mismatch');
    }
    return {
      ...j['data'] as Map<String, dynamic>,
      '_server_time': j['issued_at'],
    };
  }
}
