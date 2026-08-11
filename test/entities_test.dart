import 'package:flutter_test/flutter_test.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/domain/entities/movie.dart';
import 'package:cineus/domain/entities/clue.dart';
import 'package:cineus/domain/entities/player_tickets.dart';
import 'package:cineus/domain/entities/stage.dart';
import 'package:cineus/domain/entities/game_stats.dart';

void main() {
  group('GameSession', () {
    test('potentialScore decreases with revealedClues', () {
      final session = GameSession.daily(
        mode: GameMode.clue,
        date: '2025-01-01',
        movieId: 1,
      );
      expect(session.potentialScore, 10);

      final session5 = session.copyWith(revealedClues: 5);
      expect(session5.potentialScore, 6);

      final session10 = session.copyWith(revealedClues: 10);
      expect(session10.potentialScore, 1);
    });

    test('isFinished is true for won/lost, false for playing', () {
      final playing = GameSession.daily(
        mode: GameMode.clue,
        date: '2025-01-01',
        movieId: 1,
      );
      expect(playing.isFinished, false);

      final won = playing.copyWith(status: GameStatus.won);
      expect(won.isFinished, true);

      final lost = playing.copyWith(status: GameStatus.lost);
      expect(lost.isFinished, true);
    });

    test('canRevealMore is false at 10 clues', () {
      final session = GameSession.daily(
        mode: GameMode.clue,
        date: '2025-01-01',
        movieId: 1,
      ).copyWith(revealedClues: 10);
      expect(session.canRevealMore, false);
    });

    test('toMap/fromMap round-trip', () {
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
          );
      final map = session.toMap();
      final restored = GameSession.fromMap({...map, 'id': 1});

      expect(restored.mode, session.mode);
      expect(restored.kind, session.kind);
      expect(restored.date, session.date);
      expect(restored.movieId, session.movieId);
      expect(restored.revealedClues, session.revealedClues);
      expect(restored.guesses, session.guesses);
      expect(restored.status, session.status);
      expect(restored.score, session.score);
    });

    test('wrongGuessCount matches guesses length', () {
      final session = GameSession.daily(
        mode: GameMode.clue,
        date: '2025-01-01',
        movieId: 1,
      ).copyWith(guesses: ['a', 'b', 'c']);
      expect(session.wrongGuessCount, 3);
    });
  });

  group('Movie', () {
    test('acceptedTitles includes title and originalTitle', () {
      final movie = Movie(
        id: 1,
        title: 'A Origem',
        originalTitle: 'Inception',
        year: 2010,
        director: 'Christopher Nolan',
        genres: ['Sci-Fi'],
      );
      expect(movie.acceptedTitles, ['A Origem', 'Inception']);
    });

    test('acceptedTitles excludes null originalTitle', () {
      final movie = Movie(
        id: 1,
        title: 'A Origem',
        year: 2010,
        director: 'Christopher Nolan',
        genres: ['Sci-Fi'],
      );
      expect(movie.acceptedTitles, ['A Origem']);
    });

    test('equality is based on id', () {
      final movie1 = Movie(
        id: 1,
        title: 'A',
        year: 2020,
        director: 'D',
        genres: [],
      );
      final movie2 = Movie(
        id: 1,
        title: 'B',
        year: 2021,
        director: 'E',
        genres: [],
      );
      expect(movie1, equals(movie2));
    });
  });

  group('Clue', () {
    test('equality is based on id and clueNumber', () {
      final clue1 = Clue(
        id: 1,
        movieId: 1,
        clueNumber: 1,
        category: 'A',
        text: 'x',
      );
      final clue2 = Clue(
        id: 1,
        movieId: 1,
        clueNumber: 1,
        category: 'B',
        text: 'y',
      );
      expect(clue1, equals(clue2));
    });

    test('copyWith creates modified copy', () {
      final clue = Clue(
        id: 1,
        movieId: 1,
        clueNumber: 1,
        category: 'A',
        text: 'x',
      );
      final modified = clue.copyWith(text: 'new text');
      expect(modified.text, 'new text');
      expect(modified.category, 'A');
    });
  });

  group('PlayerTickets', () {
    test('total sums daily and extra tickets', () {
      final tickets = PlayerTickets(
        dailyTickets: 3,
        extraTickets: 2,
        lastResetDate: '2025-01-01',
      );
      expect(tickets.total, 5);
    });

    test('hasTickets is false when all tickets consumed', () {
      final tickets = PlayerTickets(
        dailyTickets: 0,
        extraTickets: 0,
        lastResetDate: '2025-01-01',
      );
      expect(tickets.hasTickets, false);
    });

    test('maxDailyTickets is 20', () {
      expect(PlayerTickets.maxDailyTickets, 20);
    });
  });

  group('Stage', () {
    test('progress calculates fraction correctly', () {
      final stage = Stage(
        id: 1,
        orderIndex: 1,
        name: 'Test',
        movieIds: [1, 2, 3, 4, 5],
        completedCount: 2,
      );
      expect(stage.progress, closeTo(0.4, 0.001));
    });

    test('isLocked respects status', () {
      final locked = Stage(
        id: 1,
        orderIndex: 1,
        name: 'Test',
        movieIds: [1],
        status: StageStatus.locked,
      );
      expect(locked.isLocked, true);
      expect(locked.isCompleted, false);
    });

    test('zero totalMovies gives zero progress', () {
      final stage = Stage(id: 1, orderIndex: 1, name: 'Test', movieIds: []);
      expect(stage.progress, 0.0);
    });
  });

  group('GameStats', () {
    test('defaults are zero', () {
      const stats = GameStats();
      expect(stats.totalGames, 0);
      expect(stats.totalWins, 0);
      expect(stats.winRate, 0);
      expect(stats.currentStreak, 0);
      expect(stats.maxStreak, 0);
      expect(stats.scoreDistribution, isEmpty);
    });
  });
}
