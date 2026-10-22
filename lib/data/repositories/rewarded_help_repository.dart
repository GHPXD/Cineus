import 'package:sqflite/sqflite.dart';
import '../datasources/database_provider.dart';

class HelpVideoUsage {
  final String state, option;
  const HelpVideoUsage(this.state, this.option);
  bool get pending => state == 'pending';
  bool get ready => state == 'ready';
  bool get used => state == 'used';
}

/// A video still grants the existing signed +2-ticket reward. One of those
/// tickets pays for the selected help; the other stays in the player's balance.
/// This journal binds delayed delivery to its original game and survives restart.
class RewardedHelpRepository {
  final DatabaseProvider database;
  final DateTime Function() now;
  RewardedHelpRepository(this.database, this.now);
  static Future<void> ensure(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS rewarded_game_help(
      game_key TEXT PRIMARY KEY, option_id TEXT NOT NULL,
      state TEXT NOT NULL CHECK(state IN ('pending','ready','used')),
      attempt TEXT UNIQUE, created_at TEXT NOT NULL)''');
  }

  void _key(String key) {
    if (key.length > 220 ||
        !RegExp(r'^(clue|poster|colors):[A-Za-z0-9:_.-]+$').hasMatch(key)) {
      throw ArgumentError('Invalid help game');
    }
  }

  Future<HelpVideoUsage?> read(String key) async {
    _key(key);
    final db = await database.database;
    return db.transaction((txn) async {
      await ensure(txn);
      final rows = await txn.query(
        'rewarded_game_help',
        where: 'game_key=?',
        whereArgs: [key],
      );
      if (rows.isEmpty) return null;
      final row = rows.single;
      final age = now().toUtc().difference(
        DateTime.parse(row['created_at'] as String),
      );
      // Server attempts expire after 30 minutes; allow ten minutes for late SSV.
      // An interrupted reservation before the ad starts can be retried sooner.
      final lifetime = Duration(minutes: row['attempt'] == null ? 2 : 40);
      if (row['state'] == 'pending' && age > lifetime) {
        await txn.delete(
          'rewarded_game_help',
          where: 'game_key=? AND state=?',
          whereArgs: [key, 'pending'],
        );
        return null;
      }
      return HelpVideoUsage(row['state'] as String, row['option_id'] as String);
    });
  }

  Future<bool> reserve(String key, String option) async {
    _key(key);
    if (option.isEmpty ||
        option.length > 180 ||
        RegExp(r'[\x00-\x1f]').hasMatch(option)) {
      throw ArgumentError('Invalid help option');
    }
    final db = await database.database;
    return db.transaction((txn) async {
      await ensure(txn);
      await txn.insert('rewarded_game_help', {
        'game_key': key,
        'option_id': option,
        'state': 'pending',
        'created_at': now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return (await txn.rawQuery('SELECT changes() AS n')).single['n'] == 1;
    });
  }

  Future<bool> hasPending() async {
    final db = await database.database;
    await ensure(db);
    final rows = await db.query(
      'rewarded_game_help',
      columns: ['game_key'],
      where: 'state=?',
      whereArgs: ['pending'],
    );
    for (final row in rows) {
      if ((await read(row['game_key'] as String))?.pending ?? false) {
        return true;
      }
    }
    return false;
  }

  Future<void> bind(String key, String attempt) async {
    _key(key);
    if (!RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(attempt)) {
      throw ArgumentError('Invalid attempt');
    }
    final db = await database.database;
    final changed = await db.update(
      'rewarded_game_help',
      {'attempt': attempt},
      where: 'game_key=? AND state=? AND attempt IS NULL',
      whereArgs: [key, 'pending'],
    );
    if (changed != 1) throw StateError('Help attempt no longer available');
  }

  /// Invoked only after the existing signed receipt has credited its +2 tickets.
  Future<void> delivered(String? attempt) async {
    if (attempt == null) return;
    final db = await database.database;
    await ensure(db);
    await db.update(
      'rewarded_game_help',
      {'state': 'ready'},
      where: 'attempt=? AND state=?',
      whereArgs: [attempt, 'pending'],
    );
  }

  Future<void> confirmed(String key) async {
    _key(key);
    final db = await database.database;
    await db.update(
      'rewarded_game_help',
      {'state': 'ready'},
      where: 'game_key=? AND state=?',
      whereArgs: [key, 'pending'],
    );
  }

  Future<bool> claim(String key, String option) async {
    _key(key);
    final db = await database.database;
    return await db.update(
          'rewarded_game_help',
          {'state': 'used'},
          where: 'game_key=? AND option_id=? AND state=?',
          whereArgs: [key, option, 'ready'],
        ) ==
        1;
  }

  Future<void> cancel(String key) async {
    _key(key);
    final db = await database.database;
    await db.delete(
      'rewarded_game_help',
      where: 'game_key=? AND state=?',
      whereArgs: [key, 'pending'],
    );
  }
}
