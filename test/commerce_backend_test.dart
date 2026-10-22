import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cineus/domain/entities/commerce_snapshot.dart';
import 'package:cineus/domain/entities/player_collection.dart';
import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/repositories/commerce_cache_repository.dart';
import 'package:cineus/data/repositories/player_collection_repository.dart';
import 'package:cineus/data/services/commerce_gateway.dart';
import 'package:cineus/data/services/commerce_synchronizer.dart';
import 'package:cineus/presentation/providers/commercial_provider.dart';
import 'package:cineus/presentation/providers/providers.dart';
import 'package:cineus/presentation/providers/app_clock.dart';
import 'support/test_database.dart';

final fixedNow = DateTime.fromMillisecondsSinceEpoch(
  1791979200000,
  isUtc: true,
);
late Map<String, dynamic> fixture;
late CommerceIdentity identity;
late CommerceBackendConfiguration config;
late CommerceSnapshotVerifier verifier;
late SimpleKeyPair key;

Future<String> signed({
  int revision = 1,
  int? issuedAt,
  List<dynamic>? grants,
  List<dynamic>? rewards,
  Map<String, dynamic> changes = const {},
}) async {
  final payload = <String, dynamic>{
    ...fixture['payload'] as Map<String, dynamic>,
    'revision': revision,
    'issued_at': issuedAt ?? 1791979200,
    if (grants != null) 'grants': grants,
    if (rewards != null) 'rewards': rewards,
    ...changes,
  };
  final bytes = utf8.encode(jsonEncode(payload));
  final signature = await Ed25519().sign(bytes, keyPair: key);
  return jsonEncode({
    'key_id': 'v1',
    'payload': base64Url.encode(bytes).replaceAll('=', ''),
    'signature': base64Url.encode(signature.bytes).replaceAll('=', ''),
  });
}

class MemoryIdentityStorage implements CommerceIdentityStorage {
  CommerceIdentity? value;
  bool failWrites = false;
  MemoryIdentityStorage(this.value);
  @override
  Future<CommerceIdentity?> read() async => value;
  @override
  Future<void> write(CommerceIdentity identity) async {
    if (failWrites) throw StateError('Secure storage unavailable');
    value = identity;
  }
}

