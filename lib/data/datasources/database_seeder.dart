import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import 'legacy_session_key.dart';

/// Creates/migrates the local schema and applies versioned catalogue snapshots.
class DatabaseSeeder {
  const DatabaseSeeder();

  /// Logical schema contract shared by Web and mobile. This is intentionally
  /// separate from SQLite `user_version`, because the bundled mobile DB may be
  /// produced outside sqflite and can carry a different physical user_version.
  static const int schemaVersion = 2;

  static const _movieColumns = <String>{
    'id',
    'tmdb_id',
    'title',
    'original_title',
    'year',
    'director',
    'genres',
    'poster_path',
    'overview',
    'tagline',
    'runtime',
  };

  static const _clueColumns = <String>{
    'movie_id',
    'clue_number',
    'category',
    'text',
  };

  /// Canonical content contract shared by Web and mobile.
  ///
  /// The bundled mobile database may contain extra legacy columns
  /// (`created_at`, `preview_url`). Those are deliberately tolerated. What the
  /// app relies on is this common subset plus [is_active].
  Future<void> createMoviesSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS movies (
        id             INTEGER PRIMARY KEY,
        tmdb_id        INTEGER UNIQUE,
        title          TEXT NOT NULL,
        original_title TEXT    DEFAULT '',
        year           INTEGER DEFAULT 0,
        director       TEXT    DEFAULT '',
        genres         TEXT    DEFAULT '',
        poster_path    TEXT    DEFAULT '',
        overview       TEXT    DEFAULT '',
        tagline        TEXT    DEFAULT '',
        runtime        INTEGER DEFAULT 0,
        is_active      INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clues (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        movie_id     INTEGER NOT NULL,
        clue_number  INTEGER NOT NULL CHECK (clue_number BETWEEN 1 AND 10),
        category     TEXT    NOT NULL,
        text         TEXT    NOT NULL,
        UNIQUE (movie_id, clue_number),
        FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clues_movie ON clues(movie_id)',
    );
  }

  /// Adds the additive parts of the canonical content schema to an older asset.
  Future<void> ensureMoviesSchema(Database db) async {
    await createMoviesSchema(db);
    final columns = await db.rawQuery('PRAGMA table_info(movies)');
    if (!columns.any((column) => column['name'] == 'is_active')) {
      await db.execute(
        'ALTER TABLE movies ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1 '
        'CHECK (is_active IN (0, 1))',
      );
    }
  }

  /// Creates `game_sessions`, migrating the legacy single-key layout first.
  Future<void> ensureGameSessionsTable(Database db) async {
    if (await _needsSessionMigration(db)) {
      await _migrateSessionsToExplicitColumns(db);
    }

    await db.execute('''
      CREATE TABLE IF NOT EXISTS game_sessions (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        mode           TEXT    NOT NULL,
        kind           TEXT    NOT NULL,
        date           TEXT    NOT NULL DEFAULT '',
        stage_id       INTEGER NOT NULL DEFAULT 0,
        movie_id       INTEGER NOT NULL,
        revealed_clues INTEGER NOT NULL DEFAULT 1,
        guesses        TEXT    NOT NULL DEFAULT '[]',
        status         TEXT    NOT NULL DEFAULT 'playing',
        score          INTEGER NOT NULL DEFAULT 0,
        extra_hints    TEXT    NOT NULL DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_daily
        ON game_sessions(mode, date) WHERE kind = 'daily'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_stage
        ON game_sessions(mode, stage_id, movie_id) WHERE kind = 'stage'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_challenge
        ON game_sessions(mode, movie_id) WHERE kind = 'challenge'
    ''');
  }

  Future<bool> _needsSessionMigration(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='game_sessions'",
    );
    if (tables.isEmpty) return false;

