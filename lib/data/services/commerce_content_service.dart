import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/commerce_content.dart';
import '../../domain/entities/player_collection.dart';
import '../datasources/database_provider.dart';
import 'commerce_synchronizer.dart';

/// A release becomes active only after every asset passes its signed hash.
/// Partial transfers survive restarts; activation/rollback uses a DB transaction.
class CommerceContentService {
  final CommerceSynchronizer sync;
  final DatabaseProvider database;
  final Directory directory;
  CommerceContentService(this.sync, this.database, this.directory);
  Future<CommerceContent>? _pending;
  Future<String> _hash(List<int> bytes) async => (await Sha256().hash(
    bytes,
  )).bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  Future<void> _ensure() async {
    await directory.create(recursive: true);
    final db = await database.database;
    await db.execute(
      'CREATE TABLE IF NOT EXISTS content_releases(slot TEXT PRIMARY KEY,envelope TEXT NOT NULL)',
    );
  }

  Future<CommerceContent> verify(String raw, {bool cached = false}) async {
    if (raw.length > 262144) throw const FormatException('Oversized content');
    final e = jsonDecode(raw) as Map<String, dynamic>,
        config = sync.gateway.configuration;
    final payload = base64Url.decode(base64Url.normalize(e['payload']));
    if (e['key_id'] != config.keyId ||
        !await Ed25519().verify(
          payload,
          signature: Signature(
            base64Url.decode(base64Url.normalize(e['signature'])),
            publicKey: SimplePublicKey(
              config.publicKey,
              type: KeyPairType.ed25519,
            ),
          ),
        )) {
      throw const FormatException('Untrusted content');
    }
    final j = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (j['audience'] != 'cineus.content.v1' ||
        j['environment'] != config.environment ||
        j['issued_at'] is! int ||
        j['issued_at'] > now + 300 ||
        (!cached && j['issued_at'] < now - 600)) {
      throw const FormatException('Wrong content scope');
    }
    return CommerceContent.parse(j);
  }

  File _file(String hash, {bool partial = false}) =>
      File('${directory.path}/$hash${partial ? '.part' : ''}');
  Future<bool> _valid(ContentAsset asset) async {
    final file = _file(asset.sha256);
    return await file.exists() &&
        await file.length() == asset.bytes &&
        await _hash(await file.readAsBytes()) == asset.sha256;
  }

  Future<CommerceContent?> cached() async {
    await _ensure();
    final db = await database.database;
    for (final slot in ['active', 'previous']) {
      final rows = await db.query(
        'content_releases',
        where: 'slot=?',
        whereArgs: [slot],
      );
      if (rows.isEmpty) continue;
      try {
        final content = await verify(
          rows.single['envelope'] as String,
          cached: true,
        );
        var valid = true;
        for (final a in content.assets) {
          if (!await _valid(a)) {
            valid = false;
            break;
          }
        }
        if (valid) return content;
      } catch (_) {
        /* Fall back to the previous complete release. */
      }
    }
    return null;
  }

  Future<CommerceContent> update() =>
      _pending ??= _update().whenComplete(() => _pending = null);
  Future<CommerceContent> _update() async {
    await _ensure();
    await sync.synchronize();
    final raw = await sync.gateway.request(
      'GET',
      '/v1/content',
      identity: sync.identity,
    );
    final content = await verify(raw), old = await cached();
    // Rollback is published with a NEW revision referring to earlier assets.
    if (old != null && content.revision <= old.revision) return old;
    await _prune(content);
    for (final asset in content.assets) {
      if (!await _valid(asset)) await _download(asset);
    }
    final db = await database.database;
    await db.transaction((txn) async {
      final old = await txn.query(
        'content_releases',
        where: 'slot=?',
        whereArgs: ['active'],
      );
      if (old.isNotEmpty) {
        await txn.rawInsert(
          'INSERT OR REPLACE INTO content_releases VALUES(?,?)',
          ['previous', old.single['envelope']],
        );
      }
      await txn.rawInsert(
        'INSERT OR REPLACE INTO content_releases VALUES(?,?)',
        ['active', raw],
      );
    });
    return content;
  }

