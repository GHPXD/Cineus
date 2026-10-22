import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/commerce_snapshot.dart';

abstract class CommerceIdentityStorage {
  Future<CommerceIdentity?> read();
  Future<void> write(CommerceIdentity identity);
}

class SecureCommerceIdentityStorage implements CommerceIdentityStorage {
  final String scope;
  final FlutterSecureStorage storage;
  SecureCommerceIdentityStorage(
    this.scope, {
    this.storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        migrateWithBackup: true,
        storageNamespace: 'cineus_commerce_secrets',
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  });
  String get _key => 'cineus.commerce.identity:$scope';
  @override
  Future<CommerceIdentity?> read() async {
    final raw = await storage.read(key: _key);
    return raw == null
        ? null
        : CommerceIdentity.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> write(CommerceIdentity identity) =>
      storage.write(key: _key, value: jsonEncode(identity.toJson()));
}

CommerceIdentity newCommerceIdentity() {
  final random = Random.secure();
  String token() => base64Url
      .encode(List.generate(32, (_) => random.nextInt(256)))
      .replaceAll('=', '');
  String uuid() {
    final b = List.generate(16, (_) => random.nextInt(256));
    b[6] = (b[6] & 15) | 64;
    b[8] = (b[8] & 63) | 128;
    final hex = b.map((i) => i.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  return CommerceIdentity(uuid(), uuid(), token(), token());
}

class CommerceNetworkException implements Exception {
  final String code;
  final int? status;
  const CommerceNetworkException(this.code, [this.status]);
  @override
  String toString() => 'CommerceNetworkException($code)';
}

class CommerceGateway {
  final CommerceBackendConfiguration configuration;
  final http.Client client;
  final CommerceSnapshotVerifier verifier;
  CommerceGateway(this.configuration, this.client, this.verifier);
  Future<String> request(
    String method,
    String path, {
    CommerceIdentity? identity,
    Map<String, Object>? body,
  }) async {
    if (!configuration.enabled) {
      throw const CommerceNetworkException('not_configured');
    }
    final request = http.Request(method, configuration.endpoint!.resolve(path));
    if (request.url.origin != configuration.endpoint!.origin ||
        !path.startsWith('/v1/')) {
      throw const CommerceNetworkException('invalid_endpoint');
    }
    request.followRedirects = false;
    request.headers['accept'] = 'application/json';
    if (identity != null) {
      request.headers['authorization'] = 'Bearer ${identity.token}';
    }
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    try {
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 12));
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 12),
      )) {
        if (bytes.length + chunk.length > 262144) {
          throw const CommerceNetworkException('response_too_large');
        }
        bytes.addAll(chunk);
      }
      if (response.statusCode != 200) {
        throw CommerceNetworkException('request_failed', response.statusCode);
      }
      return utf8.decode(bytes);
    } on CommerceNetworkException {
      rethrow;
    } catch (_) {
      throw const CommerceNetworkException('temporarily_unavailable');
    }
  }

  Future<CommerceSnapshot> register(CommerceIdentity identity) async {
    final body = Map<String, Object>.from(identity.toJson())
      ..remove('registered')
      ..remove('recovering');
    return verifier.verify(
      await request('POST', '/v1/identity', body: body),
      identity,
    );
  }

  Future<CommerceSnapshot> recover(CommerceIdentity identity) async {
    final body = Map<String, Object>.from(identity.toJson())
      ..remove('registered')
      ..remove('recovering');
    return verifier.verify(
      await request('POST', '/v1/identity/recover', body: body),
      identity,
    );
  }

  Future<CommerceSnapshot> snapshot(
    CommerceIdentity identity, {
    bool reconcile = false,
  }) async => verifier.verify(
    await request(
      reconcile ? 'POST' : 'GET',
      reconcile ? '/v1/reconcile' : '/v1/snapshot',
      identity: identity,
    ),
    identity,
  );
  Future<CommerceSnapshot> verifyPurchase(
    CommerceIdentity identity,
    String platform,
    String proof,
  ) async => verifier.verify(
    await request(
      'POST',
      '/v1/purchases/verify',
      identity: identity,
      body: {'platform': platform, 'proof': proof},
    ),
    identity,
  );
  Future<Map<String, dynamic>> startReward(CommerceIdentity identity) async =>
      jsonDecode(await request('POST', '/v1/rewards/start', identity: identity))
          as Map<String, dynamic>;
  Future<void> acknowledgeReward(CommerceIdentity identity, String id) async {
    await request(
      'POST',
      '/v1/rewards/ack',
      identity: identity,
      body: {'receipt_id': id},
    );
  }
}
