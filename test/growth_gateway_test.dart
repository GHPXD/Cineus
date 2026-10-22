import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cineus/domain/entities/commerce_snapshot.dart';
import 'package:cineus/data/services/commerce_gateway.dart';
import 'package:cineus/data/services/commerce_synchronizer.dart';
import 'package:cineus/data/services/growth_gateway.dart';
import 'package:cineus/data/services/paid_ticket_wallet.dart';
import 'package:cineus/core/utils/trusted_time.dart';
import 'support/test_database.dart';

const identity = CommerceIdentity(
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
  'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
  registered: true,
);

class _Sync extends Fake implements CommerceSynchronizer {
  final CommerceGateway? api;
  _Sync([this.api]);
  @override
  CommerceIdentity? get identity => const CommerceIdentity(
    '11111111-1111-4111-8111-111111111111',
    '22222222-2222-4222-8222-222222222222',
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
    'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
    registered: true,
  );
  @override
  CommerceGateway get gateway => api!;
}

class _WalletApi extends Fake implements GrowthGateway {
  int balance = 20, commits = 0;
  bool loseReserve = false, loseCommit = false;
  final holds = <String, String>{};
  @override
  final synchronizer = _Sync();
  @override
  Future<Map<String, dynamic>> command(
    String action, [
    Map<String, Object?> data = const {},
  ]) async {
    final operation = data['operation'] as String?;
    if (action == 'wallet_reserve') {
      if (!holds.containsKey(operation)) {
        balance -= data['amount'] as int;
        holds[operation!] = 'reserved';
      }
      if (loseReserve) {
        loseReserve = false;
        throw const CommerceNetworkException('lost');
      }
    }
    if (action == 'wallet_refund') {
      if (holds[operation] == 'reserved') {
        balance++;
        holds[operation!] = 'refunded';
      }
    }
    if (action == 'wallet_commit') {
      if (holds[operation] == 'reserved') {
        holds[operation!] = 'committed';
        commits++;
      }
      if (loseCommit) {
        loseCommit = false;
        throw const CommerceNetworkException('lost');
      }
    }
    return {'balance': balance};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'growth verifier binds signature, purpose, identity, action and fresh nonce',
    () async {
      final key = await Ed25519().newKeyPair();
      final public = await key.extractPublicKey();
      final config = CommerceBackendConfiguration(
        environment: 'sandbox',
        endpoint: Uri.parse('https://test.invalid'),
        publicKey: public.bytes,
      );
      final changes = <String, Object?>{};
      var tamper = false;
      final client = MockClient((request) async {
        expect(request.url.path, '/v1/growth');
        expect(request.headers['authorization'], 'Bearer ${identity.token}');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final value = {
          'version': 1,
          'audience': 'cineus.growth.v1',
          'environment': 'sandbox',
          'owner': identity.owner,
          'device': identity.device,
          'nonce': body['nonce'],
          'action': body['action'],
          'issued_at': 1792425600,
          'data': {'balance': 20},
          ...changes,
        };
        final bytes = utf8.encode(jsonEncode(value));
        final signature = await Ed25519().sign(bytes, keyPair: key);
        if (tamper) bytes[0] = 0;
        return http.Response(
          jsonEncode({
            'key_id': 'v1',
            'payload': base64Url.encode(bytes),
            'signature': base64Url.encode(signature.bytes),
          }),
          200,
        );
      });
      addTearDown(client.close);
      final api = GrowthGateway(
        _Sync(
          CommerceGateway(config, client, CommerceSnapshotVerifier(config)),
        ),
      );
      expect((await api.command('wallet'))['balance'], 20);
      for (final entry in {
        'owner': 'different',
        'device': 'other',
        'nonce': 'old',
        'audience': 'cineus.commerce.v1',
        'action': 'wallet_commit',
      }.entries) {
        changes
          ..clear()
          ..[entry.key] = entry.value;
        await expectLater(api.command('wallet'), throwsFormatException);
      }
      changes.clear();
      tamper = true;
      await expectLater(api.command('wallet'), throwsFormatException);
    },
  );
  test(
    'lost reserve response refunds the same persisted operation on retry',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final api = _WalletApi()..loseReserve = true;
      final wallet = PaidTicketWallet(TestDatabaseProvider(db), api);
      await expectLater(
        wallet.reserve(1),
        throwsA(isA<CommerceNetworkException>()),
      );
      expect(api.balance, 19);
      expect(await wallet.refresh(), 20);
      expect(api.holds, hasLength(1));
      expect(
        await PaidTicketWallet(TestDatabaseProvider(db), api).refresh(),
        20,
      );
    },
  );
  test(
    'lost commit response survives restart without a second debit or refund',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final api = _WalletApi();
      final wallet = PaidTicketWallet(TestDatabaseProvider(db), api);
      final operation = await wallet.reserve(1);
      api.loseCommit = true;
      await wallet.commit(operation);
      expect(
        (await db.query('paid_ticket_operations')).single['state'],
        'commit',
      );
      expect(
        await PaidTicketWallet(TestDatabaseProvider(db), api).refresh(),
        19,
      );
      expect(api.commits, 1);
      expect(
        (await db.query('paid_ticket_operations')).single['state'],
        'settled',
      );
    },
  );
  test('trusted time advances monotonically from the signed anchor', () async {
    final clock = TrustedTime();
    expect(clock.fresh, isFalse);
    clock.accept(1792425600);
    final before = clock.now();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(clock.fresh, isTrue);
    expect(clock.now().isBefore(before), isFalse);
    expect(
      clock
          .now()
          .difference(
            DateTime.fromMillisecondsSinceEpoch(1792425600000, isUtc: true),
          )
          .inSeconds,
      lessThan(1),
    );
  });
}
