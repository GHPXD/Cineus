import '../../domain/entities/game_session.dart';
import '../../core/utils/daily_selector.dart';
import '../datasources/database_provider.dart';
import '../datasources/journey_schema.dart';

enum ActivityScope { all, daily, stages, invitations, practice }

class PresenceProgress {
  final int current, best, days;
  const PresenceProgress(this.current, this.best, this.days);
}

/// Queries saved progress, never creates a result or infers a win from activity.
class ProgressRepository {
  final DatabaseProvider database;
  final DateTime Function() now;
  const ProgressRepository(this.database, this.now);

  Future<List<GameSession>> films(GameMode mode, ActivityScope scope) async {
    final db = await database.database;
    final kind = switch (scope) {
      ActivityScope.daily => 'daily',
      ActivityScope.stages => 'stage',
      ActivityScope.invitations => 'challenge',
      _ => null,
    };
    final rows = await db.query(
      'game_sessions',
      where:
          'mode=? AND status!=?${scope == ActivityScope.practice
              ? " AND kind IN ('training','archive')"
              : kind == null
              ? ''
              : ' AND kind=?'}',
      whereArgs: [mode.name, 'playing', if (kind != null) kind],
      orderBy: 'id DESC',
    );
    return rows.map(GameSession.fromMap).toList();
  }

  Future<GameSession?> continuing() async {
    final db = await database.database;
    final rows = await db.query(
      'game_sessions',
      where: 'status=?',
      whereArgs: ['playing'],
      orderBy: 'updated_at DESC, id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : GameSession.fromMap(rows.single);
  }

  Future<PresenceProgress> presence() async {
    final db = await database.database;
    await JourneySchema.ensure(db);
    final rows = await db.rawQuery(
      'SELECT DISTINCT substr(completed_at,1,10) day FROM journey_completions WHERE completed_at<=? ORDER BY day',
      [now().toUtc().toIso8601String()],
    );
    final dates = rows
        .map((r) => DailySelector.dateFromKey(r['day'] as String))
        .whereType<DateTime>()
        .toList();
    var run = 0, best = 0;
    DateTime? previous;
    for (final date in dates) {
      run = previous != null && date.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > best) best = run;
      previous = date;
    }
    final today = DailySelector.dateFromKey(DailySelector.todayKey(now()))!;
    final current = previous != null && today.difference(previous).inDays <= 1
        ? run
        : 0;
    return PresenceProgress(current, best, dates.length);
  }
}
