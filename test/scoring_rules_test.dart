import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/constants/app_constants.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/entities/scoring_rules.dart';

void main() {
  group('ScoringRules — dicas', () {
    const r = ScoringRules.clue;

    test('10 passos valendo de 10 a 1', () {
      expect(r.totalSteps, 10);
      expect(r.maxScore, 10);
      expect(r.scoreAt(1), 10);
      expect(r.scoreAt(5), 6);
      expect(r.scoreAt(10), 1);
    });

    test('canRevealMore só até o penúltimo passo', () {
      expect(r.canRevealMore(1), isTrue);
      expect(r.canRevealMore(9), isTrue);
      expect(r.canRevealMore(10), isFalse);
    });

    test('isLastStep no passo final', () {
      expect(r.isLastStep(9), isFalse);
      expect(r.isLastStep(10), isTrue);
    });

    test('passos fora da faixa são fixados nas bordas', () {
      expect(r.scoreAt(0), 10);
      expect(r.scoreAt(-5), 10);
      expect(r.scoreAt(99), 1);
    });
  });

  group('ScoringRules — poster', () {
    const r = ScoringRules.poster;

    test('5 passos valendo de 5 a 1', () {
      expect(r.totalSteps, 5);
      expect(r.maxScore, 5);
      expect(r.scoreAt(1), 5);
      expect(r.scoreAt(3), 3);
      expect(r.scoreAt(5), 1);
    });

    test('canRevealMore e isLastStep', () {
      expect(r.canRevealMore(4), isTrue);
      expect(r.canRevealMore(5), isFalse);
      expect(r.isLastStep(5), isTrue);
    });
  });

  test('forMode devolve a regra do modo', () {
    expect(ScoringRules.forMode(GameMode.clue), ScoringRules.clue);
    expect(ScoringRules.forMode(GameMode.poster), ScoringRules.poster);
  });

  test('as constantes antigas de AppConstants seguem coerentes', () {
    // Estas existiam mas ficavam sem uso enquanto os números eram digitados à
    // mão em cada lugar. Se alguém mexer numa e não na outra, isto falha.
    expect(ScoringRules.clue.totalSteps, AppConstants.totalClues);
    expect(ScoringRules.clue.maxScore, AppConstants.maxScore);
    expect(ScoringRules.poster.totalSteps, AppConstants.visualLevels);
    expect(ScoringRules.poster.maxScore, AppConstants.maxVisualScore);
  });

  group('GameSession usa as regras do próprio modo', () {
    test('sessão de dicas pontua na escala 1-10', () {
      final s = GameSession.daily(
        mode: GameMode.clue,
        date: '2026-08-10',
        movieId: 1,
      );
      expect(s.potentialScore, 10);
      expect(s.copyWith(revealedClues: 7).potentialScore, 4);
      expect(s.copyWith(revealedClues: 10).canRevealMore, isFalse);
      expect(s.copyWith(revealedClues: 10).isOnLastStep, isTrue);
    });

    test('sessão de poster pontua na escala 1-5', () {
      final s = GameSession.daily(
        mode: GameMode.poster,
        date: '2026-08-10',
        movieId: 1,
      );
      expect(s.potentialScore, 5);
      expect(s.copyWith(revealedClues: 3).potentialScore, 3);
      expect(s.copyWith(revealedClues: 5).canRevealMore, isFalse);
      expect(s.copyWith(revealedClues: 5).isOnLastStep, isTrue);
      // no passo 5 de um jogo de dicas ainda haveria o que revelar
      expect(
        GameSession.daily(mode: GameMode.clue, date: 'x', movieId: 1)
            .copyWith(revealedClues: 5)
            .canRevealMore,
        isTrue,
      );
    });

    test('sessão encerrada devolve o placar gravado, não o potencial', () {
      final won = GameSession.daily(
        mode: GameMode.clue,
        date: '2026-08-10',
        movieId: 1,
      ).copyWith(revealedClues: 8, status: GameStatus.won, score: 3);
      expect(won.potentialScore, 3);
    });
  });
}
