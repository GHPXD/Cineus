import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/data/datasources/database_provider.dart';
import 'package:cineus/data/datasources/database_seeder.dart';

/// Hands a ready in-memory SQLite to the repositories under test.
///
/// This is the seam introduced by making the repositories depend on
/// [DatabaseProvider] instead of the concrete `DatabaseHelper` singleton, which
/// needed `getDatabasesPath()` and `rootBundle` and so could never run in a
/// unit test.
class TestDatabaseProvider implements DatabaseProvider {
  final Database db;

  TestDatabaseProvider(this.db);

  @override
  Future<Database> get database async => db;
}

/// Opens an in-memory database with the production schema applied.
Future<Database> openTestDatabase({bool withMovies = false}) async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);

  const seeder = DatabaseSeeder();
  if (withMovies) await seeder.createMoviesSchema(db);
  await seeder.ensureGameSessionsTable(db);
  await seeder.ensureRewardTables(db);
  await seeder.ensureExtraHintsColumn(db);

  return db;
}

/// Creates the legacy (pre-refactor) `game_sessions` table, so migration can be
/// exercised against the shape real installs actually have on disk.
Future<void> createLegacySessionsTable(Database db) async {
  await db.execute('''
    CREATE TABLE game_sessions (
      id             INTEGER PRIMARY KEY AUTOINCREMENT,
      date           TEXT    NOT NULL UNIQUE,
      movie_id       INTEGER NOT NULL,
      revealed_clues INTEGER NOT NULL DEFAULT 1,
      guesses        TEXT    NOT NULL DEFAULT '[]',
      status         TEXT    NOT NULL DEFAULT 'playing',
      score          INTEGER NOT NULL DEFAULT 0
    )
  ''');
}
