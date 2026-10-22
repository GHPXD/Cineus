import 'package:sqflite/sqflite.dart';

enum TicketMovement {
  baseline,
  dailyReset,
  debit,
  refund,
  earned,
  verifiedReward,
  stageStart,
}

/// Local bounded audit, not a commercial receipt or a server-verified balance.
/// Writes use the caller's transaction, so a failed audit cannot leave a debit
/// committed while its caller believes it failed. Existing balances are kept.
abstract final class TicketAudit {
  static const maxEntries = 2000;
  static const retention = Duration(days: 60);

  static Future<void> ensure(DatabaseExecutor db) => db.execute('''
    CREATE TABLE IF NOT EXISTS ticket_movements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      occurred_at TEXT NOT NULL,
      reason TEXT NOT NULL,
      daily_delta INTEGER NOT NULL,
      extra_delta INTEGER NOT NULL,
      daily_after INTEGER NOT NULL,
      extra_after INTEGER NOT NULL
    )
  ''');

  static Future<void> record(
    DatabaseExecutor db, {
    required TicketMovement reason,
    required int dailyBefore,
    required int extraBefore,
    required int dailyAfter,
    required int extraAfter,
    required DateTime now,
  }) async {
    if (dailyBefore == dailyAfter &&
        extraBefore == extraAfter &&
        reason != TicketMovement.baseline) {
      return;
    }
    await db.insert('ticket_movements', {
      'occurred_at': now.toUtc().toIso8601String(),
      'reason': reason.name,
      'daily_delta': dailyAfter - dailyBefore,
      'extra_delta': extraAfter - extraBefore,
      'daily_after': dailyAfter,
      'extra_after': extraAfter,
    });
    await prune(db, now);
  }

  static Future<void> prune(DatabaseExecutor db, DateTime now) async {
    await db.delete(
      'ticket_movements',
      where: 'occurred_at < ?',
      whereArgs: [now.toUtc().subtract(retention).toIso8601String()],
    );
    await db.rawDelete(
      '''DELETE FROM ticket_movements WHERE id NOT IN
      (SELECT id FROM ticket_movements ORDER BY id DESC LIMIT ?)''',
      [maxEntries],
    );
  }

  static Future<List<Map<String, Object?>>> summary(DatabaseExecutor db) =>
      db.rawQuery('''SELECT reason, COUNT(*) AS count,
      SUM(daily_delta) AS daily_delta, SUM(extra_delta) AS extra_delta
      FROM ticket_movements GROUP BY reason ORDER BY reason''');
}
