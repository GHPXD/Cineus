import 'package:sqflite/sqflite.dart';

abstract final class CommerceSchema {
  static Future<void> ensure(DatabaseExecutor db) async {
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS commerce_cache(
      scope TEXT PRIMARY KEY, owner TEXT NOT NULL, device TEXT NOT NULL,
      revision INTEGER NOT NULL, issued_at INTEGER NOT NULL, envelope TEXT NOT NULL)''',
    );
    await db.execute('''CREATE TABLE IF NOT EXISTS commerce_reward_receipts(
      scope TEXT NOT NULL, owner TEXT NOT NULL, receipt TEXT NOT NULL,
      occurred_at INTEGER NOT NULL, PRIMARY KEY(scope,owner,receipt))''');
    final columns = await db.rawQuery(
      'PRAGMA table_info(commerce_reward_receipts)',
    );
    if (!columns.any((column) => column['name'] == 'attempt')) {
      await db.execute(
        'ALTER TABLE commerce_reward_receipts ADD COLUMN attempt TEXT',
      );
    }
  }
}
