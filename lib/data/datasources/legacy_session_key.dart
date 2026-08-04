import '../../domain/entities/game_session.dart';

/// Decodes the pre-refactor `game_sessions.date` key into explicit fields.
///
/// Before the schema carried `mode`/`kind`/`stage_id` columns, identity was
/// packed into one string in four shapes:
///
///   `2026-08-04`            daily clue game
///   `visual_2026-08-04`     daily poster game
///   `stage_3_27`            stage 3, film 27, clue mode
///   `visual_stage_3_27`     stage 3, film 27, poster mode
///
/// Kept as a standalone, pure parser so the one-time migration can be tested
/// exhaustively without a database.
class LegacySessionKey {
  final GameMode mode;
  final SessionKind kind;

  /// `YYYY-MM-DD` for daily keys, empty for stage keys.
  final String date;

  /// Stage number for stage keys, 0 for daily keys.
  final int stageId;

  /// Film id for stage keys, null for daily keys (the row's own `movie_id`
  /// column is authoritative there).
  final int? movieId;

  const LegacySessionKey({
    required this.mode,
    required this.kind,
    required this.date,
    required this.stageId,
    required this.movieId,
  });

  static final _dailyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _stagePattern = RegExp(r'^stage_(\d+)_(\d+)$');

  /// Parses [key], or returns null when it matches none of the four shapes.
  ///
  /// A null result means the row is unrecognisable and must not be migrated
  /// silently into the wrong bucket.
  static LegacySessionKey? parse(String key) {
    // Order matters: `visual_stage_…` also starts with `visual_`.
    if (key.startsWith('visual_stage_')) {
      return _parseStage(key.substring('visual_'.length), GameMode.poster);
    }
    if (key.startsWith('stage_')) {
      return _parseStage(key, GameMode.clue);
    }
    if (key.startsWith('visual_')) {
      return _parseDaily(key.substring('visual_'.length), GameMode.poster);
    }
    return _parseDaily(key, GameMode.clue);
  }

  static LegacySessionKey? _parseStage(String rest, GameMode mode) {
    final match = _stagePattern.firstMatch(rest);
    if (match == null) return null;
    return LegacySessionKey(
      mode: mode,
      kind: SessionKind.stage,
      date: '',
      stageId: int.parse(match.group(1)!),
      movieId: int.parse(match.group(2)!),
    );
  }

  static LegacySessionKey? _parseDaily(String rest, GameMode mode) {
    if (!_dailyPattern.hasMatch(rest)) return null;
    return LegacySessionKey(
      mode: mode,
      kind: SessionKind.daily,
      date: rest,
      stageId: 0,
      movieId: null,
    );
  }
}
