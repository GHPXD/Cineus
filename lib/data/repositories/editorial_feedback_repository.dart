import '../datasources/database_provider.dart';
import '../services/growth_gateway.dart';

class EditorialFeedbackRepository {
  final DatabaseProvider database;
  final DateTime Function() now;
  const EditorialFeedbackRepository(this.database, this.now);
  Future<void> flush(GrowthGateway gateway) async {
    final db = await database.database;
    if ((await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='editorial_feedback'",
    )).isEmpty) {
      return;
    }
    for (final row in await db.query(
      'editorial_feedback',
      where: 'sent=0',
      orderBy: 'id',
      limit: 10,
    )) {
      await gateway.command('feedback', {
        'id': '${row['created_at']}:${row['id']}',
        'mode': row['mode'],
        'category': switch (row['category']) {
          'answer' => 'clue',
          'art' => 'artwork',
          _ => row['category'],
        },
        'movie_id': row['movie_id'],
        'question': row['question'] ?? '',
        'note': row['note'],
      });
      await db.update(
        'editorial_feedback',
        {'sent': 1},
        where: 'id=?',
        whereArgs: [row['id']],
      );
    }
  }

  Future<void> submit({
    required String mode,
    required String category,
    int? movieId,
    String? question,
    String note = '',
  }) async {
    if (!{'clue', 'poster', 'colors'}.contains(mode) ||
        !{'answer', 'art', 'difficulty', 'other'}.contains(category) ||
        (movieId != null && (movieId < 1 || movieId > 32767)) ||
        (question?.length ?? 0) > 160 ||
        note.length > 500) {
      throw const FormatException('Invalid feedback');
    }
    final db = await database.database;
    await db.execute('''CREATE TABLE IF NOT EXISTS editorial_feedback(
      id INTEGER PRIMARY KEY AUTOINCREMENT, mode TEXT NOT NULL, category TEXT NOT NULL,
      movie_id INTEGER, question TEXT, note TEXT NOT NULL, created_at TEXT NOT NULL,
      sent INTEGER NOT NULL DEFAULT 0)''');
    await db.insert('editorial_feedback', {
      'mode': mode,
      'category': category,
      'movie_id': movieId,
      'question': question,
      'note': note.trim(),
      'created_at': now().toUtc().toIso8601String(),
    });
  }
}
