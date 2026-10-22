import 'package:sqflite/sqflite.dart';
import '../datasources/database_provider.dart';

/// A stage keeps the contract it had before its first paid game. The migration
/// seeds all existing stages at ten, regardless of a later experiment.
class EconomyRepository {
  final DatabaseProvider database;
  const EconomyRepository(this.database);
  Future<void> ensure(DatabaseExecutor db) async {
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS economy_stage_contracts(
      mode TEXT NOT NULL,stage_id INTEGER NOT NULL,version INTEGER NOT NULL,
      bonus INTEGER NOT NULL CHECK(bonus IN (4,10)),PRIMARY KEY(mode,stage_id))''',
    );
    await db.rawInsert(
      "INSERT OR IGNORE INTO economy_stage_contracts SELECT mode,stage_id,1,10 FROM game_sessions WHERE kind='stage' GROUP BY mode,stage_id",
    );
  }

  Future<int> pin(String mode, int stage, int bonus) async {
    if (!{'clue', 'poster'}.contains(mode) ||
        stage < 1 ||
        !{4, 10}.contains(bonus)) {
      throw ArgumentError('Invalid economy contract');
    }
    final db = await database.database;
    return db.transaction((txn) async {
      await ensure(txn);
      await txn.insert('economy_stage_contracts', {
        'mode': mode,
        'stage_id': stage,
        'version': bonus == 4 ? 2 : 1,
        'bonus': bonus,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return (await txn.query(
            'economy_stage_contracts',
            where: 'mode=? AND stage_id=?',
            whereArgs: [mode, stage],
          )).single['bonus']
          as int;
    });
  }

  Future<int> bonus(String mode, int stage) async {
    final db = await database.database;
    await ensure(db);
    return (await db.query(
              'economy_stage_contracts',
              where: 'mode=? AND stage_id=?',
              whereArgs: [mode, stage],
            )).firstOrNull?['bonus']
            as int? ??
        10;
  }
}
