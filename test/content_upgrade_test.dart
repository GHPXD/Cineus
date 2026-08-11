// Covers the catalogue-upgrade path added for A12.
//
// The rule being protected: refreshing content must never disturb player data.
// Movie ids are stable across exports, which is what makes `stage_progress`
// rows survive; if that ever stops holding, these tests should fail loudly.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/core/constants/app_constants.dart';
import 'package:cineus/data/datasources/database_seeder.dart';

const seeder = DatabaseSeeder();

/// Mirrors the schema of the bundled `assets/cineus_v1.db` (which differs from
/// the web schema: `tmdb_id` is NOT NULL there, and there is a `preview_url`).
const _bundledMoviesSchema = '''
  CREATE TABLE movies (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    tmdb_id        INTEGER UNIQUE NOT NULL,
    title          TEXT NOT NULL,
    original_title TEXT,
    year           INTEGER,
    director       TEXT,
    genres         TEXT,
    poster_path    TEXT,
    overview       TEXT,
    tagline        TEXT,
    runtime        INTEGER,
    created_at     TEXT DEFAULT (datetime('now')),
    preview_url    TEXT DEFAULT NULL
  )
''';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  late Database db;

  Future<void> addMovies(int from, int to) async {
    for (var id = from; id <= to; id++) {
      await db.insert('movies', {
        'id': id,
        'tmdb_id': 90000 + id,
        'title': 'Filme $id',
      });
    }
  }

  setUp(() async {
    db = await factory.openDatabase(inMemoryDatabasePath);
    await db.execute(_bundledMoviesSchema);
    await seeder.ensureGameSessionsTable(db);
  });

  tearDown(() async => db.close());

  group('versionamento de conteúdo', () {
    test('versão instalada começa em 0 e é persistida', () async {
      await seeder.ensureAppMetaTable(db);
      expect(await seeder.readContentVersion(db), 0);

      await seeder.writeContentVersion(db, 7);
      expect(await seeder.readContentVersion(db), 7);

      // idempotente: reescrever não duplica a linha
      await seeder.writeContentVersion(db, 8);
      expect(await seeder.readContentVersion(db), 8);
      final rows = await db.query('app_meta');
      expect(rows.length, 1);
    });

    test('refresh é ignorado quando o conteúdo já está atualizado', () async {
      await addMovies(1, 5);
      await seeder.ensureStagesAndTickets(db);
      await seeder.ensureAppMetaTable(db);
      await seeder.writeContentVersion(db, AppConstants.contentVersion);

      // Retorna false sem tocar no asset — se tentasse ler o JSON aqui,
      // falharia por não haver rootBundle no teste.
      expect(await seeder.refreshContentIfStale(db), isFalse);
    });
  });

  group('refresh a partir do SQLite empacotado', () {
    test('atualiza catálogo sem depender do seed JSON mobile', () async {
      await seeder.ensureStagesAndTickets(db);
      await seeder.ensureAppMetaTable(db);

      await db.execute('''
        CREATE TABLE IF NOT EXISTS clues (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          movie_id INTEGER NOT NULL,
          clue_number INTEGER NOT NULL,
          category TEXT NOT NULL,
          text TEXT NOT NULL
        )
      ''');

      final source = await factory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(source.close);
      await source.execute(_bundledMoviesSchema);
      await source.execute('''
        CREATE TABLE clues (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          movie_id INTEGER NOT NULL,
          clue_number INTEGER NOT NULL,
          category TEXT NOT NULL,
          text TEXT NOT NULL
        )
      ''');
      await source.insert('movies', {
        'id': 42,
        'tmdb_id': 90042,
        'title': 'Catálogo Novo',
      });
      await source.insert('clues', {
        'movie_id': 42,
        'clue_number': 1,
        'category': 'Conceito',
        'text': 'Nova dica',
      });

      expect(
        await seeder.refreshContentFromDatabaseIfStale(db, source),
        isTrue,
      );
      expect(
        (await db.query('movies', where: 'id = 42')).single['title'],
        'Catálogo Novo',
      );
      expect((await db.query('clues', where: 'movie_id = 42')).length, 1);
      expect(await seeder.readContentVersion(db), AppConstants.contentVersion);
    });
  });

  group('syncStages — aditivo, nunca destrutivo', () {
    test('cria estágios em blocos de stageSize', () async {
      await addMovies(1, 25);
      await seeder.ensureStagesAndTickets(db);

      final stages = await db.query('stages', orderBy: 'id ASC');
      expect(stages.length, 3); // 10 + 10 + 5
      expect(
        jsonDecode(stages[0]['film_ids'] as String),
        List.generate(10, (i) => i + 1),
      );
      expect(jsonDecode(stages[2]['film_ids'] as String), [21, 22, 23, 24, 25]);
    });

    test('rodar de novo não altera nada', () async {
      await addMovies(1, 20);
      await seeder.ensureStagesAndTickets(db);
      final before = await db.query('stages', orderBy: 'id ASC');

      await seeder.syncStages(db);
      await seeder.syncStages(db);

      final after = await db.query('stages', orderBy: 'id ASC');
      expect(after, equals(before));
    });

    test('catálogo maior apenas acrescenta estágios novos', () async {
      await addMovies(1, 20);
      await seeder.ensureStagesAndTickets(db);
      final stage1Before = (await db.query(
        'stages',
        where: 'id = 1',
        columns: ['film_ids'],
      )).first['film_ids'];

      await addMovies(21, 40);
      await seeder.syncStages(db);

      final stages = await db.query('stages', orderBy: 'id ASC');
      expect(stages.length, 4);
      // estágios existentes intactos
      expect(stages[0]['film_ids'], stage1Before);
      expect(jsonDecode(stages[3]['film_ids'] as String), [
        31,
        32,
        33,
        34,
        35,
        36,
        37,
        38,
        39,
        40,
      ]);
    });

    test('estágio parcial no fim é estendido, não reembaralhado', () async {
      await addMovies(1, 15); // estágio 2 fica com 5 filmes
      await seeder.ensureStagesAndTickets(db);
      expect(
        jsonDecode(
          (await db.query('stages', where: 'id = 2')).first['film_ids']
              as String,
        ),
        [11, 12, 13, 14, 15],
      );

      await addMovies(16, 20);
      await seeder.syncStages(db);

      expect(
        jsonDecode(
          (await db.query('stages', where: 'id = 2')).first['film_ids']
              as String,
        ),
        [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
        reason: 'o bloco cresceu de forma puramente aditiva',
      );
    });
  });

  group('dados do jogador sobrevivem à atualização de conteúdo', () {
    test('stage_progress, sessões e tickets ficam intactos', () async {
      await addMovies(1, 20);
      await seeder.ensureStagesAndTickets(db);

      // progresso do jogador
      await db.insert('stage_progress', {
        'stage_id': 1,
        'movie_id': 3,
        'mode': 'clue',
        'status': 'completed',
      });
      await db.insert('game_sessions', {
        'mode': 'clue',
        'kind': 'daily',
        'date': '2026-08-10',
        'stage_id': 0,
        'movie_id': 3,
        'revealed_clues': 2,
        'guesses': '[]',
        'status': 'won',
        'score': 9,
      });
      await db.insert('player_tickets', {
        'id': 1,
        'daily_tickets': 7,
        'extra_tickets': 2,
        'last_reset_date': '2026-08-10',
      });

      // chega catálogo maior
      await addMovies(21, 30);
      await seeder.syncStages(db);
      await seeder.ensureStagesAndTickets(db);

      expect(await db.query('stage_progress'), [
        {
          'id': 1,
          'stage_id': 1,
          'movie_id': 3,
          'mode': 'clue',
          'status': 'completed',
        },
      ]);
      final session = (await db.query('game_sessions')).single;
      expect(session['score'], 9);
      expect(session['status'], 'won');

      final tickets = (await db.query('player_tickets')).single;
      expect(tickets['daily_tickets'], 7);
      expect(
        tickets['extra_tickets'],
        2,
        reason: 'ensureStagesAndTickets não pode resetar tickets',
      );
    });
  });

  group('onUpgrade — ensure* são idempotentes', () {
    test('re-executar as migrações não perde dados nem falha', () async {
      await addMovies(1, 10);
      await seeder.ensureStagesAndTickets(db);
      await db.insert('game_sessions', {
        'mode': 'clue',
        'kind': 'daily',
        'date': '2026-08-09',
        'stage_id': 0,
        'movie_id': 1,
        'revealed_clues': 1,
        'guesses': '[]',
        'status': 'lost',
        'score': 0,
      });

      // simula o que _onUpgrade faz
      for (var i = 0; i < 3; i++) {
        await seeder.ensureGameSessionsTable(db);
        await seeder.ensureStagesAndTickets(db);
        await seeder.ensureAppMetaTable(db);
      }

      expect((await db.query('game_sessions')).length, 1);
      expect((await db.query('stages')).length, 1);
    });
  });
}
