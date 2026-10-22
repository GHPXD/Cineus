import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../datasources/database_provider.dart';
import '../datasources/database_seeder.dart';
import '../datasources/journey_schema.dart';

class InterstitialRepository {
  final DatabaseProvider database;
  final DateTime Function() now;
  final bool Function() holdout;
  InterstitialRepository(this.database, this.now, {bool Function()? holdout})
    : holdout = holdout ?? (() => Random.secure().nextBool());
  Future<void> _ensure(DatabaseExecutor db) async {
    await const DatabaseSeeder().ensureAppMetaTable(db);
    await JourneySchema.ensure(db);
    await db.execute('''CREATE TABLE IF NOT EXISTS ad_breaks(
      game_key TEXT PRIMARY KEY, reserved_at TEXT NOT NULL, day TEXT NOT NULL,
      stage_total INTEGER NOT NULL, shown INTEGER NOT NULL DEFAULT 0)''');
  }

  Future<int> _get(DatabaseExecutor db, String key) async =>
      int.tryParse(
        (await db.query(
                  'app_meta',
                  where: 'key=?',
                  whereArgs: [key],
                )).firstOrNull?['value']
                as String? ??
            '',
      ) ??
      0;
  Future<void> _set(DatabaseExecutor db, String key, int value) async =>
      db.insert('app_meta', {
        'key': key,
        'value': '$value',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
  Future<void> foreground() async {
    final db = await database.database;
    await db.transaction((txn) async {
      await _ensure(txn);
      final stamp = now().toUtc().millisecondsSinceEpoch;
      final last = await _get(txn, 'ads_last_foreground');
      final count = await _get(txn, 'ads_sessions');
      if (count == 0 ||
          stamp - last >= const Duration(minutes: 30).inMilliseconds) {
        await _set(txn, 'ads_sessions', count + 1);
      }
      if (stamp >= last) await _set(txn, 'ads_last_foreground', stamp);
      if ((await txn.query(
        'app_meta',
        where: 'key=?',
        whereArgs: ['ads_holdout'],
      )).isEmpty) {
        await _set(txn, 'ads_holdout', holdout() ? 1 : 0);
      }
    });
  }

  Future<bool> reserve(
    String key, {
    required bool rightsKnown,
    required bool paid,
    required bool ready,
  }) async {
    if (!rightsKnown || paid || !ready) return false;
    final db = await database.database;
    return db.transaction((txn) async {
      await _ensure(txn);
      await txn.delete(
        'ad_breaks',
        where: 'shown=0 AND reserved_at<?',
        whereArgs: [
          now().toUtc().subtract(const Duration(minutes: 2)).toIso8601String(),
        ],
      );
      if (await _get(txn, 'ads_holdout') == 1 ||
          await _get(txn, 'ads_sessions') <= 3) {
        return false;
      }
      if ((await txn.query(
        'journey_completions',
        where: "game_key=? AND kind='stage'",
        whereArgs: [key],
      )).isEmpty) {
        return false;
      }
      if ((await txn.query(
        'ad_breaks',
        where: 'game_key=?',
        whereArgs: [key],
      )).isNotEmpty) {
        return false;
      }
      final stamp = now().toUtc(),
          day = now().toUtc().toIso8601String().substring(0, 10);
      final previous = (await txn.query(
        'ad_breaks',
        where: 'shown=1',
        orderBy: 'reserved_at DESC',
        limit: 1,
      )).firstOrNull;
      if (previous != null &&
          stamp.difference(DateTime.parse(previous['reserved_at'] as String)) <
              const Duration(minutes: 10)) {
        return false;
      }
      if (Sqflite.firstIntValue(
            await txn.rawQuery(
              'SELECT COUNT(*) FROM ad_breaks WHERE day=? AND shown=1',
              [day],
            ),
          )! >=
          2) {
        return false;
      }
      final total = Sqflite.firstIntValue(
        await txn.rawQuery(
          "SELECT COUNT(*) FROM journey_completions WHERE kind='stage'",
        ),
      )!;
      if (total - (previous?['stage_total'] as int? ?? 0) < 4) return false;
      if ((await txn.query(
        'ad_breaks',
        where: 'shown=0',
        limit: 1,
      )).isNotEmpty) {
        return false;
      }
      await txn.insert('ad_breaks', {
        'game_key': key,
        'reserved_at': stamp.toIso8601String(),
        'day': day,
        'stage_total': total,
      });
      return true;
    });
  }

  Future<void> shown(String key) async {
    final db = await database.database;
    await db.update(
      'ad_breaks',
      {
        'shown': 1,
        'reserved_at': now().toUtc().toIso8601String(),
        'day': now().toUtc().toIso8601String().substring(0, 10),
      },
      where: 'game_key=?',
      whereArgs: [key],
    );
  }

  Future<void> cancel(String key) async {
    final db = await database.database;
    await db.delete(
      'ad_breaks',
      where: 'game_key=? AND shown=0',
      whereArgs: [key],
    );
  }
}
