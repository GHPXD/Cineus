import 'package:sqflite/sqflite.dart';

abstract final class ColorSchema {
  static Future<void> ensure(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS color_sessions (
      id TEXT PRIMARY KEY,
      kind TEXT NOT NULL CHECK(kind IN ('training','daily')),
      daily_date TEXT UNIQUE,
      status TEXT NOT NULL CHECK(status IN ('active','completed','abandoned')),
      active_slot TEXT UNIQUE CHECK(active_slot IS NULL OR active_slot = 'training'),
      revision INTEGER NOT NULL CHECK(revision >= 0),
      snapshot TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      CHECK((kind = 'daily' AND daily_date IS NOT NULL AND active_slot IS NULL)
        OR (kind = 'training' AND daily_date IS NULL)),
      CHECK(active_slot IS NULL OR (kind = 'training' AND status = 'active'))
    )''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS color_status_kind ON color_sessions(status,kind,updated_at)',
    );
    await db.execute('''CREATE TABLE IF NOT EXISTS color_stage_slots (
      stage_version TEXT NOT NULL,
      stage_id INTEGER NOT NULL CHECK(stage_id > 0),
      match_index INTEGER NOT NULL CHECK(match_index IN (0,1)),
      session_id TEXT NOT NULL UNIQUE REFERENCES color_sessions(id),
      PRIMARY KEY(stage_version,stage_id,match_index)
    )''');
  }
}
