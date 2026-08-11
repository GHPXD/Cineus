import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/entities/stage.dart';
import '../../domain/repositories/stage_repository.dart';
import '../datasources/database_provider.dart';

class StageRepositoryImpl implements StageRepository {
  final DatabaseProvider _db;

  StageRepositoryImpl(this._db);

  @override
  Future<List<Stage>> getAllStages({String mode = 'clue'}) async {
    final db = await _db.database;
    final stagesRaw = await db.query('stages', orderBy: 'order_index ASC');
    final progressRaw = await db.query(
      'stage_progress',
      where: 'mode = ?',
      whereArgs: [mode],
    );

    final completedKeys = <String>{};
    for (final row in progressRaw) {
      if (row['status'] == 'completed') {
        completedKeys.add('${row['stage_id']}_${row['movie_id']}');
      }
    }

    final stages = <Stage>[];
    bool previousComplete = true; // Stage 1 is always unlocked

    for (final raw in stagesRaw) {
      final id = raw['id'] as int;
      final movieIds = (jsonDecode(raw['film_ids'] as String) as List)
          .cast<int>();
      final completedCount = movieIds
          .where((mid) => completedKeys.contains('${id}_$mid'))
          .length;
      final allDone = movieIds.isNotEmpty && completedCount == movieIds.length;

      final status = previousComplete
          ? (allDone ? StageStatus.completed : StageStatus.unlocked)
          : StageStatus.locked;

      stages.add(
        Stage(
          id: id,
          orderIndex: raw['order_index'] as int,
          name: raw['name'] as String,
          movieIds: movieIds,
          status: status,
          completedCount: completedCount,
        ),
      );

      previousComplete = allDone;
    }

    return stages;
  }

  @override
  Future<void> markMovieCompleted(
    int stageId,
    int movieId, {
    String mode = 'clue',
  }) async {
    final db = await _db.database;
    await db.insert('stage_progress', {
      'stage_id': stageId,
      'movie_id': movieId,
      'mode': mode,
      'status': 'completed',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
