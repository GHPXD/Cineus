import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cineus/data/services/commerce_content_service.dart';
import 'package:cineus/data/services/commerce_gateway.dart';
import 'package:cineus/data/services/commerce_synchronizer.dart';
import 'package:cineus/data/repositories/sponsored_event_repository.dart';
import 'package:cineus/data/datasources/journey_schema.dart';
import 'package:cineus/domain/entities/commerce_content.dart';
import 'package:cineus/domain/entities/commerce_snapshot.dart';
import 'support/test_database.dart';

class ContentSync extends Fake implements CommerceSynchronizer {
  @override
  final CommerceGateway gateway;
  @override
  final CommerceIdentity identity = newCommerceIdentity().confirmed;
  ContentSync(this.gateway);
  @override
  Future<CommerceSnapshot?> synchronize({bool reconcile = false}) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> bundled() =>
      jsonDecode(File('assets/commerce/catalog_v1.json').readAsStringSync());
  test(
    'manifest has two complete collections, distinct cycles and bounded compatible IDs',
    () {
      final content = CommerceContent.parse(bundled());
      expect(content.collections, hasLength(2));
      expect(content.collections.every((c) => c.items.length == 6), isTrue);
      expect(content.clubReady(DateTime.utc(2026, 10, 15)), isTrue);
      expect(content.clubReady(DateTime.utc(2026, 11, 1)), isFalse);
      final incompatible = bundled()..['min_catalog'] = 999;
      expect(() => CommerceContent.parse(incompatible), throwsFormatException);
      final changed = bundled();
      changed['collections'][0]['items'][0] = 'invented';
      expect(() => CommerceContent.parse(changed), throwsFormatException);
    },
  );
  test(
    'signed download resumes, activates only when complete and rolls back by new revision',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      final directory = await Directory.systemTemp.createTemp(
        'cineus-content-test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final algorithm = Ed25519(), key = await Ed25519().newKeyPair();
      final public = await key.extractPublicKey();
      final config = CommerceBackendConfiguration(
        endpoint: Uri.parse('https://content.test'),
        environment: 'sandbox',
        publicKey: public.bytes,
      );
      var revision = 1, interrupt = true, resumed = false;
      final sourceRows =
          jsonDecode(File('docs/artwork/collection.json').readAsStringSync())
              as List;
      final data = {
        for (final r in sourceRows)
          r['file_sha256'] as String: File(r['file']).readAsBytesSync(),
      };
      Future<String> envelope({String audience = 'cineus.content.v1'}) async {
        final payload = utf8.encode(
          jsonEncode({
            ...bundled(),
            'revision': revision,
            'issued_at': DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000,
            'environment': 'sandbox',
            'audience': audience,
          }),
        );
        final signature = await algorithm.sign(payload, keyPair: key);
        return jsonEncode({
          'key_id': 'v1',
          'payload': base64Url.encode(payload),
          'signature': base64Url.encode(signature.bytes),
        });
      }

      final client = MockClient.streaming((request, _) async {
        if (request.url.path == '/v1/content') {
          return http.StreamedResponse(
            Stream.value(utf8.encode(await envelope())),
            200,
          );
        }
        final hash = request.url.pathSegments.last,
            bytes = data[request.url.pathSegments.last]!;
        final range = request.headers['Range'];
        if (range != null) {
          final offset = int.parse(range.substring(6, range.length - 1));
          resumed = true;
          return http.StreamedResponse(
            Stream.value(bytes.sublist(offset)),
            206,
            headers: {
              'content-range':
                  'bytes $offset-${bytes.length - 1}/${bytes.length}',
            },
          );
        }
        if (interrupt) {
          interrupt = false;
          return http.StreamedResponse(
            Stream<List<int>>.fromIterable([bytes.sublist(0, 32)]).asyncExpand((
              b,
            ) async* {
              yield b;
              throw const SocketException('network interrupted');
            }),
            200,
          );
        }
        expect(hash, matches(RegExp(r'^[a-f0-9]{64}$')));
        return http.StreamedResponse(Stream.value(bytes), 200);
      });
      addTearDown(client.close);
      final service = CommerceContentService(
        ContentSync(
          CommerceGateway(config, client, CommerceSnapshotVerifier(config)),
        ),
        TestDatabaseProvider(db),
        directory,
      );
      await expectLater(service.update(), throwsA(anything));
      expect(await service.cached(), isNull);
      final active = await service.update();
      expect(active.revision, 1);
      expect(resumed, isTrue);
      expect((await service.cached())!.revision, 1);
      await expectLater(
        service.verify(await envelope(audience: 'wrong')),
        throwsFormatException,
      );
      revision = 2;
      expect((await service.update()).revision, 2);
      revision = 1;
      expect((await service.update()).revision, 2);
      revision = 3;
      expect((await service.update()).revision, 3);
      final pointer = await db.query(
        'content_releases',
        where: 'slot=?',
        whereArgs: ['active'],
      );
      final forged =
          jsonDecode(pointer.single['envelope'] as String)
              as Map<String, dynamic>;
      forged['signature'] = base64Url.encode(List.filled(64, 0));
      await db.update(
        'content_releases',
        {'envelope': jsonEncode(forged)},
        where: 'slot=?',
        whereArgs: ['active'],
      );
      expect((await service.cached())!.revision, 2);
    },
  );
  test(
    'event enrollment excludes old games, ends on time and atomically grants once',
    () async {
      final db = await openTestDatabase();
      addTearDown(db.close);
      var now = DateTime.utc(2026, 10, 15, 12);
      final event = CommerceContent.parse(bundled()).events.single;
      final repo = SponsoredEventRepository(
        TestDatabaseProvider(db),
        () => now,
      );
      await JourneySchema.finish(
        db,
        key: 'old',
        mode: 'clue',
        kind: 'stage',
        at: now.subtract(const Duration(seconds: 1)),
        scoreCents: 1000,
      );
      await repo.join(event);
      expect((await repo.progress(event)).completed, 0);
      for (var i = 0; i < 3; i++) {
        await JourneySchema.finish(
          db,
          key: 'event:$i',
          mode: 'colors',
          kind: 'stage',
          at: now,
          scoreCents: 500,
        );
      }
      now = DateTime.utc(2026, 12, 1);
      expect(await repo.claim(event), isTrue);
      expect(await repo.claim(event), isFalse);
      expect(
        await db.query(
          'collection_ownership',
          where: 'source_id=?',
          whereArgs: ['event:${event.id}'],
        ),
        hasLength(1),
      );
      final later = ContentEvent(
        'late',
        'aurora_event_frame_v1',
        true,
        {'en': 'Demo'},
        event.from,
        event.until,
        3,
      );
      await repo.join(later);
      expect((await repo.progress(later)).joined, isFalse);
    },
  );
}
