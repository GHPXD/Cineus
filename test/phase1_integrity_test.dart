import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/data/repositories/game_repository_impl.dart';
import 'package:cineus/data/repositories/movie_repository_impl.dart';
import 'package:cineus/data/repositories/stage_repository_impl.dart';
import 'package:cineus/domain/entities/game_session.dart';
import 'package:cineus/presentation/providers/play_notifier.dart';

import 'support/test_database.dart';

void main() {
  late Database db;

  PlayNotifier notifierFor(GameMode mode) {
    final provider = TestDatabaseProvider(db);
    return PlayNotifier(
      mode,
      MovieRepositoryImpl(provider),
      GameRepositoryImpl(provider),
      StageRepositoryImpl(provider),
    );
  }

  setUp(() async {
    db = await openTestDatabase(withMovies: true);
    await db.execute('''
      CREATE TABLE stage_progress (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        stage_id INTEGER NOT NULL,
        movie_id INTEGER NOT NULL,
        mode     TEXT NOT NULL DEFAULT 'clue',
        status   TEXT NOT NULL DEFAULT 'completed',
        UNIQUE(stage_id, movie_id, mode)
      )
    ''');

    // Deliberately non-contiguous IDs: the old daily selector used COUNT(*) and
    // then assumed the chosen number was itself a valid movie id.
    for (final (id, title) in [
      (10, 'Filme Dez'),
      (20, 'Filme Vinte'),
      (40, 'Filme Quarenta'),
    ]) {
      await db.insert('movies', {
        'id': id,
        'tmdb_id': 1000 + id,
        'title': title,
        'original_title': title,
      });
      for (var clue = 1; clue <= 10; clue++) {
        await db.insert('clues', {
          'movie_id': id,
          'clue_number': clue,
          'category': 'Conceito',
          'text': 'Dica $clue',
        });
      }
    }
  });

  tearDown(() async => db.close());

  test('desafio diário escolhe apenas IDs que realmente existem', () async {
    for (final mode in GameMode.values) {
      final notifier = notifierFor(mode);
      expect(await notifier.loadDaily(), isTrue);
      expect([10, 20, 40], contains(notifier.state.movie!.id));
    }
  });

  test('duas revelações simultâneas consomem dois passos distintos', () async {
    final notifier = notifierFor(GameMode.clue);
    expect(await notifier.loadStageFilm(10, 1, [10]), isTrue);

    await Future.wait([notifier.revealNext(), notifier.revealNext()]);

    expect(notifier.state.step, 3);
    expect(notifier.state.currentScore, 8);
  });

  test('palpites simultâneos preservam ambos e avançam dois passos', () async {
    final notifier = notifierFor(GameMode.clue);
    expect(await notifier.loadStageFilm(10, 1, [10]), isTrue);

    final outcomes = await Future.wait([
      notifier.submitGuess('Titanic'),
      notifier.submitGuess('Matrix'),
    ]);

    expect(outcomes, [GuessOutcome.wrong, GuessOutcome.wrong]);
    expect(notifier.state.session!.guesses, ['Titanic', 'Matrix']);
    expect(notifier.state.step, 3);
  });

  test('criação concorrente converge para uma única sessão', () async {
    final repo = GameRepositoryImpl(TestDatabaseProvider(db));
    final results = await Future.wait(
      List.generate(
        8,
        (_) => repo.saveSession(
          GameSession.stage(mode: GameMode.clue, stageId: 5, movieId: 10),
        ),
      ),
    );

    expect(results.map((session) => session.id).toSet().length, 1);
    final rows = await db.query(
      'game_sessions',
      where: "kind = 'stage' AND stage_id = 5 AND movie_id = 10",
    );
    expect(rows.length, 1);
  });

  test('gravação atrasada não ressuscita sessão já finalizada', () async {
    final repo = GameRepositoryImpl(TestDatabaseProvider(db));
    final initial = await repo.saveSession(
      GameSession.stage(mode: GameMode.clue, stageId: 2, movieId: 10),
    );

    final won = await repo.saveSession(
      initial.copyWith(status: GameStatus.won, score: 10),
    );
    expect(won.status, GameStatus.won);

    final stale = await repo.saveSession(
      initial.copyWith(revealedClues: 2),
    );
    expect(stale.status, GameStatus.won);
    expect(stale.score, 10);

    final stored = await repo.getStageSession(GameMode.clue, 2, 10);
    expect(stored!.status, GameStatus.won);
    expect(stored.score, 10);
  });

  test('carregar vitória repara stage_progress perdido após crash', () async {
    final repo = GameRepositoryImpl(TestDatabaseProvider(db));
    await repo.saveSession(
      GameSession.stage(mode: GameMode.clue, stageId: 7, movieId: 10)
          .copyWith(status: GameStatus.won, score: 9),
    );
    expect(await db.query('stage_progress'), isEmpty);

    final notifier = notifierFor(GameMode.clue);
    expect(await notifier.loadStageFilm(10, 7, [10]), isTrue);

    final progress = await db.query(
      'stage_progress',
      where: 'stage_id = 7 AND movie_id = 10 AND mode = ?',
      whereArgs: ['clue'],
    );
    expect(progress.length, 1);
  });
}
