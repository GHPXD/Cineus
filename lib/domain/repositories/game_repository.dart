import '../entities/game_session.dart';
import '../entities/game_stats.dart';

export '../entities/game_stats.dart';

abstract class GameRepository {
  /// The daily session for [mode] on [date] (`YYYY-MM-DD`), if it exists.
  Future<GameSession?> getDailySession(GameMode mode, String date);

  /// The stage session for one film, if it exists.
  Future<GameSession?> getStageSession(
    GameMode mode,
    int stageId,
    int movieId,
  );

  /// The one-off challenge session for a film, if it exists.
  Future<GameSession?> getChallengeSession(GameMode mode, int movieId);

  /// Inserts or updates [session], returning it with its database id.
  Future<GameSession> saveSession(GameSession session);

  /// Removes a stage session so the film can be replayed from scratch.
  Future<void> deleteStageSession(GameMode mode, int stageId, int movieId);

  /// Finished daily sessions for [mode], most recent first.
  Future<List<GameSession>> getFinishedDailySessions({
    GameMode mode = GameMode.clue,
  });

  /// Aggregate statistics over the finished daily sessions of [mode].
  ///
  /// Scoped per mode because the two scales are not comparable: clue games run
  /// 1–10 and poster games 1–5.
  ///
  /// [streakFreezes] are `YYYY-MM-DD` days the player paid tickets to protect;
  /// they bridge a gap in the streak without counting as a win.
  Future<GameStats> getStats({
    GameMode mode = GameMode.clue,
    Set<String> streakFreezes = const {},
  });
}
