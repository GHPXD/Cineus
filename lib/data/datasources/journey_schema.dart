import 'package:sqflite/sqflite.dart';
import '../../domain/entities/saved_color_session.dart';

abstract final class JourneySchema {
  static Future<void> ensure(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS journey_completions(
      game_key TEXT PRIMARY KEY, mode TEXT NOT NULL, kind TEXT NOT NULL,
      completed_at TEXT NOT NULL, score_cents INTEGER NOT NULL)''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS journey_period ON journey_completions(completed_at)',
    );
    await db.execute('''CREATE TABLE IF NOT EXISTS journey_claims(
      period TEXT NOT NULL, mission TEXT NOT NULL, claimed_at TEXT NOT NULL,
      PRIMARY KEY(period,mission))''');
    await db.execute('''CREATE TABLE IF NOT EXISTS character_discovery(
      character_id TEXT PRIMARY KEY, found_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS event_claims(
      event_id TEXT PRIMARY KEY, claimed_at TEXT NOT NULL)''');
  }

  static Future<void> finish(
    DatabaseExecutor db, {
    required String key,
    required String mode,
    required String kind,
    required DateTime at,
    required int scoreCents,
  }) async {
    await ensure(db);
    await db.insert('journey_completions', {
      'game_key': key,
      'mode': mode,
      'kind': kind,
      'completed_at': at.toUtc().toIso8601String(),
      'score_cents': scoreCents,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> colors(
    DatabaseExecutor db,
    SavedColorSession record,
  ) async {
    await ensure(db);
    final seen = {
      ...record.game.answers.map((a) => a.question.characterId),
      record.game.question.characterId,
    };
    for (final character in seen) {
      await db.insert('character_discovery', {
        'character_id': character,
        'found_at': record.updatedAt.toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (record.status == 'completed') {
      await finish(
        db,
        key: 'colors:${record.id}',
        mode: 'colors',
        kind: record.isStage
            ? 'stage'
            : record.isArchive
            ? 'archive'
            : record.kind.name,
        at: record.updatedAt,
        scoreCents: record.game.averageCents!,
      );
    }
  }
}