void main() {
  setUpAll(() async {
    fixture =
        jsonDecode(
              File(
                'test/fixtures/commerce_snapshot_v1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    identity = CommerceIdentity.fromJson(
      fixture['identity'] as Map<String, dynamic>,
    );
    config = CommerceBackendConfiguration(
      environment: 'sandbox',
      endpoint: Uri.parse('https://commerce.test'),
      publicKey: base64Decode(fixture['public_key'] as String),
    );
    verifier = CommerceSnapshotVerifier(config, now: () => fixedNow);
    key = await Ed25519().newKeyPairFromSeed(List.generate(32, (i) => i));
  });
  test(
    'Python-signed fixture verifies in Dart with account, device and six assets',
    () async {
      final snapshot = await verifier.verify(
        jsonEncode(fixture['envelope']),
        identity,
      );
      expect(snapshot.grants.single.items, hasLength(6));
      expect(snapshot.rewards.single.id, startsWith('admob:'));
      expect(snapshot.identity.token, identity.token);
    },
  );
  test(
    'tampered payload, wrong key and unsigned boolean cannot grant rights',
    () async {
      final envelope = Map<String, dynamic>.from(fixture['envelope'] as Map);
      envelope['payload'] = base64Url.encode(utf8.encode('{"verified":true}'));
      await expectLater(
        verifier.verify(jsonEncode(envelope), identity),
        throwsA(anything),
      );
      await expectLater(
        verifier.verify('{"verified":true}', identity),
        throwsA(anything),
      );
      envelope['key_id'] = 'attacker';
      await expectLater(
        verifier.verify(jsonEncode(envelope), identity),
        throwsA(anything),
      );
    },
  );
  for (final change in [
    {'environment': 'production'},
    {'audience': 'other.app'},
    {'owner': 'different-owner'},
    {'device': 'different-device'},
    {'issued_at': 1791979600},
    {'issued_at': 1791970000},
  ]) {
    test(
      'signed snapshot still rejects scope/freshness mismatch $change',
      () async {
        await expectLater(
          verifier.verify(await signed(changes: change), identity),
          throwsFormatException,
        );
      },
    );
  }
  test(
    'unknown products, incorrect item bundle and reward amount are rejected',
    () async {
      final grant = Map<String, dynamic>.from(
        (fixture['payload']['grants'] as List).single as Map,
      );
      await expectLater(
        verifier.verify(
          await signed(
            grants: [
              {
                ...grant,
                'items': ['avatar_owl_v1'],
              },
            ],
          ),
          identity,
        ),
        throwsFormatException,
      );
      await expectLater(
        verifier.verify(
          await signed(
            grants: [
              {...grant, 'product': 'attacker-product'},
            ],
          ),
          identity,
        ),
        throwsA(anything),
      );
      await expectLater(
        verifier.verify(
          await signed(
            rewards: [
              {
                'id': 'admob:${'1' * 64}',
                'amount': 200,
                'occurred_at': 1791979100,
              },
            ],
          ),
          identity,
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'two origins survive independent revocation, cache replay and equipment fallback',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final repository = PlayerCollectionRepository(TestDatabaseProvider(db));
      final cache = CommerceCacheRepository(TestDatabaseProvider(db), verifier);
      await repository.saveIdentity('Marina', false);
      final grant = Map<String, dynamic>.from(
        (fixture['payload']['grants'] as List).single as Map,
      );
      final second = {...grant, 'source': 'apple:${'2' * 64}'};
      await cache.apply(
        await verifier.verify(await signed(grants: [grant, second]), identity),
      );
      await repository.equip('premiere_frame_deco_v1');
      await cache.apply(
        await verifier.verify(
          await signed(
            revision: 2,
            grants: [
              {...grant, 'revoked': true},
              second,
            ],
          ),
          identity,
        ),
      );
      expect((await repository.load()).owned, hasLength(11));
      await expectLater(
        cache.apply(await verifier.verify(await signed(revision: 1), identity)),
        throwsStateError,
      );
      await cache.apply(
        await verifier.verify(
          await signed(
            revision: 3,
            grants: [
              {...grant, 'revoked': true},
              {...second, 'revoked': true},
            ],
          ),
          identity,
        ),
      );
      final restored = await repository.load();
      expect(restored.owned, hasLength(5));
      expect(restored.equipped[CollectionItemKind.frame], 'frame_premiere_v1');
      expect(restored.displayName, 'Marina');
      expect(restored.showIdentity, isFalse);
    },
  );
  test(
    'database failure rolls back inventory, cache and receipt journal together',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final repository = PlayerCollectionRepository(TestDatabaseProvider(db));
      final cache = CommerceCacheRepository(TestDatabaseProvider(db), verifier);
      await repository.load();
      await cache.load(identity);
      await db.execute(
        "CREATE TRIGGER fail_cache BEFORE INSERT ON commerce_cache BEGIN SELECT RAISE(ABORT,'disk failure'); END",
      );
      await expectLater(
        cache.apply(await verifier.verify(await signed(), identity)),
        throwsA(anything),
      );
      expect((await repository.load()).owned, hasLength(5));
      expect(await db.query('commerce_reward_receipts'), isEmpty);
      expect(await cache.load(identity), isNull);
    },
  );
  test(
    'network failure preserves authenticated cached grants and never fabricates offers',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final cache = CommerceCacheRepository(TestDatabaseProvider(db), verifier);
      await cache.apply(
        await verifier.verify(await signed(rewards: []), identity),
      );
      final client = MockClient(
        (request) async => http.Response('{"error":"down"}', 503),
      );
      addTearDown(client.close);
      final sync = CommerceSynchronizer(
        gateway: CommerceGateway(config, client, verifier),
        identityStorage: MemoryIdentityStorage(identity),
        cache: cache,
        credit: (_, __) async {},
        onChanged: () async {},
      );
      await expectLater(
        sync.synchronize(),
        throwsA(isA<CommerceNetworkException>()),
      );
      expect(sync.current!.grants.single.items, hasLength(6));
      expect(
        (await PlayerCollectionRepository(
          TestDatabaseProvider(db),
        ).load()).owned,
        hasLength(11),
      );
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(commerceSynchronizerProvider), isNull);
      expect(await c.read(commercialOffersProvider.future), isEmpty);
    },
  );
  test(
    'secure identity is persisted before registration and storage failure prevents network',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final storage = MemoryIdentityStorage(null)..failWrites = true;
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      });
      addTearDown(client.close);
      final sync = CommerceSynchronizer(
        gateway: CommerceGateway(config, client, verifier),
        identityStorage: storage,
        cache: CommerceCacheRepository(TestDatabaseProvider(db), verifier),
        credit: (_, __) async {},
        onChanged: () async {},
      );
      await expectLater(sync.synchronize(), throwsStateError);
      expect(requests, 0);
      final generated = newCommerceIdentity();
      expect(
        CommerceIdentity.fromJson(generated.toJson()).owner,
        generated.owner,
      );
    },
  );
  test(
    'HTTP redirects, foreign paths and oversized bodies cannot exfiltrate credentials',
    () async {
      final client = MockClient((request) async {
        expect(request.followRedirects, isFalse);
        return http.Response(
          '',
          302,
          headers: {'location': 'https://attacker.test'},
        );
      });
      addTearDown(client.close);
      final gateway = CommerceGateway(config, client, verifier);
      await expectLater(
        gateway.snapshot(identity),
        throwsA(isA<CommerceNetworkException>()),
      );
      await expectLater(
        gateway.request(
          'GET',
          'https://attacker.test/v1/x',
          identity: identity,
        ),
        throwsA(isA<CommerceNetworkException>()),
      );
      final huge = MockClient((_) async => http.Response('x' * 262145, 200));
      addTearDown(huge.close);
      await expectLater(
        CommerceGateway(config, huge, verifier).snapshot(identity),
        throwsA(isA<CommerceNetworkException>()),
      );
    },
  );
  test(
    'credit committed before lost acknowledgement survives process/database reopen exactly once',
    () async {
      sqfliteFfiInit();
      final path =
          '${Directory.current.path}/.dart_tool/commerce-${DateTime.now().microsecondsSinceEpoch}.db';
      var db = await databaseFactoryFfi.openDatabase(path);
      var serverAck = false;
      final storage = MemoryIdentityStorage(identity);
      final client = MockClient((request) async {
        if (request.url.path == '/v1/rewards/ack') {
          serverAck = true;
          return http.Response('{}', 503);
        }
        return http.Response(await signed(rewards: serverAck ? [] : null), 200);
      });
      ProviderContainer container() => ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(TestDatabaseProvider(db)),
          appClockProvider.overrideWithValue(() => fixedNow),
        ],
      );
      var c = container();
      CommerceSynchronizer synchronizer() {
        final cache = CommerceCacheRepository(
          TestDatabaseProvider(db),
          verifier,
        );
        return CommerceSynchronizer(
          gateway: CommerceGateway(config, client, verifier),
          identityStorage: storage,
          cache: cache,
          credit: (id, receipt) async {
            await c
                .read(ticketNotifierProvider.notifier)
                .creditOnce(
                  key: cache.rewardKey(id, receipt.id),
                  amount: 2,
                  verify: (tx) => cache.verifyReward(tx, id, receipt.id),
                );
          },
          onChanged: () async {},
        );
      }

      try {
        await const DatabaseSeeder().ensureCanonicalSchema(db);
        await c.read(ticketNotifierProvider.notifier).ready;
        await expectLater(
          synchronizer().synchronize(),
          throwsA(isA<CommerceNetworkException>()),
        );
        expect(c.read(ticketNotifierProvider).extraTickets, 2);
        c.dispose();
        await db.close();
        db = await databaseFactoryFfi.openDatabase(path);
        c = container();
        await c.read(ticketNotifierProvider.notifier).ready;
        await synchronizer().synchronize();
        expect(c.read(ticketNotifierProvider).extraTickets, 2);
        expect(await db.query('ticket_rewards'), hasLength(1));
        expect(
          (await db.query(
            'ticket_movements',
            where: 'reason=?',
            whereArgs: ['verifiedReward'],
          )),
          hasLength(1),
        );
      } finally {
        c.dispose();
        await db.close();
        client.close();
        await databaseFactoryFfi.deleteDatabase(path);
      }
    },
  );

  test(
    'corrupt signed cache is removed without deleting free items and a valid refresh can recover',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final cache = CommerceCacheRepository(TestDatabaseProvider(db), verifier);
      await cache.apply(
        await verifier.verify(await signed(rewards: []), identity),
      );
      await db.update('commerce_cache', {'envelope': '{"signature":"forged"}'});
      var online = false;
      final client = MockClient(
        (_) async => online
            ? http.Response(await signed(revision: 2, rewards: []), 200)
            : http.Response('{}', 503),
      );
      addTearDown(client.close);
      final repo = PlayerCollectionRepository(TestDatabaseProvider(db));
      final sync = CommerceSynchronizer(
        gateway: CommerceGateway(config, client, verifier),
        identityStorage: MemoryIdentityStorage(identity),
        cache: cache,
        credit: (_, __) async {},
        onChanged: () async {},
      );
      await expectLater(
        sync.synchronize(),
        throwsA(isA<CommerceNetworkException>()),
      );
      expect((await repo.load()).owned, hasLength(5));
      online = true;
      await sync.synchronize();
      expect((await repo.load()).owned, hasLength(11));
    },
  );
  test(
    'lost registration response retries the identity written before the HTTP request',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final storage = MemoryIdentityStorage(null);
      Map<String, dynamic>? registered;
      var fail = true;
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/identity');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(storage.value!.owner, body['owner']);
        if (registered == null) {
          registered = body;
        } else {
          expect(body, registered);
        }
        if (fail) return http.Response('{}', 503);
        return http.Response(
          await signed(
            rewards: [],
            changes: {'owner': body['owner'], 'device': body['device']},
          ),
          200,
        );
      });
      addTearDown(client.close);
      final sync = CommerceSynchronizer(
        gateway: CommerceGateway(config, client, verifier),
        identityStorage: storage,
        cache: CommerceCacheRepository(TestDatabaseProvider(db), verifier),
        credit: (_, __) async {},
        onChanged: () async {},
      );
      await expectLater(
        sync.synchronize(),
        throwsA(isA<CommerceNetworkException>()),
      );
      expect(storage.value!.registered, isFalse);
      fail = false;
      await sync.synchronize();
      expect(storage.value!.registered, isTrue);
    },
  );
  test(
    'foreground sync calls share one request instead of racing snapshots',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      var calls = 0;
      final gate = Completer<void>();
      final client = MockClient((_) async {
        calls++;
        await gate.future;
        return http.Response(await signed(rewards: []), 200);
      });
      addTearDown(client.close);
      final sync = CommerceSynchronizer(
        gateway: CommerceGateway(config, client, verifier),
        identityStorage: MemoryIdentityStorage(identity),
        cache: CommerceCacheRepository(TestDatabaseProvider(db), verifier),
        credit: (_, __) async {},
        onChanged: () async {},
      );
      final one = sync.synchronize(), two = sync.synchronize();
      expect(identical(one, two), isTrue);
      gate.complete();
      await Future.wait([one, two]);
      expect(calls, 1);
    },
  );
  test(
    'expired session recovery survives a lost response while preserving the signed cache',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final cache = CommerceCacheRepository(TestDatabaseProvider(db), verifier);
      await cache.apply(
        await verifier.verify(await signed(rewards: []), identity),
      );
      final storage = MemoryIdentityStorage(identity);
      var failRecovery = true;
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        if (request.url.path == '/v1/snapshot') return http.Response('{}', 401);
        expect(request.url.path, '/v1/identity/recover');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['device'], identity.device);
        expect(body['owner'], identity.owner);
        expect(body['token'], isNot(identity.token));
        expect(storage.value!.recovering, isTrue);
        if (failRecovery) return http.Response('{}', 503);
        return http.Response(await signed(revision: 2, rewards: []), 200);
      });
      addTearDown(client.close);
      final sync = CommerceSynchronizer(
        gateway: CommerceGateway(config, client, verifier),
        identityStorage: storage,
        cache: cache,
        credit: (_, __) async {},
        onChanged: () async {},
      );
      await expectLater(
        sync.synchronize(),
        throwsA(isA<CommerceNetworkException>()),
      );
      expect(sync.current, isNotNull);
      expect((await cache.load(storage.value!))!.grants, hasLength(1));
      failRecovery = false;
      await sync.synchronize();
      expect(storage.value!.registered, isTrue);
      expect(storage.value!.recovering, isFalse);
      expect(calls, 3);
    },
  );
}
