// The real GameRepositoryImpl, against real SQLite.
//
// This is what the DatabaseProvider seam bought: before, the repository reached
// the concrete DatabaseHelper singleton, so the statistics bug had to be
// diagnosed by replaying its SQL by hand instead of running the actual code.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/data/repositories/game_repository_impl.dart';
import 'package:cineus/domain/entities/game_session.dart';

import 'support/test_database.dart';

void main() {
  late Database db;
  late GameRepositoryImpl repo;

  setUp(() async {
    db = await openTestDatabase();
    repo = GameRepositoryImpl(TestDatabaseProvider(db));
  });

  tearDown(() async => db.close());

  GameSession finishedDaily(
    GameMode mode,
    String date, {
    required bool won,
    int score = 0,
    int clues = 1,
  }) {
    return GameSession.daily(mode: mode, date: date, movieId: 1).copyWith(
      revealedClues: clues,
      status: won ? GameStatus.won : GameStatus.lost,
      score: won ? score : 0,
    );
  }

  group('sessões diárias', () {
    test('devolve null quando não existe', () async {
      expect(await repo.getDailySession(GameMode.clue, '2026-08-10'), isNull);
    });

    test('salva e recupera por modo e data', () async {
      final saved = await repo.saveSession(
        GameSession.daily(mode: GameMode.clue, date: '2026-08-10', movieId: 42),
      );
      expect(saved.id, isNotNull);

      final found = await repo.getDailySession(GameMode.clue, '2026-08-10');
      expect(found!.movieId, 42);
      expect(found.mode, GameMode.clue);
      expect(found.kind, SessionKind.daily);
    });

    test('os dois modos coexistem no mesmo dia sem se confundir', () async {
      await repo.saveSession(
        GameSession.daily(mode: GameMode.clue, date: '2026-08-10', movieId: 10),
      );
      await repo.saveSession(
        GameSession.daily(
          mode: GameMode.poster,
          date: '2026-08-10',
          movieId: 99,
        ),
      );

      expect(
        (await repo.getDailySession(GameMode.clue, '2026-08-10'))!.movieId,
        10,
      );
      expect(
        (await repo.getDailySession(GameMode.poster, '2026-08-10'))!.movieId,
        99,
      );
    });

    test('salvar duas vezes sem id atualiza em vez de duplicar', () async {
      final first = await repo.saveSession(
        GameSession.daily(mode: GameMode.clue, date: '2026-08-10', movieId: 10),
      );
      // Um chamador que perdeu o id não pode criar uma segunda linha.
      final second = await repo.saveSession(
        GameSession.daily(
          mode: GameMode.clue,
          date: '2026-08-10',
          movieId: 10,
        ).copyWith(revealedClues: 4),
      );

      expect(second.id, first.id);
      expect((await db.query('game_sessions')).length, 1);
      expect(
        (await repo.getDailySession(
          GameMode.clue,
          '2026-08-10',
        ))!.revealedClues,
        4,
      );
    });

    test('o índice único impede duas diárias do mesmo modo e data', () async {
      await repo.saveSession(
        GameSession.daily(mode: GameMode.clue, date: '2026-08-10', movieId: 10),
      );

      expect(
        () => db.insert('game_sessions', {
          'mode': 'clue',
          'kind': 'daily',
          'date': '2026-08-10',
          'stage_id': 0,
          'movie_id': 77,
          'revealed_clues': 1,
          'guesses': '[]',
          'status': 'playing',
          'score': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('sessões de estágio', () {
    test('identificadas por modo, estágio e filme', () async {
      await repo.saveSession(
        GameSession.stage(mode: GameMode.clue, stageId: 3, movieId: 27),
      );

      expect(await repo.getStageSession(GameMode.clue, 3, 27), isNotNull);
      expect(await repo.getStageSession(GameMode.clue, 3, 28), isNull);
      expect(await repo.getStageSession(GameMode.clue, 4, 27), isNull);
      expect(await repo.getStageSession(GameMode.poster, 3, 27), isNull);
    });

    test('o mesmo filme pode ser jogado nos dois modos', () async {
      await repo.saveSession(
        GameSession.stage(mode: GameMode.clue, stageId: 1, movieId: 5),
      );
      await repo.saveSession(
        GameSession.stage(mode: GameMode.poster, stageId: 1, movieId: 5),
      );

      expect((await db.query('game_sessions')).length, 2);
    });

    test('delete remove só a sessão apontada', () async {
      await repo.saveSession(
        GameSession.stage(mode: GameMode.clue, stageId: 1, movieId: 5),
      );
      await repo.saveSession(
        GameSession.stage(mode: GameMode.poster, stageId: 1, movieId: 5),
      );
      await repo.saveSession(
        GameSession.stage(mode: GameMode.clue, stageId: 1, movieId: 6),
      );

      await repo.deleteStageSession(GameMode.clue, 1, 5);

      expect(await repo.getStageSession(GameMode.clue, 1, 5), isNull);
      expect(await repo.getStageSession(GameMode.poster, 1, 5), isNotNull);
      expect(await repo.getStageSession(GameMode.clue, 1, 6), isNotNull);
    });

    test('o índice único impede duplicar a mesma sessão de estágio', () async {
      await repo.saveSession(
        GameSession.stage(mode: GameMode.clue, stageId: 2, movieId: 9),
      );

      expect(
        () => db.insert('game_sessions', {
          'mode': 'clue',
          'kind': 'stage',
          'date': '',
          'stage_id': 2,
          'movie_id': 9,
          'revealed_clues': 1,
          'guesses': '[]',
          'status': 'playing',
          'score': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('estatísticas escopadas por modo', () {
    setUp(() async {
      // Dicas: 2 vitórias em dias consecutivos
      await repo.saveSession(
        finishedDaily(
          GameMode.clue,
          '2026-08-10',
          won: true,
          score: 9,
          clues: 2,
        ),
      );
      await repo.saveSession(
        finishedDaily(
          GameMode.clue,
          '2026-08-09',
          won: true,
          score: 7,
          clues: 4,
        ),
      );
      // Poster: escala 1-5, não pode contaminar
      await repo.saveSession(
        finishedDaily(GameMode.poster, '2026-08-10', won: true, score: 5),
      );
      // Estágios: nunca contam
      await repo.saveSession(
        GameSession.stage(
          mode: GameMode.clue,
          stageId: 1,
          movieId: 3,
        ).copyWith(status: GameStatus.won, score: 8),
      );
      await repo.saveSession(
        GameSession.stage(
          mode: GameMode.poster,
          stageId: 2,
          movieId: 7,
        ).copyWith(status: GameStatus.won, score: 4),
      );
      // Em andamento: nunca conta
      await repo.saveSession(
        GameSession.daily(mode: GameMode.clue, date: '2026-08-08', movieId: 1),
      );
    });

    test('só diárias encerradas do modo pedido', () async {
      final clue = await repo.getFinishedDailySessions(mode: GameMode.clue);
      expect(clue.map((s) => s.date), ['2026-08-10', '2026-08-09']);

      final poster = await repo.getFinishedDailySessions(mode: GameMode.poster);
      expect(poster.map((s) => s.date), ['2026-08-10']);
    });

    test('a distribuição das Dicas não recebe placar de Poster', () async {
      final stats = await repo.getStats(mode: GameMode.clue);
      expect(stats.totalGames, 2);
      expect(stats.scoreDistribution, {9: 1, 7: 1});
      expect(stats.averageCluesUsed, closeTo(3.0, 1e-9));
    });

    test('as stats de Poster existem separadamente', () async {
      final stats = await repo.getStats(mode: GameMode.poster);
      expect(stats.totalGames, 1);
      expect(stats.scoreDistribution, {5: 1});
    });

    test('o padrão é o modo Dicas', () async {
      final def = await repo.getStats();
      final clue = await repo.getStats(mode: GameMode.clue);
      expect(def.totalGames, clue.totalGames);
      expect(def.scoreDistribution, clue.scoreDistribution);
    });
  });

  group('round-trip completo', () {
    test('guesses, status e placar sobrevivem à ida e volta', () async {
      final original =
          GameSession.daily(
            mode: GameMode.poster,
            date: '2026-08-10',
            movieId: 33,
          ).copyWith(
            revealedClues: 3,
            guesses: ['Errado 1', 'Errado 2'],
            status: GameStatus.won,
            score: 3,
          );

      await repo.saveSession(original);
      final loaded = (await repo.getDailySession(
        GameMode.poster,
        '2026-08-10',
      ))!;

      expect(loaded.mode, GameMode.poster);
      expect(loaded.kind, SessionKind.daily);
      expect(loaded.revealedClues, 3);
      expect(loaded.guesses, ['Errado 1', 'Errado 2']);
      expect(loaded.status, GameStatus.won);
      expect(loaded.score, 3);
      // Regra de pontuação vem do modo
      expect(loaded.rules.maxScore, 5);
      expect(loaded.rules.totalSteps, 5);
    });
  });
}
