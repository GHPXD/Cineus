import 'package:sqflite/sqflite.dart';

import '../../domain/entities/ticket_reward.dart';
import '../../domain/repositories/reward_repository.dart';
import '../datasources/database_provider.dart';

class RewardRepositoryImpl implements RewardRepository {
  final DatabaseProvider _db;

  /// Injectable so tests are not tied to the wall clock.
  final DateTime Function() _now;

  RewardRepositoryImpl(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  @override
  Future<bool> claim(TicketReward reward) async {
    final db = await _db.database;
    // `key` is the PRIMARY KEY, so `ignore` makes a repeat claim a no-op and
    // tells us so via the returned rowid.
    final rowId = await db.insert(
      'ticket_rewards',
      {
        'key': reward.key,
        'amount': reward.amount,
        'awarded_at': _now().toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return rowId != 0;
  }

  @override
  Future<Set<String>> claimedKeys() async {
    final db = await _db.database;
    final rows = await db.query('ticket_rewards', columns: ['key']);
    return rows.map((r) => r['key'] as String).toSet();
  }

  @override
  Future<int> totalEarned() async {
    final db = await _db.database;
    final result =
        await db.rawQuery('SELECT COALESCE(SUM(amount), 0) AS total FROM ticket_rewards');
    return (result.first['total'] as int?) ?? 0;
  }

  @override
  Future<Set<String>> streakFreezes() async {
    final db = await _db.database;
    final rows = await db.query('streak_freezes', columns: ['date']);
    return rows.map((r) => r['date'] as String).toSet();
  }

  @override
  Future<bool> freezeStreakDay(String date) async {
    final db = await _db.database;
    final rowId = await db.insert(
      'streak_freezes',
      {'date': date, 'created_at': _now().toUtc().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return rowId != 0;
  }
}
