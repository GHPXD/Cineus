import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/core/utils/daily_selector.dart';
import 'package:cineus/data/repositories/game_repository_impl.dart';
import 'package:cineus/domain/entities/game_session.dart';

/// Builds a finished session for a daily key.
GameSession daily(
  String date, {
  required bool won,
  int score = 0,
  int clues = 1,
}) {
  return GameSession.daily(
    mode: GameMode.clue,
    date: date,
    movieId: 1,
  ).copyWith(
    revealedClues: clues,
    status: won ? GameStatus.won : GameStatus.lost,
    score: won ? score : 0,
  );
}

void main() {
  final today = DateTime.utc(2026, 8, 10);

  group('computeStats — contaminação por outros modos', () {
    // Regression: the old filter was `date NOT LIKE 'stage_%'`, which let
    // `visual_<date>` and `visual_stage_<id>_<id>` through. Poster scores (1–5)
    // polluted the clue distribution (1–10), and because "visual_…" sorts above
    // "2025-…" the streak was computed over poster rows first.
    test('a query só devolve chaves diárias YYYY-MM-DD', () {
      const keys = [
        '2026-08-10',
        'stage_1_5',
        'visual_2026-08-10',
        'visual_stage_1_5',
      ];
      final daily = keys.where(DailySelector.isDailyKey).toList();
      expect(daily, ['2026-08-10']);
    });

    test('a ordenação por string agora é cronológica', () {
      final keys = ['2026-08-01', '2026-08-10', '2026-08-02']..sort();
      expect(keys, ['2026-08-01', '2026-08-02', '2026-08-10']);
      // O que quebrava antes: "visual_…" > "2026-…" em ordem lexicográfica.
      expect('visual_2026-08-01'.compareTo('2026-08-10'), greaterThan(0));
    });
  });

  group('computeStats — agregações', () {
    test('lista vazia devolve stats zeradas', () {
      final s = GameRepositoryImpl.computeStats([], todayUtc: today);
      expect(s.totalGames, 0);
      expect(s.winRate, 0);
      expect(s.currentStreak, 0);
      expect(s.scoreDistribution, isEmpty);
    });

    test('winRate e médias contam apenas o que foi passado', () {
      final s = GameRepositoryImpl.computeStats([
        daily('2026-08-10', won: true, score: 9, clues: 2),
        daily('2026-08-09', won: false, clues: 10),
        daily('2026-08-08', won: true, score: 7, clues: 4),
      ], todayUtc: today);

      expect(s.totalGames, 3);
      expect(s.totalWins, 2);
      expect(s.winRate, closeTo(2 / 3, 1e-9));
      // média só das vitórias: (2 + 4) / 2
      expect(s.averageCluesUsed, closeTo(3.0, 1e-9));
      expect(s.scoreDistribution, {9: 1, 0: 1, 7: 1});
    });
  });

  group('currentStreak — precisa ser consecutivo em dias de calendário', () {
    test('conta vitórias consecutivas terminando hoje', () {
      final s = GameRepositoryImpl.computeStats([
        daily('2026-08-10', won: true, score: 8),
        daily('2026-08-09', won: true, score: 7),
        daily('2026-08-08', won: true, score: 6),
      ], todayUtc: today);
      expect(s.currentStreak, 3);
    });

    test('quebra numa derrota', () {
      final s = GameRepositoryImpl.computeStats([
        daily('2026-08-10', won: true, score: 8),
        daily('2026-08-09', won: false),
        daily('2026-08-08', won: true, score: 6),
      ], todayUtc: today);
      expect(s.currentStreak, 1);
    });

    test(
      'quebra num dia não jogado (o bug antigo somava por cima do buraco)',
      () {
        final s = GameRepositoryImpl.computeStats([
          daily('2026-08-10', won: true, score: 8),
          // 09 e 08 não foram jogados
          daily('2026-08-07', won: true, score: 7),
          daily('2026-08-06', won: true, score: 6),
        ], todayUtc: today);
        expect(s.currentStreak, 1);
      },
    );

    test('sobrevive quando a última partida foi ontem', () {
      final s = GameRepositoryImpl.computeStats([
        daily('2026-08-09', won: true, score: 8),
        daily('2026-08-08', won: true, score: 7),
      ], todayUtc: today);
      expect(s.currentStreak, 2);
    });

    test('zera quando a última partida é mais velha que ontem', () {
      final s = GameRepositoryImpl.computeStats([
        daily('2026-08-05', won: true, score: 8),
        daily('2026-08-04', won: true, score: 7),
      ], todayUtc: today);
      expect(s.currentStreak, 0);
      // mas o recorde histórico permanece
      expect(s.maxStreak, 2);
    });

    test('zera quando a partida mais recente é derrota', () {
      final s = GameRepositoryImpl.computeStats([
        daily('2026-08-10', won: false),
        daily('2026-08-09', won: true, score: 7),
      ], todayUtc: today);
      expect(s.currentStreak, 0);
    });
  });

  group('maxStreak', () {
    test('encontra a maior sequência histórica', () {
      final s = GameRepositoryImpl.computeStats([
        daily('2026-08-10', won: true, score: 5), // atual: 1
        daily('2026-08-09', won: false),
        daily('2026-08-08', won: true, score: 5), // sequência de 3
        daily('2026-08-07', won: true, score: 5),
        daily('2026-08-06', won: true, score: 5),
        daily('2026-08-05', won: false),
        daily('2026-08-04', won: true, score: 5),
      ], todayUtc: today);
      expect(s.currentStreak, 1);
      expect(s.maxStreak, 3);
    });

    test('buraco de calendário também corta a maior sequência', () {
      final s = GameRepositoryImpl.computeStats([
        daily('2026-08-10', won: true, score: 5),
        daily('2026-08-09', won: true, score: 5),
        // 08 não jogado
        daily('2026-08-07', won: true, score: 5),
        daily('2026-08-06', won: true, score: 5),
        daily('2026-08-05', won: true, score: 5),
      ], todayUtc: today);
      expect(s.maxStreak, 3);
      expect(s.currentStreak, 2);
    });
  });
}