  Future<void> _prune(CommerceContent next) async {
    final keep = next.assets.map((a) => a.sha256).toSet(),
        db = await database.database;
    for (final row in await db.query('content_releases')) {
      try {
        keep.addAll(
          (await verify(
            row['envelope'] as String,
            cached: true,
          )).assets.map((a) => a.sha256),
        );
      } catch (_) {}
    }
    await for (final entity in directory.list(followLinks: false)) {
      final name = entity.uri.pathSegments.last;
      if (entity is File &&
          RegExp(r'^[a-f0-9]{64}(\.part)?$').hasMatch(name) &&
          !keep.contains(name.split('.').first)) {
        await entity.delete();
      }
    }
  }

  Future<void> _download(ContentAsset asset) async {
    final file = _file(asset.sha256, partial: true);
    var offset = await file.exists() ? await file.length() : 0;
    if (offset >= asset.bytes) {
      await file.delete();
      offset = 0;
    }
    {
      final url = sync.gateway.configuration.endpoint!.resolve(
        '/v1/content/assets/${asset.sha256}',
      );
      final req = http.Request('GET', url);
      req.followRedirects = false;
      req.headers['Authorization'] = 'Bearer ${sync.identity!.token}';
      if (offset > 0) {
        req.headers['Range'] = 'bytes=$offset-';
        req.headers['If-Range'] = '"${asset.sha256}"';
      }
      final response = await sync.gateway.client
          .send(req)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw const HttpException('Content unavailable');
      }
      if (response.statusCode == 206 &&
          (offset == 0 ||
              response.headers['content-range'] !=
                  'bytes $offset-${asset.bytes - 1}/${asset.bytes}')) {
        throw const FormatException('Invalid partial content');
      }
      if (response.statusCode == 200) offset = 0;
      final sink = file.openWrite(
        mode: offset == 0 ? FileMode.write : FileMode.append,
      );
      try {
        await for (final chunk in response.stream.timeout(
          const Duration(seconds: 12),
        )) {
          offset += chunk.length;
          if (offset > asset.bytes) {
            throw const FormatException('Oversized asset');
          }
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      final bytes = await file.readAsBytes();
      if (bytes.length != asset.bytes || await _hash(bytes) != asset.sha256) {
        await file.delete();
        throw const FormatException('Corrupt asset');
      }
      if (asset.format == 'svg') {
        final svg = utf8.decode(bytes);
        if (!svg.contains('<svg') ||
            RegExp(
              r'<(?:script|foreignObject)|(?:href|url)\s*[=(:]\s*["\x27]?https?:',
              caseSensitive: false,
            ).hasMatch(svg)) {
          await file.delete();
          throw const FormatException('Unsupported SVG');
        }
      } else if (bytes.length < 8 ||
          bytes[0] != 137 ||
          bytes[1] != 80 ||
          bytes[2] != 78 ||
          bytes[3] != 71) {
        await file.delete();
        throw const FormatException('Invalid PNG');
      }
      if (asset.format == 'png') {
        if (bytes.length < 24) {
          throw const FormatException('Invalid PNG header');
        }
        final view = ByteData.sublistView(bytes),
            width = view.getUint32(16),
            height = view.getUint32(20);
        final item = PlayerCollectionCatalog.items.firstWhere(
          (i) => i.id == asset.item,
        );
        if (width < 1 ||
            height < 1 ||
            width * height > 4194304 ||
            (item.kind == CollectionItemKind.frame &&
                (width != item.frameWidth.toInt() || height != 800))) {
          await file.delete();
          throw const FormatException('Incompatible image dimensions');
        }
      }
      final target = _file(asset.sha256);
      if (await target.exists()) await target.delete();
      await file.rename(target.path);
    }
  }

  Future<Uint8List?> bytes(ContentAsset asset) async =>
      await _valid(asset) ? _file(asset.sha256).readAsBytes() : null;
}
