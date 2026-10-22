import '../datasources/journey_schema.dart';
import 'dart:convert';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import '../../core/utils/daily_selector.dart';
import '../../domain/entities/color_daily_selector.dart';
import '../../domain/entities/color_question.dart';
import '../../domain/entities/color_training_session.dart';
import '../../domain/entities/saved_color_session.dart';
export '../../domain/entities/saved_color_session.dart';
import '../datasources/color_schema.dart';
import '../datasources/database_provider.dart';
import '../datasources/database_seeder.dart';

class ColorWriteConflict implements Exception {}

/// Dedicated tables. No writes to clue/poster sessions, streaks or tickets.
class ColorRepository {
  final DatabaseProvider databaseProvider;
  final DateTime Function() now;
  final Future<List<String>?> Function(String date)? schedule;
  ColorRepository(
    this.databaseProvider, {
    DateTime Function()? now,
    this.schedule,
  }) : now = now ?? DateTime.now;

  Future<Database> _db() async {
    final db = await databaseProvider.database;
    await ColorSchema.ensure(db);
    return db;
  }

  Future<SavedColorSession?> load(String id) async {
    final db = await _db();
    final rows = await db.query(
      'color_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : SavedColorSession.fromRow(rows.single);
  }

  Future<List<SavedColorSession>> list() async {
    final db = await _db();
    final rows = await db.query(
      'color_sessions',
      where: 'status != ?',
      whereArgs: ['abandoned'],
      orderBy: 'updated_at DESC, id DESC',
    );
    return rows.map(SavedColorSession.fromRow).toList();
  }

  Future<SavedColorSession?> activeTraining() async {
    final db = await _db();
    final rows = await db.query(
      'color_sessions',
      where: 'active_slot = ?',
      whereArgs: ['training'],
    );
    return rows.isEmpty ? null : SavedColorSession.fromRow(rows.single);
  }

  Future<bool> guideSeen() async =>
      await const DatabaseSeeder().readMeta(
        await databaseProvider.database,
        'colors_guide_v1',
      ) ==
      'seen';

  Future<void> markGuideSeen() async => const DatabaseSeeder().writeMeta(
    await databaseProvider.database,
    'colors_guide_v1',
    'seen',
  );

  Future<SavedColorSession> start(
    ColorPilotCatalog catalog,
    ColorSessionKind kind, {
    bool replaceTraining = false,
  }) async {
    final db = await _db(), instant = now().toUtc();
    final date = kind == ColorSessionKind.daily
        ? DailySelector.todayKey(instant)
        : null;
    final published = date == null ? null : await schedule?.call(date);
    return db.transaction((txn) async {
      final existing = await txn.query(
        'color_sessions',
        where: kind == ColorSessionKind.daily
            ? 'daily_date = ?'
            : 'active_slot = ?',
        whereArgs: [date ?? 'training'],
        limit: 1,
      );
      if (existing.isNotEmpty && !replaceTraining) {
        return SavedColorSession.fromRow(existing.single);
      }
      if (existing.isNotEmpty && kind == ColorSessionKind.daily) {
        return SavedColorSession.fromRow(existing.single);
      }
      if (existing.isNotEmpty) {
        await txn.update(
          'color_sessions',
          {
            'active_slot': null,
            'status': 'abandoned',
            'revision': (existing.single['revision'] as int) + 1,
          },
          where: 'id = ?',
          whereArgs: [existing.single['id']],
        );
      }
      final game = kind == ColorSessionKind.daily
          ? ColorDailySelector.draw(
              catalog,
              date!,
              publishedQuestions: published,
            )
          : ColorTrainingSession.draw(catalog);
      final id = date == null
          ? 'training:${instant.microsecondsSinceEpoch}:${Random.secure().nextInt(0x7fffffff)}'
          : 'daily:$date';
      final record = SavedColorSession(
        id: id,
        kind: kind,
        dailyDate: date,
        revision: 0,
        status: 'active',
        createdAt: instant,
        updatedAt: instant,
        catalog: catalog,
        game: game,
      );
      await txn.insert('color_sessions', record.toRow());
      await JourneySchema.colors(txn, record);
      return record;
    });
  }

  Future<SavedColorSession> archive(
    ColorPilotCatalog catalog,
    String date,
  ) async {
    final parsed = DailySelector.dateFromKey(date);
    if (parsed == null ||
        DailySelector.todayKey(parsed) != date ||
        date.compareTo(DailySelector.todayKey(now())) >= 0) {
      throw const FormatException('Archive requires a past date');
    }
    final db = await _db();
    final published = await schedule?.call(date);
    return db.transaction((txn) async {
      final id = 'archive:$date';
      final existing = await txn.query(
        'color_sessions',
        where: 'id=?',
        whereArgs: [id],
      );
      if (existing.isNotEmpty) {
        return SavedColorSession.fromRow(existing.single);
      }
      final original = (await txn.query(
        'color_sessions',
        where: 'daily_date=?',
        whereArgs: [date],
      )).firstOrNull;
      final pinned = original == null
          ? null
          : SavedColorSession.fromRow(original);
      final record = SavedColorSession(
        id: id,
        kind: ColorSessionKind.training,
        dailyDate: null,
        archiveDate: date,
        revision: 0,
        status: 'active',
        createdAt: now().toUtc(),
        updatedAt: now().toUtc(),
        catalog: pinned?.catalog ?? catalog,
        game: pinned == null
            ? ColorDailySelector.draw(
                catalog,
                date,
                publishedQuestions: published,
              )
            : ColorTrainingSession(
                packVersion: pinned.catalog.packVersion,
                questions: pinned.game.questions,
              ),
      );
      await txn.insert('color_sessions', record.toRow());
      return record;
    });
  }

  Future<SavedColorSession> review(SavedColorSession source) async {
    if (source.status != 'completed') {
      throw StateError('Only completed games can be reviewed');
    }
    final instant = now().toUtc();
    final record = SavedColorSession(
      id: 'review:${instant.microsecondsSinceEpoch}:${Random.secure().nextInt(0x7fffffff)}',
      kind: ColorSessionKind.training,
      dailyDate: null,
      revision: 0,
      status: 'active',
      createdAt: instant,
      updatedAt: instant,
      catalog: source.catalog,
      reviewOf: source.id,
      game: ColorTrainingSession(
        packVersion: source.catalog.packVersion,
        questions: source.game.questions,
      ),
    );
    await (await _db()).insert('color_sessions', record.toRow());
    return record;
  }

  Future<SavedColorSession> save(
    SavedColorSession previous,
    ColorTrainingSession game,
  ) async {
    final before = previous.game.toJson(), after = game.toJson();
    if (before['pack'] != after['pack'] ||
        before['rule'] != after['rule'] ||
        jsonEncode(before['questions']) != jsonEncode(after['questions']) ||
        game.answers.length < previous.game.answers.length ||
        jsonEncode(
              (after['answers'] as List)
                  .take(previous.game.answers.length)
                  .toList(),
            ) !=
            jsonEncode(before['answers'])) {
      throw const FormatException(
        'Cannot replace pinned questions or confirmed answers',
      );
    }
    final db = await _db();
    final next = previous.edited(game.clone(), now());
    return db.transaction((txn) async {
      final count = await txn.update(
        'color_sessions',
        next.toRow(),
        where: 'id = ? AND revision = ? AND status = ?',
        whereArgs: [previous.id, previous.revision, 'active'],
      );
      if (count != 1) throw ColorWriteConflict();
      await JourneySchema.colors(txn, next);
      return next;
    });
  }
}
