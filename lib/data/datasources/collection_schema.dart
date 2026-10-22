import 'package:sqflite/sqflite.dart';

abstract final class CollectionSchema {
  static Future<void> ensure(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS collection_profile (
      id INTEGER PRIMARY KEY CHECK(id=1),
      display_name TEXT NOT NULL DEFAULT '',
      show_identity INTEGER NOT NULL DEFAULT 1 CHECK(show_identity IN (0,1))
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS collection_ownership (
      item_id TEXT NOT NULL, source_id TEXT NOT NULL, granted_at TEXT NOT NULL,
      PRIMARY KEY(item_id,source_id)
    )''');
    await db.execute('''CREATE TABLE IF NOT EXISTS collection_equipment (
      kind TEXT PRIMARY KEY, item_id TEXT NOT NULL
    )''');
  }
}
