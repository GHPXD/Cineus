import 'dart:convert';
import 'dart:math';
import '../../domain/entities/product_event.dart';
import '../../domain/services/product_telemetry.dart';
import '../datasources/database_provider.dart';
import 'growth_gateway.dart';
import 'local_product_telemetry.dart';

/// Opt-in, bounded durable outbox. Failed delivery never blocks gameplay.
class PopulationTelemetry implements ProductTelemetry {
  final DatabaseProvider database;
  final DateTime Function() now;
  final bool localEnabled;
  final GrowthGateway? Function() gateway;
  Future<void>? _flushing;
  PopulationTelemetry(
    this.database,
    this.now,
    this.gateway, {
    this.localEnabled = false,
  });
  Future<void> _ensure() async {
    final db = await database.database;
    await db.execute(
      'CREATE TABLE IF NOT EXISTS metrics_preferences(id INTEGER PRIMARY KEY CHECK(id=1), enabled INTEGER NOT NULL, pending INTEGER NOT NULL)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS metrics_outbox(id TEXT PRIMARY KEY, event TEXT NOT NULL, occurred_at INTEGER NOT NULL, properties TEXT NOT NULL)',
    );
  }

  Future<bool> consented() async {
    await _ensure();
    return (await (await database.database).query(
          'metrics_preferences',
          where: 'id=1',
        )).firstOrNull?['enabled'] ==
        1;
  }

  Future<void> setConsent(bool enabled) async {
    await _ensure();
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.rawInsert(
        'INSERT OR REPLACE INTO metrics_preferences VALUES(1,?,1)',
        [enabled ? 1 : 0],
      );
      if (!enabled) {
        await txn.delete('metrics_outbox');
        if ((await txn.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='product_events'",
        )).isNotEmpty) {
          await txn.delete('product_events');
        }
      }
    });
  }

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {
    final safe = ProductEvents.sanitize(event, properties);
    if (safe == null) return;
    await _ensure();
    final db = await database.database;
    final stamp = now().toUtc().millisecondsSinceEpoch ~/ 1000;
    await db.transaction((txn) async {
      final preferences = await txn.query('metrics_preferences', where: 'id=1');
      if (preferences.firstOrNull?['enabled'] != 1) return;
      if (localEnabled) {
        await txn.execute('''CREATE TABLE IF NOT EXISTS product_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT, event TEXT NOT NULL,
          occurred_at TEXT NOT NULL, properties TEXT NOT NULL)''');
        await txn.insert('product_events', {
          'event': event,
          'occurred_at': now().toUtc().toIso8601String(),
          'properties': jsonEncode(safe),
        });
        await txn.delete(
          'product_events',
          where: 'occurred_at<?',
          whereArgs: [
            now()
                .toUtc()
                .subtract(LocalProductTelemetry.retention)
                .toIso8601String(),
          ],
        );
        await txn.rawDelete(
          'DELETE FROM product_events WHERE id NOT IN '
          '(SELECT id FROM product_events ORDER BY id DESC LIMIT ?)',
          [LocalProductTelemetry.maxEvents],
        );
      }
      await txn.insert('metrics_outbox', {
        'id':
            '$stamp:${Random.secure().nextInt(1 << 32)}:${Random.secure().nextInt(1 << 32)}',
        'event': event,
        'occurred_at': stamp,
        'properties': jsonEncode(safe),
      });
      await txn.delete(
        'metrics_outbox',
        where: 'occurred_at<?',
        whereArgs: [stamp - 60 * 86400],
      );
      await txn.rawDelete(
        'DELETE FROM metrics_outbox WHERE rowid NOT IN (SELECT rowid FROM metrics_outbox ORDER BY rowid DESC LIMIT 2000)',
      );
    });
  }

  Future<bool> preferencePending() async {
    await _ensure();
    return (await (await database.database).query(
          'metrics_preferences',
          where: 'id=1',
        )).firstOrNull?['pending'] ==
        1;
  }

  Future<void> flush() =>
      _flushing ??= _flush().whenComplete(() => _flushing = null);
  Future<void> _flush() async {
    await _ensure();
    final db = await database.database;
    final preferences = (await db.query(
      'metrics_preferences',
      where: 'id=1',
    )).firstOrNull;
    if (preferences == null) return;
    final api = gateway();
    if (api == null) return;
    final enabled = preferences['enabled'] == 1;
    if (preferences['pending'] == 1) {
      await api.command('consent', {'enabled': enabled});
      await db.update(
        'metrics_preferences',
        {'pending': 0},
        where: 'id=1 AND enabled=?',
        whereArgs: [enabled ? 1 : 0],
      );
    }
    if (!enabled) return;
    for (var batch = 0; batch < 4; batch++) {
      if (!await consented()) return;
      final rows = await db.query(
        'metrics_outbox',
        orderBy: 'rowid',
        limit: 50,
      );
      if (rows.isEmpty) return;
      final result = await api.command('events', {
        'events': [
          for (final row in rows)
            {...row, 'properties': jsonDecode(row['properties'] as String)},
        ],
      });
      final accepted = (result['accepted'] as List).cast<String>().toSet();
      await db.transaction((txn) async {
        for (final row in rows) {
          if (accepted.contains(row['id'])) {
            await txn.delete(
              'metrics_outbox',
              where: 'id=?',
              whereArgs: [row['id']],
            );
          }
        }
      });
    }
  }
}
