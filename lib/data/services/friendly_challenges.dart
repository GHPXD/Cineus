import '../datasources/database_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'growth_gateway.dart';
import 'commerce_gateway.dart';

class FriendlyChallenges {
  final DatabaseProvider database;
  final GrowthGateway gateway;
  FriendlyChallenges(this.database, this.gateway);
  Future<void> attach(int sessionId, String code) async {
    final db = await database.database;
    await db.execute(
      'CREATE TABLE IF NOT EXISTS friendly_pending(session_id INTEGER NOT NULL,code TEXT PRIMARY KEY, sent INTEGER NOT NULL DEFAULT 0)',
    );
    if (!(await db.rawQuery(
      'PRAGMA table_info(friendly_pending)',
    )).any((c) => c['name'] == 'owner')) {
      await db.execute(
        "ALTER TABLE friendly_pending ADD COLUMN owner TEXT NOT NULL DEFAULT ''",
      );
    }
    await db.insert('friendly_pending', {
      'session_id': sessionId,
      'code': code,
      'owner': gateway.synchronizer.identity!.owner,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> flush() async {
    final db = await database.database;
    if ((await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='friendly_pending'",
    )).isEmpty) {
      return;
    }
    final owner = gateway.synchronizer.identity?.owner;
    if (owner == null) return;
    // Legacy pending invitations did not record the account. Do not submit
    // those scores under whichever account happens to be connected now.
    if (!(await db.rawQuery(
      'PRAGMA table_info(friendly_pending)',
    )).any((column) => column['name'] == 'owner')) {
      await db.execute(
        "ALTER TABLE friendly_pending ADD COLUMN owner TEXT NOT NULL DEFAULT ''",
      );
    }
    for (final row in await db.rawQuery(
      "SELECT p.code,g.score,g.extra_hints FROM friendly_pending p JOIN game_sessions g ON g.id=p.session_id WHERE p.sent=0 AND p.owner=? AND g.status!='playing' LIMIT 10",
      [owner],
    )) {
      try {
        await gateway.command('friend_score', {
          'code': row['code'],
          'score': row['score'],
          'assisted': row['extra_hints'] != '[]',
        });
        await db.update(
          'friendly_pending',
          {'sent': 1},
          where: 'code=?',
          whereArgs: [row['code']],
        );
      } on CommerceNetworkException catch (error) {
        if (error.status == 404 || error.status == 409) {
          await db.update(
            'friendly_pending',
            {'sent': -1},
            where: 'code=?',
            whereArgs: [row['code']],
          );
        } else {
          rethrow;
        }
      }
    }
  }
}
