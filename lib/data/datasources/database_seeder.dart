import 'dart:convert';

import 'package:flutter/services.dart' show NetworkAssetBundle;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import 'legacy_session_key.dart';

/// Responsible for creating database schema and seeding initial data.
/// Extracted from DatabaseHelper to satisfy Single Responsibility Principle.
class DatabaseSeeder {
  const DatabaseSeeder();

  /// Creates the movies and clues schema.
  Future<void> createMoviesSchema(Database db) async {
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
        runtime        INTEGER DEFAULT 0
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

  /// Creates `game_sessions`, migrating the legacy single-key layout first.
  ///
  /// The migration detects itself by inspecting the columns rather than relying
  /// on `onUpgrade`: on mobile the database file is copied from a
  /// Python-generated asset whose `user_version` is not under our control, so
  /// sqflite's version callbacks are not a dependable trigger here. Checking for
  /// the `mode` column costs one PRAGMA per launch and cannot misfire.
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

    // Partial unique indexes: one daily session per (mode, date), one stage
    // session per (mode, stage, film). A plain UNIQUE across all five columns
    // would not work — `date`/`stage_id` use sentinel values precisely because
    // SQLite treats NULLs as distinct and would let duplicates through.
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_daily
        ON game_sessions(mode, date) WHERE kind = 'daily'
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_stage
        ON game_sessions(mode, stage_id, movie_id) WHERE kind = 'stage'
    ''');
    // One challenge session per (mode, film), regardless of who sent it.
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_challenge
        ON game_sessions(mode, movie_id) WHERE kind = 'challenge'
    ''');
  }

  /// True when a `game_sessions` table exists but predates the `mode` column.
  Future<bool> _needsSessionMigration(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='game_sessions'",
    );
    if (tables.isEmpty) return false;

    final columns = await db.rawQuery('PRAGMA table_info(game_sessions)');
    return !columns.any((c) => c['name'] == 'mode');
  }

  /// Rewrites legacy rows into the explicit-column layout.
  ///
  /// Runs as one transaction: either every recognisable session carries over or
  /// nothing changes. Rows whose key matches none of the four legacy shapes are
  /// dropped rather than guessed at — [droppedLegacyKeys] records them.
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
          // For stage keys the film id is in the key itself; trust it over the
          // column, which is what the key was built from anyway.
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

  /// Legacy keys the last migration could not interpret. Empty in practice;
  /// exposed so tests can assert nothing was silently discarded.
  static final List<String> droppedLegacyKeys = [];

  /// Creates stages, stage_progress and player_tickets tables.
  /// Seeds stages from movie IDs if the table is empty.
  Future<void> ensureStagesAndTickets(Database db) async {
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

    // Add mode column to existing installations that lack it.
    try {
      await db.execute(
        "ALTER TABLE stage_progress ADD COLUMN mode TEXT NOT NULL DEFAULT 'clue'",
      );
    } catch (_) {
      // Column already exists — safe to ignore.
    }

    await syncStages(db);
  }

  /// Tables backing the ticket economy: which rewards were already handed out,
  /// and which missed days the player paid to keep their streak alive.
  Future<void> ensureRewardTables(Database db) async {
    // Keyed by a deterministic reward id (`stage_clue_3`, `streak_14`, …), which
    // is what makes granting idempotent — a reward can never pay twice.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ticket_rewards (
        key        TEXT    PRIMARY KEY,
        amount     INTEGER NOT NULL,
        awarded_at TEXT    NOT NULL
      )
    ''');

    // A frozen day counts as "not a gap" when computing the streak, without
    // inventing a win the player never earned.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS streak_freezes (
        date       TEXT PRIMARY KEY,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Extra hints bought with tickets, stored per session.
  Future<void> ensureExtraHintsColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(game_sessions)');
    if (columns.any((c) => c['name'] == 'extra_hints')) return;
    await db.execute(
      "ALTER TABLE game_sessions ADD COLUMN extra_hints TEXT NOT NULL DEFAULT '[]'",
    );
  }

  // ── Generic key/value flags ────────────────────────────────────────────────

  Future<String?> readMeta(Database db, String key) async {
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

  Future<void> writeMeta(Database db, String key, String value) async {
    await ensureAppMetaTable(db);
    await db.insert('app_meta', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Reads the web-only seed JSON and batch-inserts all rows.
  ///
  /// [conflict] is `ignore` for first-time seeding and `replace` when refreshing
  /// an existing install to a newer catalogue.
  Future<void> seedFromJsonAsset(
    DatabaseExecutor db, {
    ConflictAlgorithm conflict = ConflictAlgorithm.ignore,
  }) async {
    final jsonStr = await NetworkAssetBundle(
      Uri.base,
    ).loadString('cineus_v1_seed.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    final movies = (data['movies'] as List).cast<Map<String, dynamic>>();
    final clues = (data['clues'] as List).cast<Map<String, dynamic>>();

    const movieCols = {
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
    const clueCols = {'id', 'movie_id', 'clue_number', 'category', 'text'};

    const chunkSize = 100;

    // Movies before clues: `replace` deletes the conflicting movie row first,
    // which cascades to its clues when foreign keys are enforced. The clue pass
    // then restores them. Callers wrap this in a transaction so a failure can
    // never leave movies without clues.
    for (var i = 0; i < movies.length; i += chunkSize) {
      final batch = db.batch();
      for (final m in movies.sublist(
        i,
        (i + chunkSize).clamp(0, movies.length),
      )) {
        final row = {
          for (final e in m.entries)
            if (movieCols.contains(e.key)) e.key: e.value,
        };
        batch.insert('movies', row, conflictAlgorithm: conflict);
      }
      await batch.commit(noResult: true);
    }

    for (var i = 0; i < clues.length; i += chunkSize) {
      final batch = db.batch();
      for (final c in clues.sublist(
        i,
        (i + chunkSize).clamp(0, clues.length),
      )) {
        final row = {
          for (final e in c.entries)
            if (clueCols.contains(e.key)) e.key: e.value,
        };
        batch.insert('clues', row, conflictAlgorithm: conflict);
      }
      await batch.commit(noResult: true);
    }
  }

  /// Copies catalogue rows from another SQLite database into [db].
  ///
  /// Mobile uses the bundled `cineus_v1.db` as the source for content upgrades,
  /// so the 1.2 MB JSON seed can remain web-only instead of inflating the APK.
  Future<void> seedFromDatabase(
    DatabaseExecutor db,
    Database source, {
    ConflictAlgorithm conflict = ConflictAlgorithm.replace,
  }) async {
    final movies = await source.query('movies');
    final clues = await source.query('clues');

    const movieCols = {
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
    const clueCols = {'id', 'movie_id', 'clue_number', 'category', 'text'};
    const chunkSize = 100;

    for (var i = 0; i < movies.length; i += chunkSize) {
      final batch = db.batch();
      for (final m in movies.sublist(
        i,
        (i + chunkSize).clamp(0, movies.length),
      )) {
        batch.insert('movies', {
          for (final e in m.entries)
            if (movieCols.contains(e.key)) e.key: e.value,
        }, conflictAlgorithm: conflict);
      }
      await batch.commit(noResult: true);
    }

    for (var i = 0; i < clues.length; i += chunkSize) {
      final batch = db.batch();
      for (final c in clues.sublist(
        i,
        (i + chunkSize).clamp(0, clues.length),
      )) {
        batch.insert('clues', {
          for (final e in c.entries)
            if (clueCols.contains(e.key)) e.key: e.value,
        }, conflictAlgorithm: conflict);
      }
      await batch.commit(noResult: true);
    }
  }

  // ── Content versioning ─────────────────────────────────────────────────────

  /// Key/value table holding the installed catalogue version.
  Future<void> ensureAppMetaTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<int> readContentVersion(Database db) async {
    final raw = await readMeta(db, 'content_version');
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<void> writeContentVersion(Database db, int version) =>
      writeMeta(db, 'content_version', '$version');

  /// Brings the catalogue up to [AppConstants.contentVersion] when the installed
  /// copy is older, then extends the stage list to cover any new movies.
  ///
  /// Only content tables are touched. `game_sessions`, `stage_progress` and
  /// `player_tickets` are never rewritten, so progress survives a catalogue
  /// update. Movie ids are stable across exports, which is what keeps
  /// `stage_progress` rows meaningful.
  Future<bool> refreshContentIfStale(Database db) async {
    await ensureAppMetaTable(db);
    final installed = await readContentVersion(db);
    if (installed >= AppConstants.contentVersion) return false;

    await db.transaction((txn) async {
      await seedFromJsonAsset(txn, conflict: ConflictAlgorithm.replace);
    });
    await syncStages(db);
    await writeContentVersion(db, AppConstants.contentVersion);
    return true;
  }

  /// Mobile counterpart to [refreshContentIfStale], using the bundled SQLite
  /// catalogue as source instead of the web JSON seed.
  Future<bool> refreshContentFromDatabaseIfStale(
    Database db,
    Database source,
  ) async {
    await ensureAppMetaTable(db);
    final installed = await readContentVersion(db);
    if (installed >= AppConstants.contentVersion) return false;

    await db.transaction((txn) async {
      await seedFromDatabase(txn, source);
    });
    await syncStages(db);
    await writeContentVersion(db, AppConstants.contentVersion);
    return true;
  }

  /// Groups all movie IDs into buckets of [AppConstants.stageSize], adding only
  /// what is missing.
  ///
  /// Safe to run on every launch. An existing stage is never reshuffled — a
  /// player may already have `stage_progress` rows pointing at it. The single
  /// exception is a trailing partial stage that grew (e.g. it held 5 movies and
  /// the catalogue now supplies 10 for that bucket): it is extended, which is
  /// purely additive, so recorded progress stays valid.
  Future<void> syncStages(Database db) async {
    final rows = await db.query('movies', columns: ['id'], orderBy: 'id ASC');
    final ids = rows.map((r) => r['id'] as int).toList();

    final storedRows = await db.query('stages', columns: ['id', 'film_ids']);
    final stored = <int, List<int>>{
      for (final r in storedRows)
        r['id'] as int: (jsonDecode(r['film_ids'] as String) as List)
            .cast<int>(),
    };

    const stageSize = AppConstants.stageSize;
    final batch = db.batch();

    for (var i = 0; i < ids.length; i += stageSize) {
      final stageNum = (i ~/ stageSize) + 1;
      final chunk = ids.sublist(i, (i + stageSize).clamp(0, ids.length));
      final current = stored[stageNum];

      if (current == null) {
        batch.insert('stages', {
          'id': stageNum,
          'order_index': stageNum,
          'name': 'Estágio $stageNum',
          'film_ids': jsonEncode(chunk),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } else if (current.length < chunk.length && _isPrefix(current, chunk)) {
        batch.update(
          'stages',
          {'film_ids': jsonEncode(chunk)},
          where: 'id = ?',
          whereArgs: [stageNum],
        );
      }
    }

    await batch.commit(noResult: true);
  }

  static bool _isPrefix(List<int> shorter, List<int> longer) {
    for (var i = 0; i < shorter.length; i++) {
      if (shorter[i] != longer[i]) return false;
    }
    return true;
  }
}
