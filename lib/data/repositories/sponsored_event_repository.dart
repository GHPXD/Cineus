import 'package:sqflite/sqflite.dart';
import '../../domain/entities/commerce_content.dart';
import '../datasources/database_provider.dart';
import '../datasources/journey_schema.dart';
import '../datasources/collection_schema.dart';

class EventProgress {
  final bool joined, claimed;
  final int completed;
  const EventProgress(this.joined, this.claimed, this.completed);
}

class SponsoredEventRepository {
  final DatabaseProvider database;
  final DateTime Function() now;
  const SponsoredEventRepository(this.database, this.now);
  Future<void> _ensure(DatabaseExecutor db) async {
    await JourneySchema.ensure(db);
    await db.execute(
      'CREATE TABLE IF NOT EXISTS event_enrollment(event_id TEXT PRIMARY KEY,joined_at TEXT NOT NULL)',
    );
  }

  Future<void> join(ContentEvent e) async {
    if (!e.active(now())) return;
    final db = await database.database;
    await _ensure(db);
    await db.insert('event_enrollment', {
      'event_id': e.id,
      'joined_at': now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<EventProgress> _progress(DatabaseExecutor db, ContentEvent e) async {
    final rows = await db.query(
      'event_enrollment',
      where: 'event_id=?',
      whereArgs: [e.id],
    );
    final claims = await db.query(
      'event_claims',
      where: 'event_id=?',
      whereArgs: [e.id],
    );
    if (rows.isEmpty) return EventProgress(false, claims.isNotEmpty, 0);
    final start = rows.single['joined_at'] as String;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM journey_completions WHERE completed_at>=? AND completed_at>=? AND completed_at<?',
        [start, e.from.toIso8601String(), e.until.toIso8601String()],
      ),
    )!;
    return EventProgress(true, claims.isNotEmpty, count.clamp(0, e.target));
  }

  Future<EventProgress> progress(ContentEvent e) async {
    final db = await database.database;
    await _ensure(db);
    return _progress(db, e);
  }

  Future<bool> claim(ContentEvent e) async {
    final db = await database.database;
    return db.transaction((txn) async {
      await _ensure(txn);
      await CollectionSchema.ensure(txn);
      final p = await _progress(txn, e);
      if (p.claimed || !p.joined || p.completed < e.target) return false;
      await txn.insert('event_claims', {
        'event_id': e.id,
        'claimed_at': now().toUtc().toIso8601String(),
      });
      await txn.insert('collection_ownership', {
        'item_id': e.reward,
        'source_id': 'event:${e.id}',
        'granted_at': now().toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return true;
    });
  }
}
