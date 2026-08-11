import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/domain/entities/achievement.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/entities/game_stats.dart';
import 'package:cineus/domain/entities/movie.dart';
import 'package:cineus/domain/entities/play_insights.dart';

GameSession session(int movieId, {required bool won, int score = 0}) =>
    GameSession.daily(
      mode: GameMode.clue,
      date: '2026-08-10',
      movieId: movieId,
    ).copyWith(status: won ? GameStatus.won : GameStatus.lost, score: score);

Movie movie(int id, {required List<String> genres, required int year}) =>
    Movie(id: id, title: 'F$id', year: year, director: 'D', genres: genres);

void main() {
  group('PlayInsights — por gênero', () {
    test('conta um jogo em cada gênero do filme', () {
      final insights = PlayInsights.from(
        [session(1, won: true, score: 8)],
        {
          1: movie(1, genres: ['Ação', 'Ficção'], year: 2000),
        },
      );
      expect(
        insights.byGenre.map((b) => b.label),
        containsAll(['Ação', 'Ficção']),
      );
      expect(
        insights.byGenre.every((b) => b.played == 1 && b.won == 1),
        isTrue,
      );
    });

    test('taxa de acerto e média de pontos por gênero', () {
      final insights = PlayInsights.from(
        [
          session(1, won: true, score: 9),
          session(2, won: true, score: 5),
          session(3, won: false),
        ],
        {
          1: movie(1, genres: ['Drama'], year: 1990),
          2: movie(2, genres: ['Drama'], year: 1990),
          3: movie(3, genres: ['Drama'], year: 1990),
        },
      );
      final drama = insights.byGenre.single;
      expect(drama.played, 3);
      expect(drama.won, 2);
      expect(drama.winRate, closeTo(2 / 3, 1e-9));
      expect(drama.averageScore, closeTo(7.0, 1e-9));
    });

    test('ordena pelos mais jogados', () {
      final insights = PlayInsights.from(
        [
          session(1, won: true, score: 5),
          session(2, won: true, score: 5),
          session(3, won: true, score: 5),
        ],
        {
          1: movie(1, genres: ['Ação', 'Terror'], year: 2000),
          2: movie(2, genres: ['Ação'], year: 2000),
          3: movie(3, genres: ['Ação'], year: 2000),
        },
      );
      expect(insights.byGenre.first.label, 'Ação');
      expect(insights.byGenre.first.played, 3);
    });

    test('gênero vazio ou só espaço é ignorado', () {
      final insights = PlayInsights.from(
        [session(1, won: true, score: 5)],
        {
          1: movie(1, genres: ['', '  ', 'Ação'], year: 2000),
        },
      );
      expect(insights.byGenre.map((b) => b.label), ['Ação']);
    });

    test('sessão sem filme conhecido é ignorada, sem estourar', () {
      final insights = PlayInsights.from([session(99, won: true)], {});
      expect(insights.isEmpty, isTrue);
    });
  });

  group('PlayInsights — por década', () {
    test('agrupa por década e ordena da mais nova', () {
      final insights = PlayInsights.from(
        [session(1, won: true, score: 5), session(2, won: false)],
        {
          1: movie(1, genres: ['Ação'], year: 1994),
          2: movie(2, genres: ['Ação'], year: 2021),
        },
      );
      expect(insights.byDecade.map((b) => b.label), ['2020s', '1990s']);
    });

    test('ano ausente não cria década', () {
      final insights = PlayInsights.from(
        [session(1, won: true, score: 5)],
        {
          1: movie(1, genres: ['Ação'], year: 0),
        },
      );
      expect(insights.byDecade, isEmpty);
      expect(insights.byGenre, isNotEmpty);
    });
  });

  group('PlayInsights — melhor e pior gênero', () {
    final sessions = [
      for (var i = 1; i <= 3; i++) session(i, won: true, score: 8),
      for (var i = 4; i <= 6; i++) session(i, won: false),
    ];
    final movies = {
      for (var i = 1; i <= 3; i++) i: movie(i, genres: ['Ação'], year: 2000),
      for (var i = 4; i <= 6; i++) i: movie(i, genres: ['Terror'], year: 2000),
    };

    test('identifica os extremos', () {
      final insights = PlayInsights.from(sessions, movies);
      expect(insights.bestGenre()!.label, 'Ação');
      expect(insights.worstGenre()!.label, 'Terror');
    });

    test('exige um mínimo de jogos para opinar', () {
      final insights = PlayInsights.from(
        [session(1, won: true, score: 8)],
        {
          1: movie(1, genres: ['Ação'], year: 2000),
        },
      );
      expect(insights.bestGenre(), isNull);
      expect(insights.bestGenre(minPlayed: 1), isNotNull);
    });
  });

  group('Achievements', () {
    List<Achievement> evaluate({
      GameStats stats = const GameStats(),
      int stages = 0,
      int tickets = 0,
    }) => Achievements.evaluate(
      stats: stats,
      stagesCompleted: stages,
      ticketsEarned: tickets,
    );

    test('nada desbloqueado num histórico vazio', () {
      final all = evaluate();
      expect(all, isNotEmpty);
      expect(all.where((a) => a.isUnlocked), isEmpty);
    });

    test('primeira vitória desbloqueia com uma vitória', () {
      final a = evaluate(
        stats: const GameStats(totalWins: 1),
      ).firstWhere((x) => x.id == 'first_win');
      expect(a.isUnlocked, isTrue);
    });

    test('"sem titubear" exige um 10 na distribuição', () {
      final semDez = evaluate(
        stats: const GameStats(scoreDistribution: {9: 5}),
      ).firstWhere((x) => x.id == 'perfect');
      expect(semDez.isUnlocked, isFalse);

      final comDez = evaluate(
        stats: const GameStats(scoreDistribution: {10: 1}),
      ).firstWhere((x) => x.id == 'perfect');
      expect(comDez.isUnlocked, isTrue);
    });

    test('marcos de sequência usam o recorde histórico', () {
      final a = evaluate(stats: const GameStats(maxStreak: 7));
      expect(a.firstWhere((x) => x.id == 'streak_7').isUnlocked, isTrue);
      expect(a.firstWhere((x) => x.id == 'streak_30').isUnlocked, isFalse);
      expect(
        a.firstWhere((x) => x.id == 'streak_30').progress,
        closeTo(7 / 30, 1e-9),
      );
    });

    test('progresso é limitado a 1 e o rótulo não passa da meta', () {
      final a = evaluate(
        stats: const GameStats(maxStreak: 100),
      ).firstWhere((x) => x.id == 'streak_30');
      expect(a.progress, 1);
      expect(a.progressLabel, '30 / 30');
    });

    test('estágios e tickets contam', () {
      final a = evaluate(stages: 5, tickets: 100);
      expect(a.firstWhere((x) => x.id == 'stages_5').isUnlocked, isTrue);
      expect(a.firstWhere((x) => x.id == 'tickets_100').isUnlocked, isTrue);
    });

    test('metas de 1 não mostram rótulo de progresso', () {
      final a = evaluate().firstWhere((x) => x.id == 'first_win');
      expect(a.progressLabel, isEmpty);
    });

    test('ids são únicos', () {
      final ids = evaluate().map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
