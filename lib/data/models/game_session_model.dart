import 'dart:convert';

import '../../domain/entities/game_session.dart';

/// SQLite mapper for [GameSession].
///
/// Keeping persistence here makes the domain entity independent of database
/// column names and serialization choices while preserving the existing schema.
abstract final class GameSessionModel {
  static Map<String, dynamic> toMap(GameSession session) => {
    if (session.id != null) 'id': session.id,
    'mode': session.mode.name,
    'kind': session.kind.name,
    'date': session.date,
    'stage_id': session.stageId,
    'movie_id': session.movieId,
    'revealed_clues': session.revealedClues,
    'guesses': jsonEncode(session.guesses),
    'status': session.status.name,
    'score': session.score,
    'extra_hints': jsonEncode(session.extraHints),
  };

  static GameSession fromMap(Map<String, dynamic> map) => GameSession(
    id: map['id'] as int?,
    mode: GameMode.values.byName(map['mode'] as String),
    kind: SessionKind.values.byName(map['kind'] as String),
    date: map['date'] as String? ?? '',
    stageId: map['stage_id'] as int? ?? 0,
    movieId: map['movie_id'] as int,
    revealedClues: map['revealed_clues'] as int,
    guesses: (jsonDecode(map['guesses'] as String) as List).cast<String>(),
    status: GameStatus.values.byName(map['status'] as String),
    score: map['score'] as int,
    // Column added after the original schema. Older installs can read null.
    extraHints: map['extra_hints'] == null
        ? const []
        : (jsonDecode(map['extra_hints'] as String) as List).cast<String>(),
  );
}