    final columns = await db.rawQuery('PRAGMA table_info(game_sessions)');
    return !columns.any((column) => column['name'] == 'mode');
  }

  Future<void> _migrateSessionsToExplicitColumns(Database db) async {
    final legacy = await db.query('game_sessions');
    droppedLegacyKeys.clear();

    await db.transaction((txn) async {
      await txn.execute('DROP TABLE IF EXISTS game_sessions_legacy');
      await txn.execute(
        'ALTER TABLE game_sessions RENAME TO game_sessions_legacy',
      );
      await txn.execute('''
        CREATE TABLE game_sessions (
          id             INTEGER PRIMARY KEY AUTOINCREMENT,
          mode           TEXT    NOT NULL,
          kind           TEXT    NOT NULL,
          date           TEXT    NOT NULL DEFAULT '',
          stage_id       INTEGER NOT NULL DEFAULT 0,
          movie_id       INTEGER NOT NULL,
          revealed_clues INTEGER NOT NULL DEFAULT 1,
          guesses        TEXT    NOT NULL DEFAULT '[]',
          status         TEXT    NOT NULL DEFAULT 'playing',
          score          INTEGER NOT NULL DEFAULT 0,
          extra_hints    TEXT    NOT NULL DEFAULT '[]'
        )
      ''');

      final batch = txn.batch();
      for (final row in legacy) {
        final key = row['date'] as String?;
        if (key == null) continue;
        final parsed = LegacySessionKey.parse(key);
        if (parsed == null) {
          droppedLegacyKeys.add(key);
          continue;
        }

        batch.insert('game_sessions', {
          'mode': parsed.mode.name,
          'kind': parsed.kind.name,
          'date': parsed.date,
          'stage_id': parsed.stageId,
          'movie_id': parsed.movieId ?? row['movie_id'],
          'revealed_clues': row['revealed_clues'] ?? 1,
          'guesses': row['guesses'] ?? '[]',
          'status': row['status'] ?? 'playing',
          'score': row['score'] ?? 0,
        });
      }
      await batch.commit(noResult: true);
      await txn.execute('DROP TABLE game_sessions_legacy');
    });
  }

  /// Legacy keys the last migration could not interpret.
  static final List<String> droppedLegacyKeys = [];

  Future<void> ensureStagesAndTickets(Database db) async {
    // Some tests and old installs reach stage migration directly. Ensure the
    // content contract first so `syncStages()` can safely rely on is_active.
    await ensureMoviesSchema(db);

    await db.execute('''
      CREATE TABLE IF NOT EXISTS player_tickets (
        id               INTEGER PRIMARY KEY,
        daily_tickets    INTEGER NOT NULL DEFAULT 20,
        extra_tickets    INTEGER NOT NULL DEFAULT 0,
        last_reset_date  TEXT    NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stages (
        id          INTEGER PRIMARY KEY,
        order_index INTEGER NOT NULL,
        name        TEXT    NOT NULL,
        film_ids    TEXT    NOT NULL
      )
    ''');

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

    final progressColumns = await db.rawQuery('PRAGMA table_info(stage_progress)');
    if (!progressColumns.any((column) => column['name'] == 'mode')) {
      await db.execute(
        "ALTER TABLE stage_progress ADD COLUMN mode TEXT NOT NULL DEFAULT 'clue'",
      );
    }

    await syncStages(db);
  }

  Future<void> ensureRewardTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ticket_rewards (
        key        TEXT    PRIMARY KEY,
        amount     INTEGER NOT NULL,
        awarded_at TEXT    NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS streak_freezes (
        date       TEXT PRIMARY KEY,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> ensureExtraHintsColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(game_sessions)');
    if (columns.any((column) => column['name'] == 'extra_hints')) return;
    await db.execute(
      "ALTER TABLE game_sessions ADD COLUMN extra_hints TEXT NOT NULL DEFAULT '[]'",
    );
  }

  /// Applies every additive schema migration and records the logical version.
  Future<void> ensureCanonicalSchema(Database db) async {
    await ensureMoviesSchema(db);
    await ensureGameSessionsTable(db);
    await ensureStagesAndTickets(db);
    await ensureRewardTables(db);
    await ensureExtraHintsColumn(db);
    await ensureAppMetaTable(db);
    await writeSchemaVersion(db, schemaVersion);
  }

  // ── Generic key/value flags ────────────────────────────────────────────────

  Future<void> ensureAppMetaTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<String?> readMeta(DatabaseExecutor db, String key) async {
    await ensureAppMetaTable(db);
    final rows = await db.query(
      'app_meta',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> writeMeta(
    DatabaseExecutor db,
    String key,
    String value,
  ) async {
    await ensureAppMetaTable(db);
    await db.insert(
      'app_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> readSchemaVersion(DatabaseExecutor db) async {
    final raw = await readMeta(db, 'schema_version');
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> writeSchemaVersion(DatabaseExecutor db, int version) =>
      writeMeta(db, 'schema_version', '$version');

  // ── Catalogue snapshot ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadSeedAsset() async {
    final jsonString =
        await rootBundle.loadString('assets/cineus_v1_seed.json');
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Catalogue seed must be a JSON object');
    }
    validateContentSnapshot(decoded);
    return decoded;
  }

  /// Fails before any write when the snapshot cannot satisfy game invariants.
  void validateContentSnapshot(Map<String, dynamic> data) {
    final movies = _mapRows(data, 'movies');
    final clues = _mapRows(data, 'clues');
    if (movies.isEmpty) {
      throw const FormatException('Catalogue must contain at least one movie');
    }

    final movieIds = <int>{};
    final tmdbIds = <int>{};
    for (final movie in movies) {
      final id = movie['id'];
      final title = movie['title'];
      if (id is! int || id <= 0 || !movieIds.add(id)) {
        throw FormatException('Invalid or duplicate movie id: $id');
      }
      if (title is! String || title.trim().isEmpty) {
        throw FormatException('Movie $id has no title');
      }
      final tmdbId = movie['tmdb_id'];
      if (tmdbId != null) {
        if (tmdbId is! int || tmdbId <= 0 || !tmdbIds.add(tmdbId)) {
          throw FormatException('Invalid or duplicate tmdb_id: $tmdbId');
        }
      }
    }

    final clueKeys = <String>{};
    final clueCounts = <int, int>{};
    for (final clue in clues) {
      final movieId = clue['movie_id'];
      final number = clue['clue_number'];
      final category = clue['category'];
      final text = clue['text'];
      if (movieId is! int || !movieIds.contains(movieId)) {
        throw FormatException('Clue references unknown movie: $movieId');
      }
      if (number is! int ||
          number < 1 ||
          number > AppConstants.totalClues) {
        throw FormatException('Invalid clue number $number for movie $movieId');
      }
      if (!clueKeys.add('$movieId:$number')) {
        throw FormatException('Duplicate clue $number for movie $movieId');
      }
      if (category is! String || category.trim().isEmpty) {
        throw FormatException('Clue $movieId:$number has no category');
      }
      if (text is! String || text.trim().isEmpty) {
        throw FormatException('Clue $movieId:$number has no text');
      }
      clueCounts[movieId] = (clueCounts[movieId] ?? 0) + 1;
    }

    for (final id in movieIds) {
      if (clueCounts[id] != AppConstants.totalClues) {
        throw FormatException(
          'Movie $id must have exactly ${AppConstants.totalClues} clues',
        );
      }
    }
  }

  static List<Map<String, dynamic>> _mapRows(
    Map<String, dynamic> data,
    String key,
  ) {
    final raw = data[key];
    if (raw is! List) {
      throw FormatException('Catalogue field "$key" must be a list');
    }
    return raw.map((row) {
      if (row is! Map) {
        throw FormatException('Catalogue field "$key" contains a non-object');
      }
      return Map<String, dynamic>.from(row);
    }).toList(growable: false);
  }

  /// Reads the bundled JSON and inserts it into an empty/new database.
  Future<void> seedFromJsonAsset(DatabaseExecutor db) async {
    final data = await loadSeedAsset();
    await applyContentSnapshot(db, data, deactivateMissing: false);
  }

  /// Applies a validated content snapshot without replacing movie rows.
  ///
  /// IDs are append-only. A movie omitted by a newer snapshot is soft-retired
  /// (`is_active = 0`) rather than deleted, preserving historical sessions and
  /// stage references. Existing IDs are updated in-place; this deliberately
  /// avoids SQLite `INSERT OR REPLACE`, which deletes the previous row first.
  Future<void> applyContentSnapshot(
    DatabaseExecutor db,
    Map<String, dynamic> data, {
    required bool deactivateMissing,
  }) async {
    validateContentSnapshot(data);
    final movies = _mapRows(data, 'movies');
    final clues = _mapRows(data, 'clues');

    final existingRows = await db.query(
      'movies',
      columns: ['id', 'tmdb_id'],
    );
    final existingTmdbById = <int, int?>{
      for (final row in existingRows)
        row['id'] as int: row['tmdb_id'] as int?,
    };
    final existingIds = existingTmdbById.keys.toSet();

    // An ID is permanent once shipped. A changed tmdb_id under the same id
    // means the catalogue is trying to reuse a historical identity.
    final resolvedTmdbById = <int, int>{};
    for (final movie in movies) {
      final id = movie['id'] as int;
      final previousTmdb = existingTmdbById[id];
      final incomingTmdb = movie['tmdb_id'] as int?;
      if (previousTmdb != null &&
          incomingTmdb != null &&
          previousTmdb != incomingTmdb) {
        throw StateError(
          'Movie id $id is stable and cannot change tmdb_id '
          'from $previousTmdb to $incomingTmdb',
        );
      }
      final resolvedTmdb = incomingTmdb ?? previousTmdb;
      if (resolvedTmdb == null) {
        throw FormatException('New movie $id must include tmdb_id');
      }
      resolvedTmdbById[id] = resolvedTmdb;
    }

    if (deactivateMissing) {
      await db.update('movies', {'is_active': 0});
    }

    // Use UPDATE/INSERT rather than modern SQLite UPSERT syntax. Cineus still
    // supports Android API 24 devices whose platform SQLite can predate 3.24.
    const chunkSize = 100;
    for (var i = 0; i < movies.length; i += chunkSize) {
      final batch = db.batch();
      final chunk = movies.sublist(i, (i + chunkSize).clamp(0, movies.length));
      for (final movie in chunk) {
        final row = <String, dynamic>{
          for (final entry in movie.entries)
            if (_movieColumns.contains(entry.key)) entry.key: entry.value,
        };
        final id = row['id'] as int;
        final values = <String, dynamic>{
          'tmdb_id': resolvedTmdbById[id],
          'title': row['title'],
          'original_title': row['original_title'] ?? '',
          'year': row['year'] ?? 0,
          'director': row['director'] ?? '',
          'genres': row['genres'] ?? '',
          'poster_path': row['poster_path'] ?? '',
          'overview': row['overview'] ?? '',
          'tagline': row['tagline'] ?? '',
          'runtime': row['runtime'] ?? 0,
          'is_active': 1,
        };

        if (existingIds.contains(id)) {
          batch.update(
            'movies',
            values,
            where: 'id = ?',
            whereArgs: [id],
          );
        } else {
          batch.insert(
            'movies',
            {'id': id, ...values},
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      }
      await batch.commit(noResult: true);
    }

    // Clues have no external identity in player data. Replacing the exact clue
    // set for snapshot movies prevents stale clue numbers from surviving a
    // content correction while keeping retired movies readable historically.
    final movieIds = movies.map((movie) => movie['id'] as int).toList();
    for (var i = 0; i < movieIds.length; i += 500) {
      final ids = movieIds.sublist(i, (i + 500).clamp(0, movieIds.length));
      await db.delete(
        'clues',
        where: 'movie_id IN (${List.filled(ids.length, '?').join(',')})',
        whereArgs: ids,
      );
    }

    for (var i = 0; i < clues.length; i += chunkSize) {
      final batch = db.batch();
      final chunk = clues.sublist(i, (i + chunkSize).clamp(0, clues.length));
      for (final clue in chunk) {
        final row = <String, dynamic>{
          for (final entry in clue.entries)
            if (_clueColumns.contains(entry.key)) entry.key: entry.value,
        };
        batch.insert('clues', row, conflictAlgorithm: ConflictAlgorithm.abort);
      }
      await batch.commit(noResult: true);
    }
  }

  // ── Content versioning ────────────────────────────────────────────────────

  Future<int> readContentVersion(DatabaseExecutor db) async {
    final raw = await readMeta(db, 'content_version');
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> writeContentVersion(DatabaseExecutor db, int version) =>
      writeMeta(db, 'content_version', '$version');

  /// Applies one complete catalogue upgrade atomically.
  Future<void> applyContentUpgrade(
    Database db,
    Map<String, dynamic> data, {
    required int targetVersion,
  }) async {
    // Validate once before beginning any write at all.
    validateContentSnapshot(data);
    await db.transaction((txn) async {
      await applyContentSnapshot(txn, data, deactivateMissing: true);
      await syncStages(txn);
      await writeContentVersion(txn, targetVersion);
    });
  }

  /// Refreshes content, stage assignment and content version in one transaction.
  Future<bool> refreshContentIfStale(Database db) async {
    await ensureAppMetaTable(db);
    final installed = await readContentVersion(db);
    if (installed >= AppConstants.contentVersion) return false;

    // Decode + validate before starting the transaction so malformed shipped
    // assets cannot touch a healthy player's database at all.
    final data = await loadSeedAsset();
    await applyContentUpgrade(
      db,
      data,
      targetVersion: AppConstants.contentVersion,
    );
    return true;
  }

  /// Keeps stage membership append-only.
  ///
  /// Existing stage lists are never rebuilt, even if a movie is later retired.
  /// Newly active, never-assigned movie IDs first fill the trailing partial
  /// stage, then create new stages. This prevents catalogue removals from
  /// shifting boundaries and duplicating films in future stages.
  Future<void> syncStages(DatabaseExecutor db) async {
    final activeRows = await db.query(
      'movies',
      columns: ['id'],
      where: 'is_active = 1',
      orderBy: 'id ASC',
    );
    final activeIds = activeRows.map((row) => row['id'] as int).toList();

    final storedRows = await db.query(
      'stages',
      columns: ['id', 'film_ids'],
      orderBy: 'order_index ASC, id ASC',
    );

    final assigned = <int>{};
    final stageIds = <int>[];
    final stageMovies = <int, List<int>>{};
    for (final row in storedRows) {
      final id = row['id'] as int;
      final filmIds = (jsonDecode(row['film_ids'] as String) as List).cast<int>();
      assigned.addAll(filmIds);
      stageIds.add(id);
      stageMovies[id] = filmIds;
    }

    final unassigned = activeIds.where((id) => !assigned.contains(id)).toList();
    if (unassigned.isEmpty) return;

    const stageSize = AppConstants.stageSize;
    var cursor = 0;
    final batch = db.batch();

    var nextStageId = 1;
    if (stageIds.isNotEmpty) {
      final lastId = stageIds.last;
      final lastMovies = stageMovies[lastId]!;
      nextStageId = stageIds.reduce((a, b) => a > b ? a : b) + 1;
      final room = stageSize - lastMovies.length;
      if (room > 0) {
        final take = room < unassigned.length ? room : unassigned.length;
        final extended = [...lastMovies, ...unassigned.take(take)];
        batch.update(
          'stages',
          {'film_ids': jsonEncode(extended)},
          where: 'id = ?',
          whereArgs: [lastId],
        );
        cursor += take;
      }
    }

    while (cursor < unassigned.length) {
      final end = (cursor + stageSize).clamp(0, unassigned.length);
      final chunk = unassigned.sublist(cursor, end);
      batch.insert(
        'stages',
        {
          'id': nextStageId,
          'order_index': nextStageId,
          'name': 'Estágio $nextStageId',
          'film_ids': jsonEncode(chunk),
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      nextStageId++;
      cursor = end;
    }

    await batch.commit(noResult: true);
  }
}
