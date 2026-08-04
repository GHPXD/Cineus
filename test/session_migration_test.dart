// One-time migration from the packed `date` key to explicit columns.
//
// This is the riskiest change in the refactor: it rewrites a table holding the
// player's entire history. These tests start from the exact legacy schema a real
// install has on disk.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/datasources/legacy_session_key.dart';
import 'package:cineus/data/repositories/game_repository_impl.dart';
import 'package:cineus/domain/entities/game_session.dart';

import 'support/test_database.dart';

const seeder = DatabaseSeeder();

void main() {
  group('LegacySessionKey.parse — as quatro formas', () {
    test('diária de dicas', () {
      final k = LegacySessionKey.parse('2026-08-04')!;
      expect(k.mode, GameMode.clue);
      expect(k.kind, SessionKind.daily);
      expect(k.date, '2026-08-04');
      expect(k.stageId, 0);
      expect(k.movieId, isNull);
    });

    test('diária de poster', () {
      final k = LegacySessionKey.parse('visual_2026-08-04')!;
      expect(k.mode, GameMode.poster);
      expect(k.kind, SessionKind.daily);
      expect(k.date, '2026-08-04');
    });

    test('estágio de dicas', () {
      final k = LegacySessionKey.parse('stage_3_27')!;
      expect(k.mode, GameMode.clue);
      expect(k.kind, SessionKind.stage);
      expect(k.stageId, 3);
      expect(k.movieId, 27);
      expect(k.date, '');
    });

    test('estágio de poster — o prefixo mais longo ganha', () {
      // `visual_stage_…` também começa com `visual_`; a ordem de teste importa.
      final k = LegacySessionKey.parse('visual_stage_3_27')!;
      expect(k.mode, GameMode.poster);
      expect(k.kind, SessionKind.stage);
      expect(k.stageId, 3);
      expect(k.movieId, 27);
    });

    test('números de vários dígitos', () {
      final k = LegacySessionKey.parse('visual_stage_50_487')!;
      expect(k.stageId, 50);
      expect(k.movieId, 487);
    });

    test('devolve null para o que não reconhece', () {
      for (final bad in [
        '',
        'lixo',
        '2026-8-4',
        '26-08-04',
        'stage_x_1',
        'stage_1',
        'stage_1_2_3',
        'visual_',
        'visual_lixo',
        'visual_stage_a_b',
      ]) {
        expect(LegacySessionKey.parse(bad), isNull, reason: 'aceitou "$bad"');
      }
    });
  });

  group('migração da tabela', () {
    late Database db;

    setUp(() async {
      sqfliteFfiInit();
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await createLegacySessionsTable(db);
    });

    tearDown(() async => db.close());

    Future<void> insertLegacy(
      String key,
      int movieId, {
      String status = 'won',
      int score = 0,
      int clues = 1,
      String guesses = '[]',
    }) async {
      await db.insert('game_sessions', {
        'date': key,
        'movie_id': movieId,
        'revealed_clues': clues,
        'guesses': guesses,
        'status': status,
        'score': score,
      });
    }

    test('converte as quatro formas para colunas explícitas', () async {
      await insertLegacy('2026-08-04', 11, score: 9, clues: 2);
      await insertLegacy('visual_2026-08-04', 22, score: 4, clues: 2);
      await insertLegacy('stage_3_27', 27, score: 8, clues: 3);
      await insertLegacy('visual_stage_3_27', 27, score: 3, clues: 3);

      await seeder.ensureGameSessionsTable(db);

      final repo = GameRepositoryImpl(TestDatabaseProvider(db));

      final dailyClue = await repo.getDailySession(GameMode.clue, '2026-08-04');
      expect(dailyClue!.movieId, 11);
      expect(dailyClue.score, 9);
      expect(dailyClue.revealedClues, 2);

      final dailyPoster =
          await repo.getDailySession(GameMode.poster, '2026-08-04');
      expect(dailyPoster!.movieId, 22);
      expect(dailyPoster.score, 4);

      final stageClue = await repo.getStageSession(GameMode.clue, 3, 27);
      expect(stageClue!.score, 8);

      final stagePoster = await repo.getStageSession(GameMode.poster, 3, 27);
      expect(stagePoster!.score, 3);
    });

    test('preserva palpites e status', () async {
      await insertLegacy(
        '2026-08-04',
        11,
        status: 'lost',
        clues: 10,
        guesses: '["Titanic","Matrix"]',
      );

      await seeder.ensureGameSessionsTable(db);
      final repo = GameRepositoryImpl(TestDatabaseProvider(db));
      final s = (await repo.getDailySession(GameMode.clue, '2026-08-04'))!;

      expect(s.status, GameStatus.lost);
      expect(s.guesses, ['Titanic', 'Matrix']);
      expect(s.revealedClues, 10);
    });

    test('não perde nenhuma linha reconhecível', () async {
      for (var d = 1; d <= 9; d++) {
        await insertLegacy('2026-08-0$d', d, score: d);
        await insertLegacy('visual_2026-08-0$d', d + 100, score: d);
      }
      for (var stage = 1; stage <= 5; stage++) {
        for (var film = 1; film <= 4; film++) {
          await insertLegacy('stage_${stage}_$film', film);
          await insertLegacy('visual_stage_${stage}_$film', film);
        }
      }
      final antes = (await db.query('game_sessions')).length;
      expect(antes, 9 * 2 + 5 * 4 * 2);

      await seeder.ensureGameSessionsTable(db);

      final depois = (await db.query('game_sessions')).length;
      expect(depois, antes);
      expect(DatabaseSeeder.droppedLegacyKeys, isEmpty);
    });

    test('descarta chaves ilegíveis em vez de chutar o destino', () async {
      await insertLegacy('2026-08-04', 11);
      await insertLegacy('lixo_qualquer', 99);
      await insertLegacy('stage_x_y', 98);

      await seeder.ensureGameSessionsTable(db);

      expect((await db.query('game_sessions')).length, 1);
      expect(
        DatabaseSeeder.droppedLegacyKeys,
        containsAll(['lixo_qualquer', 'stage_x_y']),
      );
    });

    test('é idempotente: rodar de novo não faz nada', () async {
      await insertLegacy('2026-08-04', 11, score: 9);
      await insertLegacy('stage_1_5', 5, score: 7);

      await seeder.ensureGameSessionsTable(db);
      final depoisDaPrimeira = await db.query('game_sessions', orderBy: 'id');

      await seeder.ensureGameSessionsTable(db);
      await seeder.ensureGameSessionsTable(db);

      expect(await db.query('game_sessions', orderBy: 'id'),
          equals(depoisDaPrimeira));
    });

    test('não deixa a tabela temporária para trás', () async {
      await insertLegacy('2026-08-04', 11);
      await seeder.ensureGameSessionsTable(db);

      final tabelas = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'game_sessions%'",
      );
      expect(tabelas.map((t) => t['name']), ['game_sessions']);
    });

    test('instalação nova já nasce no schema novo, sem migração', () async {
      final fresh = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(fresh.close);

      await seeder.ensureGameSessionsTable(fresh);

      final cols = await fresh.rawQuery('PRAGMA table_info(game_sessions)');
      expect(cols.map((c) => c['name']), containsAll(['mode', 'kind', 'stage_id']));
    });

    test('a coluna date passa a conter apenas datas ISO', () async {
      await insertLegacy('2026-08-04', 11);
      await insertLegacy('visual_stage_2_9', 9);

      await seeder.ensureGameSessionsTable(db);

      final dates = (await db.query('game_sessions', columns: ['date']))
          .map((r) => r['date'] as String)
          .toList();
      // estágio guarda string vazia; diária guarda a data
      expect(dates.toSet(), {'2026-08-04', ''});
    });
  });
}
