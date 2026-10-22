import '../datasources/journey_schema.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/color_stage.dart';
import '../../domain/entities/color_training_session.dart';
import '../../domain/entities/saved_color_session.dart';
import '../datasources/color_schema.dart';
import '../datasources/database_provider.dart';

class ColorStageRepository {
  final DatabaseProvider databaseProvider;
  final DateTime Function() now;
  const ColorStageRepository(this.databaseProvider, this.now);
  Future<void> prepare() async =>
      ColorSchema.ensure(await databaseProvider.database);

  Future<List<SavedColorSession>> records(
    DatabaseExecutor db,
    ColorStageCatalog catalog,
    int stageId,
  ) async {
    final rows = await db.rawQuery(
      '''SELECT s.* FROM color_stage_slots p
      JOIN color_sessions s ON s.id = p.session_id
      WHERE p.stage_version = ? AND p.stage_id = ? ORDER BY p.match_index''',
      [catalog.version, stageId],
    );
    return rows.map((row) {
      final record = SavedColorSession.fromRow(row);
      if (record.stageId != stageId ||
          record.stageVersion != catalog.version ||
          record.game.questions.map((q) => q.id).join('|') !=
              catalog
                  .stage(stageId)
                  .match(record.stageMatch!)
                  .map((q) => q.id)
                  .join('|')) {
        throw const FormatException('Stage differs from published order');
      }
      return record;
    }).toList();
  }

  Future<void> _check(
    DatabaseExecutor db,
    ColorStageCatalog catalog,
    int stageId,
    int match,
  ) async {
    catalog.stage(stageId).match(match);
    if (stageId > 1) {
      final previous = await records(db, catalog, stageId - 1);
      if (previous.length != catalog.stage(stageId - 1).matches ||
          previous.any((s) => s.status != 'completed')) {
        throw StateError('Stage is locked');
      }
    }
    if (match > 0) {
      final current = await records(db, catalog, stageId);
      if (!current.any(
        (s) => s.stageMatch == match - 1 && s.status == 'completed',
      )) {
        throw StateError('Previous match is unfinished');
      }
    }
  }

  Future<SavedColorSession?> existing(
    DatabaseExecutor db,
    ColorStageCatalog catalog,
    int stageId,
    int match,
  ) async {
    await _check(db, catalog, stageId, match);
    return (await records(
      db,
      catalog,
      stageId,
    )).where((s) => s.stageMatch == match).firstOrNull;
  }

  Future<SavedColorSession> create(
    DatabaseExecutor db,
    ColorStageCatalog catalog,
    int stageId,
    int match,
  ) async {
    await _check(db, catalog, stageId, match);
    final time = now().toUtc();
    final record = SavedColorSession(
      id: 'stage:${catalog.version}:$stageId:$match',
      kind: ColorSessionKind.training,
      dailyDate: null,
      revision: 0,
      status: 'active',
      createdAt: time,
      updatedAt: time,
      catalog: catalog.colors,
      game: ColorTrainingSession(
        packVersion: catalog.colors.packVersion,
        questions: catalog.stage(stageId).match(match),
      ),
      stageId: stageId,
      stageMatch: match,
      stageVersion: catalog.version,
    );
    await db.insert('color_sessions', record.toRow());
    await JourneySchema.colors(db, record);
    await db.insert('color_stage_slots', {
      'stage_version': catalog.version,
      'stage_id': stageId,
      'match_index': match,
      'session_id': record.id,
    });
    return record;
  }
}
