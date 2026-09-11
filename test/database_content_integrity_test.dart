import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/data/datasources/database_seeder.dart';
import 'package:cineus/data/repositories/movie_repository_impl.dart';

import 'support/test_database.dart';

const seeder = DatabaseSeeder();

Map<String, dynamic> movie(int id, {int? tmdbId, String? title}) => {
      'id': id,
      'tmdb_id': tmdbId ?? 10000 + id,
      'title': title ?? 'Filme $id',
      'original_title': title ?? 'Movie $id',
      'year': 2000 + id,
      'director': 'Diretor $id',
      'genres': 'Drama',
      'poster_path': '/$id.jpg',
      'overview': 'Overview $id',
      'tagline': 'Tagline $id',
      'runtime': 90 + id,
    };

List<Map<String, dynamic>> cluesFor(int movieId) => List.generate(
      10,
      (index) => {
        'movie_id': movieId,
        'clue_number': index + 1,
        'category': 'Conceito',
        'text': 'Dica ${index + 1} do filme $movieId',
      },
    );

Map<String, dynamic> snapshot(List<Map<String, dynamic>> movies) => {
      'movies': movies,
      'clues': [
        for (final item in movies) ...cluesFor(item['id'] as int),
      ],
    };

void main() {
  sqfliteFfiInit();
  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await seeder.createMoviesSchema(db);
    await seeder.ensureGameSessionsTable(db);
    await seeder.ensureStagesAndTickets(db);
    await seeder.ensureRewardTables(db);
    await seeder.ensureAppMetaTable(db);
  });

  tearDown(() async => db.close());

  test('schema canônico adiciona is_active a um asset mobile antigo', () async {
    final legacy = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(legacy.close);
    await legacy.execute('''
      CREATE TABLE movies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tmdb_id INTEGER UNIQUE NOT NULL,
        title TEXT NOT NULL,
        original_title TEXT,
        year INTEGER,
        director TEXT,
        genres TEXT,
        poster_path TEXT,
        overview TEXT,
        tagline TEXT,
        runtime INTEGER,
        created_at TEXT,
        preview_url TEXT
      )
    ''');
    await legacy.execute('''
      CREATE TABLE clues (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        movie_id INTEGER NOT NULL,
        clue_number INTEGER NOT NULL,
        category TEXT NOT NULL,
        text TEXT NOT NULL,
        UNIQUE(movie_id, clue_number),
        FOREIGN KEY(movie_id) REFERENCES movies(id) ON DELETE CASCADE
      )
    ''');
    await legacy.insert('movies', {
      'id': 1,
      'tmdb_id': 101,
      'title': 'Legado',
      'preview_url': 'https://example.invalid/legacy',
    });

    await seeder.ensureMoviesSchema(legacy);

    final columns = await legacy.rawQuery('PRAGMA table_info(movies)');
    expect(columns.any((column) => column['name'] == 'is_active'), isTrue);
    final row = (await legacy.query('movies')).single;
    expect(row['is_active'], 1);
    expect(row['preview_url'], 'https://example.invalid/legacy',
        reason: 'colunas extras do asset mobile devem continuar intactas');
  });

  test('foreign keys ficam realmente ativos e cascade remove clues', () async {
    final flag = await db.rawQuery('PRAGMA foreign_keys');
    expect(flag.single.values.single, 1);

    await db.insert('movies', movie(1));
    for (final clue in cluesFor(1)) {
      await db.insert('clues', clue);
    }
    expect((await db.query('clues')).length, 10);

    await db.delete('movies', where: 'id = 1');
    expect(await db.query('clues'), isEmpty);
  });

  test('snapshot inválido é recusado antes de alterar qualquer conteúdo', () async {
    await seeder.applyContentUpgrade(
      db,
      snapshot([movie(1)]),
      targetVersion: 1,
    );

    final beforeMovies = await db.query('movies', orderBy: 'id');
    final beforeClues = await db.query('clues', orderBy: 'movie_id, clue_number');

    final invalid = snapshot([movie(1), movie(2)]);
    (invalid['clues'] as List).removeLast();

    expect(
      () => seeder.applyContentUpgrade(db, invalid, targetVersion: 2),
      throwsFormatException,
    );

    expect(await db.query('movies', orderBy: 'id'), beforeMovies);
    expect(await db.query('clues', orderBy: 'movie_id, clue_number'), beforeClues);
    expect(await seeder.readContentVersion(db), 1);
  });

  test('falha no meio do upgrade faz rollback de conteúdo, stages e versão',
      () async {
    await seeder.applyContentUpgrade(
      db,
      snapshot([movie(1, tmdbId: 101), movie(2, tmdbId: 202)]),
      targetVersion: 1,
    );
    final stagesBefore = await db.query('stages', orderBy: 'id');

    // Movie 3 tries to claim the tmdb_id already owned by historical movie 2.
    // Validation of the incoming snapshot passes; SQLite fails only after the
    // transaction has already marked old rows inactive, exercising real rollback.
    final conflicting = snapshot([
      movie(1, tmdbId: 101),
      movie(3, tmdbId: 202),
    ]);

    expect(
      () => seeder.applyContentUpgrade(db, conflicting, targetVersion: 2),
      throwsA(anything),
    );

    final rows = await db.query('movies', orderBy: 'id');
    expect(rows.map((row) => row['id']).toList(), [1, 2]);
    expect(rows.map((row) => row['is_active']).toList(), [1, 1],
        reason: 'deactivateMissing também precisa ser revertido');
    expect(await db.query('stages', orderBy: 'id'), stagesBefore);
    expect(await seeder.readContentVersion(db), 1);
  });

  test('ID de filme publicado nunca pode apontar para outro tmdb_id', () async {
    await seeder.applyContentUpgrade(
      db,
      snapshot([movie(7, tmdbId: 7007)]),
      targetVersion: 1,
    );

    expect(
      () => seeder.applyContentUpgrade(
        db,
        snapshot([movie(7, tmdbId: 9999)]),
        targetVersion: 2,
      ),
      throwsStateError,
    );

    final stored = (await db.query('movies', where: 'id = 7')).single;
    expect(stored['tmdb_id'], 7007);
    expect(await seeder.readContentVersion(db), 1);
  });

  test('filme removido é aposentado sem quebrar histórico ou stages', () async {
    await seeder.applyContentUpgrade(
      db,
      snapshot([movie(1), movie(2)]),
      targetVersion: 1,
    );
    expect(
      jsonDecode((await db.query('stages')).single['film_ids'] as String),
      [1, 2],
    );

    await seeder.applyContentUpgrade(
      db,
      snapshot([movie(2, title: 'Filme Dois'), movie(3)]),
      targetVersion: 2,
    );

    final all = await db.query('movies', orderBy: 'id');
    expect(all.map((row) => row['id']).toList(), [1, 2, 3]);
    expect(all.first['is_active'], 0);

    final stage = (await db.query('stages')).single;
    expect(jsonDecode(stage['film_ids'] as String), [1, 2, 3],
        reason: 'membership existente é append-only e não muda de posição');

    final repo = MovieRepositoryImpl(TestDatabaseProvider(db));
    expect(await repo.getMovieIds(), [2, 3]);
    expect(await repo.getMovieCount(), 2);
    expect(await repo.getMovieById(1), isNotNull,
        reason: 'sessões antigas ainda precisam resolver o filme aposentado');
    expect(
      (await repo.searchMovies('Filme 1')).map((item) => item.id),
      isNot(contains(1)),
    );
  });

  test('movie novo sem tmdb_id é rejeitado, legado existente pode herdá-lo',
      () async {
    await seeder.applyContentUpgrade(
      db,
      snapshot([movie(1, tmdbId: 101)]),
      targetVersion: 1,
    );

    final existingWithoutTmdbInSnapshot = snapshot([movie(1, tmdbId: 101)]);
    (existingWithoutTmdbInSnapshot['movies'] as List).first.remove('tmdb_id');
    await seeder.applyContentUpgrade(
      db,
      existingWithoutTmdbInSnapshot,
      targetVersion: 2,
    );
    expect((await db.query('movies')).single['tmdb_id'], 101);

    final newWithoutTmdb = snapshot([movie(2)]);
    (newWithoutTmdb['movies'] as List).first.remove('tmdb_id');
    expect(
      () => seeder.applyContentUpgrade(db, newWithoutTmdb, targetVersion: 3),
      throwsFormatException,
    );
    expect(await seeder.readContentVersion(db), 2);
  });
}
