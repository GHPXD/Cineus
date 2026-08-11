import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/data/models/game_session_model.dart';
import 'package:cineus/domain/entities/game_session.dart';

void main() {
  test('GameSessionModel preserves a session through the persistence map', () {
    final session =
        GameSession.daily(
          mode: GameMode.clue,
          date: '2025-06-15',
          movieId: 42,
        ).copyWith(
          revealedClues: 3,
          guesses: ['Wrong 1', 'Wrong 2'],
          status: GameStatus.won,
          score: 8,
          extraHints: ['year'],
        );

    final map = GameSessionModel.toMap(session);
    final restored = GameSessionModel.fromMap({...map, 'id': 1});

    expect(restored.id, 1);
    expect(restored.mode, session.mode);
    expect(restored.kind, session.kind);
    expect(restored.date, session.date);
    expect(restored.movieId, session.movieId);
    expect(restored.revealedClues, session.revealedClues);
    expect(restored.guesses, session.guesses);
    expect(restored.status, session.status);
    expect(restored.score, session.score);
    expect(restored.extraHints, session.extraHints);
  });

  test('older rows without extra_hints still deserialize safely', () {
    final session = GameSessionModel.fromMap({
      'id': 9,
      'mode': 'poster',
      'kind': 'stage',
      'date': '',
      'stage_id': 2,
      'movie_id': 17,
      'revealed_clues': 4,
      'guesses': '[]',
      'status': 'playing',
      'score': 0,
      'extra_hints': null,
    });

    expect(session.extraHints, isEmpty);
    expect(session.mode, GameMode.poster);
    expect(session.kind, SessionKind.stage);
  });
}
