import 'package:sqflite/sqflite.dart';
import '../../domain/entities/commerce_snapshot.dart';
import '../datasources/database_provider.dart';
import '../datasources/commerce_schema.dart';
import '../datasources/collection_schema.dart';

class CommerceCacheRepository {
  final DatabaseProvider database;
  final CommerceSnapshotVerifier verifier;
  CommerceCacheRepository(this.database, this.verifier);
  String get scope => verifier.configuration.scope;
  String get prefix => 'commerce:$scope:';
  Future<CommerceSnapshot?> load(CommerceIdentity identity) async {
    final db = await database.database;
    await CommerceSchema.ensure(db);
    final rows = await db.query(
      'commerce_cache',
      where: 'scope=?',
      whereArgs: [scope],
    );
    if (rows.isEmpty) return null;
    return verifier.verify(
      rows.single['envelope'] as String,
      identity,
      cached: true,
    );
  }

  Future<void> discardUntrusted() async {
    final db = await database.database;
    await db.transaction((txn) async {
      await CommerceSchema.ensure(txn);
      await CollectionSchema.ensure(txn);
      await txn.delete(
        'collection_ownership',
        where: 'substr(source_id,1,?)=?',
        whereArgs: [prefix.length, prefix],
      );
      await txn.delete('commerce_cache', where: 'scope=?', whereArgs: [scope]);
    });
  }

  Future<void> apply(CommerceSnapshot snapshot, {bool cached = false}) async {
    snapshot = await verifier.verify(
      snapshot.envelope,
      snapshot.identity,
      cached: cached,
    );
    final db = await database.database;
    await db.transaction((txn) async {
      await CommerceSchema.ensure(txn);
      await CollectionSchema.ensure(txn);
      final old = (await txn.query(
        'commerce_cache',
        where: 'scope=?',
        whereArgs: [scope],
      )).firstOrNull;
      if (old != null &&
          old['owner'] == snapshot.identity.owner &&
          ((old['revision'] as int) > snapshot.revision ||
              (old['issued_at'] as int) > snapshot.issuedAt)) {
        throw StateError('Older commercial snapshot');
      }
      await txn.delete(
        'collection_ownership',
        where: 'substr(source_id,1,?)=?',
        whereArgs: [prefix.length, prefix],
      );
      final current = verifier.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final effectiveNow = current > snapshot.issuedAt
          ? current
          : snapshot.issuedAt;
      for (final grant in snapshot.grants.where(
        (g) => g.activeAt(effectiveNow),
      )) {
        for (final item in grant.items) {
          await txn.insert('collection_ownership', {
            'item_id': item,
            'source_id': '$prefix${grant.source}',
            'granted_at': DateTime.fromMillisecondsSinceEpoch(
              snapshot.issuedAt * 1000,
              isUtc: true,
            ).toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      for (final receipt in snapshot.rewards) {
        await txn.insert('commerce_reward_receipts', {
          'scope': scope,
          'owner': snapshot.identity.owner,
          'receipt': receipt.id,
          'occurred_at': receipt.occurredAt,
          'attempt': receipt.attempt,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        if (receipt.attempt != null) {
          await txn.update(
            'commerce_reward_receipts',
            {'attempt': receipt.attempt},
            where: 'scope=? AND owner=? AND receipt=? AND attempt IS NULL',
            whereArgs: [scope, snapshot.identity.owner, receipt.id],
          );
        }
      }
      await txn.insert('commerce_cache', {
        'scope': scope,
        'owner': snapshot.identity.owner,
        'device': snapshot.identity.device,
        'revision': snapshot.revision,
        'issued_at': snapshot.issuedAt,
        'envelope': snapshot.envelope,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  String rewardKey(CommerceIdentity identity, String receipt) =>
      '$prefix${identity.owner}:$receipt';
  Future<bool> isRewardCredited(
    CommerceIdentity identity,
    String attempt,
  ) async {
    final db = await database.database;
    await CommerceSchema.ensure(db);
    final rows = await db.query(
      'commerce_reward_receipts',
      where: 'scope=? AND owner=? AND attempt=?',
      whereArgs: [scope, identity.owner, attempt],
    );
    for (final row in rows) {
      final credit = await db.query(
        'ticket_rewards',
        columns: ['key'],
        where: 'key=?',
        whereArgs: [rewardKey(identity, row['receipt'] as String)],
        limit: 1,
      );
      if (credit.isNotEmpty) return true;
    }
    return false;
  }

  Future<void> verifyReward(
    DatabaseExecutor db,
    CommerceIdentity identity,
    String receipt,
  ) async {
    final rows = await db.query(
      'commerce_reward_receipts',
      where: 'scope=? AND owner=? AND receipt=?',
      whereArgs: [scope, identity.owner, receipt],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Missing verified commercial reward');
  }
}
