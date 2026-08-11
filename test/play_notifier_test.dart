// Full game flows through the unified PlayNotifier, with real repositories on
// real SQLite.

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

  const films = [
    (1, 'Vingadores', 'The Avengers'),
    (2, 'Vingadores: Ultimato', 'Avengers: Endgame'),
    (3, 'Coração Valente', 'Braveheart'),
    (4, 'Rocky', 'Rocky'),
    (5, 'Rocky II', 'Rocky II'),
  ];

  String errorText(PlayLoadError error) => switch (error) {
    PlayLoadError.noMovies => 'Nenhum filme na base',
    PlayLoadError.movieNotFound => 'Filme não encontrado',
    PlayLoadError.loadFailed => 'Falha controlada',
  };

  PlayNotifier notifierFor(GameMode mode) {
    final provider = TestDatabaseProvider(db);
    return PlayNotifier(
      mode,
      MovieRepositoryImpl(provider),
      GameRepositoryImpl(provider),
      StageRepositoryImpl(provider),
      errorText: errorText,
    );
  }

  setUp(() async {
    db = await openTestDatabase(withMovies: true);
    const seeder = DatabaseSeederForTest();
    await seeder.ensureStages(db);

    for (final (id, title, original) in films) {
      await db.insert('movies', {
        'id': id,
        'tmdb_id': 1000 + id,
        'title': title,
        'original_title': original,
      });
      for (var n = 1; n <= 10; n++) {
        await db.insert('clues', {
          'movie_id': id,
          'clue_number': n,
          'category': 'Conceito',
          'text': 'Dica $n do filme $id',
        });
      }
    }
  });

  tearDown(() async => db.close());

  group('carga diária', () {
    test('cria a sessão e carrega o filme com as dicas', () async {
      final n = notifierFor(GameMode.clue);
      await n.loadDaily();
      expect(n.state.isLoading, isFalse);
      expect(n.state.error, isNull);
      expect(n.state.movie, isNotNull);
      expect(n.state.movie!.clues.length, 10);
      expect(n.state.session!.kind, SessionKind.daily);
      expect(n.state.session!.mode, GameMode.clue);
      expect(n.state.step, 1);
      expect(n.state.currentScore, 10);
    });

    test('poster começa valendo 5 e com blur máximo', () async {
      final n = notifierFor(GameMode.poster);
      await n.loadDaily();
      expect(n.state.currentScore, 5);
      expect(n.state.blurSigma, visualBlurSigmas.first);
      expect(n.state.posterAsset, 'assets/posters/${n.state.movie!.id}.webp');
    });

    test('recarregar reaproveita a sessão em vez de duplicar', () async {
      final a = notifierFor(GameMode.clue);
      await a.loadDaily();
      await a.revealNext();
      final b = notifierFor(GameMode.clue);
      await b.loadDaily();
      expect(b.state.step, 2, reason: 'progresso preservado');
      expect((await db.query('game_sessions')).length, 1);
    });

    test('os dois modos não se atropelam no mesmo dia', () async {
      final clue = notifierFor(GameMode.clue);
      final poster = notifierFor(GameMode.poster);
      await clue.loadDaily();
      await poster.loadDaily();
      expect((await db.query('game_sessions')).length, 2);
      expect(clue.state.session!.mode, GameMode.clue);
      expect(poster.state.session!.mode, GameMode.poster);
    });

    test('base vazia devolve erro em vez de estourar', () async {
      await db.delete('movies');
      final n = notifierFor(GameMode.clue);
      await n.loadDaily();
      expect(n.state.error, 'Nenhum filme na base');
      expect(n.state.isLoading, isFalse);
    });
  });

  group('revelar', () {
    test('cada revelação custa um ponto e persiste', () async {
      final n = notifierFor(GameMode.clue);
      await n.loadDaily();
      await n.revealNext();
      expect(n.state.step, 2);
      expect(n.state.currentScore, 9);
      await n.revealNext();
      expect(n.state.currentScore, 8);
      final stored = (await db.query(
        'game_sessions',
        where: "kind = 'daily'",
      )).single;
      expect(stored['revealed_clues'], 3);
    });

    test('para no último passo de cada modo', () async {
      final clue = notifierFor(GameMode.clue);
      await clue.loadDaily();
      for (var i = 0; i < 20; i++) {
        await clue.revealNext();
      }
      expect(clue.state.step, 10);
      final poster = notifierFor(GameMode.poster);
      await poster.loadDaily();
      for (var i = 0; i < 20; i++) {
        await poster.revealNext();
      }
      expect(poster.state.step, 5);
      expect(poster.state.blurSigma, 0.0);
    });
  });

  group('palpites', () {
    Future<PlayNotifier> loadedStage(GameMode mode) async {
      final n = notifierFor(mode);
      expect(await n.loadStageFilm(1, 1, [1, 2, 3]), isTrue);
      return n;
    }

    test('acerto exato ganha com o placar do passo atual', () async {
      final n = await loadedStage(GameMode.clue);
      await n.revealNext();
      expect(await n.submitGuess('Vingadores'), GuessOutcome.correct);
      expect(n.state.session!.status, GameStatus.won);
      expect(n.state.session!.score, 9);
    });

    test('acerto pelo título original também vale', () async {
      final n = await loadedStage(GameMode.clue);
      expect(await n.submitGuess('The Avengers'), GuessOutcome.correct);
    });

    test('acerto sem acento e sem caixa', () async {
      final n = notifierFor(GameMode.clue);
      await n.loadStageFilm(3, 1, [3]);
      expect(await n.submitGuess('coracao valente'), GuessOutcome.correct);
    });

    test('prefixo de franquia NÃO ganha em nenhum dos dois modos', () async {
      for (final mode in GameMode.values) {
        for (final answer in [2, 5]) {
          final n = notifierFor(mode);
          await n.loadStageFilm(answer, 1, [answer]);
          final guess = answer == 2 ? 'Vingadores' : 'Rocky';
          final outcome = await n.submitGuess(guess);
          expect(
            outcome,
            isNot(GuessOutcome.correct),
            reason: 'modo $mode, resposta $answer',
          );
          expect(
            n.state.session!.status,
            GameStatus.playing,
            reason: 'modo $mode, resposta $answer',
          );
        }
      }
    });

    test('a dica de franquia só cobre sequências numeradas', () async {
      final numerada = notifierFor(GameMode.clue);
      await numerada.loadStageFilm(5, 1, [5]);
      expect(await numerada.submitGuess('Rocky'), GuessOutcome.franchise);
      final subtitulada = notifierFor(GameMode.clue);
      await subtitulada.loadStageFilm(2, 1, [2]);
      expect(await subtitulada.submitGuess('Vingadores'), GuessOutcome.wrong);
    });

    test('erro queima o passo seguinte e guarda o palpite', () async {
      final n = await loadedStage(GameMode.clue);
      expect(await n.submitGuess('Titanic'), GuessOutcome.wrong);
      expect(n.state.step, 2);
      expect(n.state.session!.guesses, ['Titanic']);
      expect(n.state.currentScore, 9);
    });

    test('errar no último passo perde a partida', () async {
      final n = await loadedStage(GameMode.clue);
      for (var i = 0; i < 9; i++) {
        await n.revealNext();
      }
      expect(n.state.isOnLastStep, isTrue);
      expect(await n.submitGuess('Titanic'), GuessOutcome.lost);
      expect(n.state.session!.status, GameStatus.lost);
      expect(n.state.session!.score, 0);
    });

    test('poster perde no 5º nível, não no 10º', () async {
      final n = await loadedStage(GameMode.poster);
      for (var i = 0; i < 4; i++) {
        await n.revealNext();
      }
      expect(n.state.step, 5);
      expect(await n.submitGuess('Titanic'), GuessOutcome.lost);
    });

    test('partida encerrada não aceita mais palpite', () async {
      final n = await loadedStage(GameMode.clue);
      await n.submitGuess('Vingadores');
      expect(await n.submitGuess('Titanic'), GuessOutcome.invalid);
    });

    test(
      'guessCount sobe a cada tentativa, mesmo repetindo o desfecho',
      () async {
        final n = notifierFor(GameMode.clue);
        await n.loadStageFilm(5, 1, [5]);
        await n.submitGuess('Rocky');
        final first = n.state.guessCount;
        await n.submitGuess('Rocky');
        expect(n.state.lastGuessOutcome, GuessOutcome.franchise);
        expect(n.state.guessCount, first + 1);
      },
    );
  });

  group('progresso de estágio', () {
    test('vitória marca o filme como concluído no modo certo', () async {
      final n = notifierFor(GameMode.clue);
      await n.loadStageFilm(1, 1, [1, 2, 3]);
      await n.submitGuess('Vingadores');
      final rows = await db.query('stage_progress');
      expect(rows.length, 1);
      expect(rows.single['mode'], 'clue');
      expect(rows.single['movie_id'], 1);
      final poster = notifierFor(GameMode.poster);
      await poster.loadStageFilm(1, 1, [1]);
      expect(poster.state.session!.status, GameStatus.playing);
    });

    test('derrota não marca conclusão', () async {
      final n = notifierFor(GameMode.clue);
      await n.loadStageFilm(1, 1, [1]);
      for (var i = 0; i < 9; i++) {
        await n.revealNext();
      }
      await n.submitGuess('Titanic');
      expect(await db.query('stage_progress'), isEmpty);
    });

    test('reset apaga a sessão e recomeça do passo 1', () async {
      final n = notifierFor(GameMode.clue);
      await n.loadStageFilm(1, 1, [1]);
      await n.revealNext();
      await n.revealNext();
      expect(n.state.step, 3);
      expect(await n.resetStageFilm(1, 1, [1]), isTrue);
      expect(n.state.step, 1);
      expect(n.state.session!.guesses, isEmpty);
      expect(n.state.session!.status, GameStatus.playing);
    });

    test('filme inexistente falha sem iniciar sessão', () async {
      final n = notifierFor(GameMode.clue);
      expect(await n.loadStageFilm(999, 1, [999]), isFalse);
      expect(n.state.error, 'Filme não encontrado');
      expect(await db.query('game_sessions'), isEmpty);
    });
  });
}

class DatabaseSeederForTest {
  const DatabaseSeederForTest();

  Future<void> ensureStages(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stage_progress (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        stage_id INTEGER NOT NULL,
        movie_id INTEGER NOT NULL,
        mode     TEXT    NOT NULL DEFAULT 'clue',
        status   TEXT    NOT NULL DEFAULT 'completed',
        UNIQUE(stage_id, movie_id, mode)
      )
    ''');
  }
}
