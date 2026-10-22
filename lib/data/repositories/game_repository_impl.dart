import 'package:sqflite/sqflite.dart';

import '../../core/utils/daily_selector.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/database_provider.dart';
import '../datasources/journey_schema.dart';

class GameRepositoryImpl implements GameRepository {
  final DatabaseProvider _db;
  final DateTime Function() _now;

  GameRepositoryImpl(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  @override
  Future<GameSession?> getDailySession(GameMode mode, String date) async {
    final db = await _db.database;
    final maps = await db.query(
      'game_sessions',
      where: "kind = 'daily' AND mode = ? AND date = ?",
      whereArgs: [mode.name, date],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return GameSession.fromMap(maps.first);
  }

  @override
  Future<GameSession?> getStageSession(
    GameMode mode,
    int stageId,
    int movieId,
  ) async {
    final db = await _db.database;
    final maps = await db.query(
      'game_sessions',
      where: "kind = 'stage' AND mode = ? AND stage_id = ? AND movie_id = ?",
      whereArgs: [mode.name, stageId, movieId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return GameSession.fromMap(maps.first);
  }

  @override
  Future<GameSession?> getChallengeSession(GameMode mode, int movieId) async {
    final db = await _db.database;
    final maps = await db.query(
      'game_sessions',
      where: "kind = 'challenge' AND mode = ? AND movie_id = ? AND date = ''",
      whereArgs: [mode.name, movieId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return GameSession.fromMap(maps.first);
  }

  Future<GameSession?> _byIdentity(GameSession s, DatabaseExecutor db) async {
    final (where, args) = switch (s.kind) {
      SessionKind.daily => (
        "kind='daily' AND mode=? AND date=?",
        <Object?>[s.mode.name, s.date],
      ),
      SessionKind.stage => (
        "kind='stage' AND mode=? AND stage_id=? AND movie_id=?",
        <Object?>[s.mode.name, s.stageId, s.movieId],
      ),
      SessionKind.challenge => (
        "kind='challenge' AND mode=? AND movie_id=? AND date=?",
        <Object?>[s.mode.name, s.movieId, s.date],
      ),
      SessionKind.archive => (
        'kind=? AND mode=? AND date=?',
        <Object?>[s.kind.name, s.mode.name, s.date],
      ),
      SessionKind.training => (
        'kind=? AND mode=? AND date=? AND movie_id=?',
        <Object?>[s.kind.name, s.mode.name, s.date, s.movieId],
      ),
    };
    final rows = await db.query(
      'game_sessions',
      where: where,
      whereArgs: args,
      limit: 1,
    );
    return rows.isEmpty ? null : GameSession.fromMap(rows.single);
  }

  Future<GameSession> _recordFinished(
    DatabaseExecutor db,
    GameSession s,
  ) async {
    if (s.isFinished) {
      await JourneySchema.finish(
        db,
        key: 'film:${s.id}',
        mode: s.mode.name,
        kind: s.kind.name,
        at: _now(),
        scoreCents: s.score * 100,
      );
    }
    return s;
  }

  @override
  Future<GameSession> saveSession(GameSession session) async {
    final database = await _db.database;
    return database.transaction((db) => _save(db, session));
  }

  Future<GameSession> _save(DatabaseExecutor db, GameSession session) async {
    if (session.id != null) {
      // A stale notifier must never turn a terminal result back into `playing`
      // (or replace one terminal outcome with another). Only a playing row may
      // transition. If another writer already finished it, return that truth.
      final changed = await db.update(
        'game_sessions',
        {...session.toMap(), 'updated_at': _now().toUtc().toIso8601String()},
        where: "id = ? AND status = 'playing'",
        whereArgs: [session.id],
      );
      if (changed == 1) return _recordFinished(db, session);

      final rows = await db.query(
        'game_sessions',
        where: 'id = ?',
        whereArgs: [session.id],
        limit: 1,
      );
      if (rows.isNotEmpty) return GameSession.fromMap(rows.first);
      throw StateError('Session ${session.id} no longer exists');
    }

    // Fast path for normal callers that lost the row id.
    final existing = await _byIdentity(session, db);
    if (existing != null) {
      if (existing.isFinished) return existing;
      final updated = session.copyWith(id: existing.id);
      final changed = await db.update(
        'game_sessions',
        {...updated.toMap(), 'updated_at': _now().toUtc().toIso8601String()},
        where: "id = ? AND status = 'playing'",
        whereArgs: [existing.id],
      );
      if (changed == 1) return _recordFinished(db, updated);
      return (await _byIdentity(session, db)) ?? updated;
    }

    // Two simultaneous creators can both observe "no row". Let the unique
    // identity indexes arbitrate with INSERT OR IGNORE, then read back the one
    // canonical row. This turns a constraint crash into an idempotent create.
    await db.insert('game_sessions', {
      ...session.toMap(),
      'updated_at': _now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    final stored = await _byIdentity(session, db);
    if (stored == null) {
      throw StateError('Failed to create ${session.kind.name} session');
    }
    return _recordFinished(db, stored);
  }

  @override
  Future<void> deleteStageSession(
    GameMode mode,
    int stageId,
    int movieId,
  ) async {
    final db = await _db.database;
    await db.delete(
      'game_sessions',
      where: "kind = 'stage' AND mode = ? AND stage_id = ? AND movie_id = ?",
      whereArgs: [mode.name, stageId, movieId],
    );
  }

  @override
  Future<List<GameSession>> getFinishedDailySessions({
    GameMode mode = GameMode.clue,
  }) async {
    final db = await _db.database;
    final maps = await db.query(
      'game_sessions',
      where: "kind = 'daily' AND mode = ? AND status != 'playing'",
      whereArgs: [mode.name],
      orderBy: 'date DESC',
    );
    return maps.map(GameSession.fromMap).toList();
  }

  @override
  Future<GameStats> getStats({
    GameMode mode = GameMode.clue,
    Set<String> streakFreezes = const {},
  }) async {
    return computeStats(
      await getFinishedDailySessions(mode: mode),
      todayUtc: DailySelector.dateFromKey(DailySelector.todayKey(_now()))!,
      streakFreezes: streakFreezes,
    );
  }

  static GameStats computeStats(
    List<GameSession> descending, {
    required DateTime todayUtc,
    Set<String> streakFreezes = const {},
  }) {
    if (descending.isEmpty) return const GameStats();

    final totalGames = descending.length;
    final wins = descending.where((s) => s.status == GameStatus.won).toList();
    final totalWins = wins.length;

    final avgClues = wins.isNotEmpty
        ? wins.map((s) => s.revealedClues).reduce((a, b) => a + b) / wins.length
        : 0.0;

    // The chart renders score buckets 1..max only. Losses are already represented
    // by totalGames/totalWins/winRate and must not create a hidden score=0 bucket
    // that changes the visual scale of every visible bar.
    final distMap = <int, int>{};
    for (final s in wins) {
      distMap[s.score] = (distMap[s.score] ?? 0) + 1;
    }

    return GameStats(
      totalGames: totalGames,
      totalWins: totalWins,
      winRate: totalWins / totalGames,
      averageCluesUsed: avgClues,
      currentStreak: _currentStreak(descending, todayUtc, streakFreezes),
      maxStreak: _maxStreak(descending, streakFreezes),
      scoreDistribution: distMap,
    );
  }

  static int _currentStreak(
    List<GameSession> descending,
    DateTime today,
    Set<String> freezes,
  ) {
    if (descending.isEmpty) return 0;

    final latest = DailySelector.dateFromKey(descending.first.date);
    if (latest == null) return 0;

    if (today.difference(latest).inDays > 1 &&
        !_allFrozen(
          latest.add(const Duration(days: 1)),
          today.subtract(const Duration(days: 1)),
          freezes,
        )) {
      return 0;
    }

    var streak = 0;
    DateTime? expected;
    for (final s in descending) {
      if (s.status != GameStatus.won) break;
      final day = DailySelector.dateFromKey(s.date);
      if (day == null) break;

      if (expected != null &&
          day != expected &&
          !_allFrozen(day.add(const Duration(days: 1)), expected, freezes)) {
        break;
      }
      streak++;
      expected = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _maxStreak(List<GameSession> descending, Set<String> freezes) {
    var best = 0;
    var run = 0;
    DateTime? expected;

    for (final s in descending) {
      final day = DailySelector.dateFromKey(s.date);
      if (s.status != GameStatus.won || day == null) {
        run = 0;
        expected = null;
        continue;
      }
      if (expected != null &&
          day != expected &&
          !_allFrozen(day.add(const Duration(days: 1)), expected, freezes)) {
        run = 0;
      }
      run++;
      if (run > best) best = run;
      expected = day.subtract(const Duration(days: 1));
    }
    return best;
  }

  static bool _allFrozen(DateTime first, DateTime last, Set<String> freezes) {
    if (last.isBefore(first)) return true;
    if (freezes.isEmpty) return false;

    for (
      var day = first;
      !day.isAfter(last);
      day = day.add(const Duration(days: 1))
    ) {
      if (!freezes.contains(DailySelector.todayKey(day))) return false;
    }
    return true;
  }
}
