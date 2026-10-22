import 'dart:convert';
import '../../core/utils/daily_selector.dart';
import 'color_daily_selector.dart';
import 'color_question.dart';
import 'color_training_session.dart';

enum ColorSessionKind { training, daily }

class SavedColorSession {
  final String id;
  final ColorSessionKind kind;
  final String? dailyDate;
  final String? archiveDate;
  final String? reviewOf;
  bool get isArchive => archiveDate != null;
  final int revision;
  final String status;
  final String selectorVersion;
  final DateTime createdAt, updatedAt;
  final ColorPilotCatalog catalog;
  final ColorTrainingSession game;
  final int? stageId, stageMatch;
  final String? stageVersion;
  bool get isStage => stageId != null;
  const SavedColorSession({
    required this.id,
    required this.kind,
    required this.dailyDate,
    this.archiveDate,
    this.reviewOf,
    required this.revision,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.catalog,
    required this.game,
    this.selectorVersion = ColorDailySelector.version,
    this.stageId,
    this.stageMatch,
    this.stageVersion,
  });

  SavedColorSession edited(ColorTrainingSession next, DateTime now) =>
      SavedColorSession(
        id: id,
        kind: kind,
        dailyDate: dailyDate,
        archiveDate: archiveDate,
        reviewOf: reviewOf,
        revision: revision + 1,
        status: next.phase == ColorRoundPhase.finished ? 'completed' : 'active',
        createdAt: createdAt,
        updatedAt: now.toUtc(),
        catalog: catalog,
        game: next,
        selectorVersion: selectorVersion,
        stageId: stageId,
        stageMatch: stageMatch,
        stageVersion: stageVersion,
      );

  Map<String, Object?> toRow() => {
    'id': id,
    'kind': kind.name,
    'daily_date': dailyDate,
    'revision': revision,
    'status': status,
    'active_slot':
        !isStage &&
            !isArchive &&
            reviewOf == null &&
            kind == ColorSessionKind.training &&
            status == 'active'
        ? 'training'
        : null,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'snapshot': jsonEncode({
      'schema': 1,
      'selector': selectorVersion,
      'catalog': catalog.toJson(),
      'game': game.toJson(),
      if (isArchive) 'archive_date': archiveDate,
      if (reviewOf != null) 'review_of': reviewOf,
      if (isStage)
        'stage': {'id': stageId, 'match': stageMatch, 'version': stageVersion},
    }),
  };

  factory SavedColorSession.fromRow(Map<String, Object?> row) {
    final json = jsonDecode(row['snapshot'] as String) as Map<String, dynamic>;
    if (json['schema'] != 1) {
      throw const FormatException('Unsupported saved colour schema');
    }
    final catalog = ColorPilotCatalog.fromJson(
      json['catalog'] as Map<String, dynamic>,
    );
    final game = ColorTrainingSession.fromJson(
      json['game'] as Map<String, dynamic>,
    );
    final kind = ColorSessionKind.values.byName(row['kind'] as String);
    final date = row['daily_date'] as String?;
    final stage = json['stage'] as Map<String, dynamic>?;
    final archive = json['archive_date'] as String?;
    final review = json['review_of'] as String?;
    if (review != null &&
        (review.isEmpty ||
            review.length > 160 ||
            stage != null ||
            archive != null ||
            kind != ColorSessionKind.training ||
            row['active_slot'] != null)) {
      throw const FormatException('Invalid review metadata');
    }
    if (archive != null &&
        (stage != null ||
            kind != ColorSessionKind.training ||
            DailySelector.dateFromKey(archive) == null ||
            DailySelector.todayKey(DailySelector.dateFromKey(archive)!) !=
                archive ||
            row['id'] != 'archive:$archive' ||
            row['active_slot'] != null)) {
      throw const FormatException('Invalid archive metadata');
    }
    if (stage != null &&
        (kind != ColorSessionKind.training ||
            (stage['id'] as int) < 1 ||
            (stage['match'] as int) < 0 ||
            (stage['match'] as int) > 1 ||
            (stage['version'] as String).isEmpty ||
            row['active_slot'] != null)) {
      throw const FormatException('Invalid stage metadata');
    }
    if (catalog.packVersion != game.packVersion ||
        (kind == ColorSessionKind.daily &&
            (date == null ||
                DailySelector.dateFromKey(date) == null ||
                DailySelector.todayKey(DailySelector.dateFromKey(date)!) !=
                    date)) ||
        (kind == ColorSessionKind.training && date != null) ||
        ((row['status'] == 'completed') !=
            (game.phase == ColorRoundPhase.finished))) {
      throw const FormatException('Invalid saved colour session');
    }
    // All reference regions are pinned too, not only the five scored targets.
    for (final q in game.questions) {
      if (!catalog.questions.any(
        (item) => jsonEncode(item.toJson()) == jsonEncode(q.toJson()),
      )) {
        throw const FormatException('Question differs from pinned pack');
      }
    }
    return SavedColorSession(
      id: row['id'] as String,
      kind: kind,
      dailyDate: date,
      archiveDate: archive,
      reviewOf: review,
      revision: row['revision'] as int,
      status: row['status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      catalog: catalog,
      game: game,
      selectorVersion: json['selector'] as String,
      stageId: stage?['id'] as int?,
      stageMatch: stage?['match'] as int?,
      stageVersion: stage?['version'] as String?,
    );
  }
}
