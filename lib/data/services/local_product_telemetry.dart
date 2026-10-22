import 'dart:convert';
import '../../domain/entities/product_event.dart';
import '../../domain/services/product_telemetry.dart';
import '../datasources/database_provider.dart';

/// Explicitly enabled local diagnostics. No SDK, endpoint or automatic export.
/// Raw events last at most 60 days / 2000 entries; a local sample cannot measure
/// population DAU/MAU, payer conversion or cohort retention across devices.
class LocalProductTelemetry implements ProductTelemetry {
  static const maxEvents = 2000;
  static const retention = Duration(days: 60);
  final DatabaseProvider database;
  final DateTime Function() now;

  LocalProductTelemetry(this.database, {DateTime Function()? now})
    : now = now ?? DateTime.now;

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {
    final sanitized = ProductEvents.sanitize(event, properties);
    if (sanitized == null) return;
    final instant = now().toUtc();
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.execute('''CREATE TABLE IF NOT EXISTS product_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event TEXT NOT NULL, occurred_at TEXT NOT NULL, properties TEXT NOT NULL
      )''');
      await txn.insert('product_events', {
        'event': event,
        'occurred_at': instant.toIso8601String(),
        'properties': jsonEncode(sanitized),
      });
      await txn.delete(
        'product_events',
        where: 'occurred_at < ?',
        whereArgs: [instant.subtract(retention).toIso8601String()],
      );
      await txn.rawDelete(
        '''DELETE FROM product_events WHERE id NOT IN
        (SELECT id FROM product_events ORDER BY id DESC LIMIT ?)''',
        [maxEvents],
      );
    });
  }

  /// Aggregated local troubleshooting data, read only when explicitly requested.
  Future<List<Map<String, Object?>>> summary() async {
    final db = await database.database;
    final exists = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='product_events'",
    );
    if (exists.isEmpty) return [];
    await db.delete(
      'product_events',
      where: 'occurred_at < ?',
      whereArgs: [now().toUtc().subtract(retention).toIso8601String()],
    );
    return db.rawQuery('''SELECT event, COUNT(*) AS count,
      MIN(occurred_at) AS first_at, MAX(occurred_at) AS last_at
      FROM product_events GROUP BY event ORDER BY event''');
  }
}
