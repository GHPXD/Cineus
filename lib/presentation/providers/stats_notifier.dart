import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/achievement.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/play_insights.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/movie_repository.dart';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/repositories/stage_repository.dart';
import 'providers.dart';

class StatsState {
  final GameStats stats;
  final List<SessionWithMovie> recentGames;
  final bool isLoading;

  /// Genre and decade breakdowns (D8).
  final PlayInsights insights;

  /// Derived badges (D5).
  final List<Achievement> achievements;

  const StatsState({
    this.stats = const GameStats(),
    this.recentGames = const [],
    this.isLoading = true,
    this.insights = const PlayInsights(),
    this.achievements = const [],
  });

  int get unlockedAchievements =>
      achievements.where((a) => a.isUnlocked).length;
}

class SessionWithMovie {
  final GameSession session;
  final Movie? movie;

  const SessionWithMovie(this.session, this.movie);
}

class StatsNotifier extends StateNotifier<StatsState> {
  final GameRepository _gameRepo;
  final MovieRepository _movieRepo;
  final RewardRepository _rewardRepo;
  final StageRepository _stageRepo;

  StatsNotifier(
    this._gameRepo,
    this._movieRepo,
    this._rewardRepo,
    this._stageRepo,
  ) : super(const StatsState()) {
    load();
  }

  Future<void> load() async {
    state = const StatsState(isLoading: true);

    // Clue mode only: poster games run on a 1–5 scale and would distort the
    // distribution, the average and the streak.
    final stats = await _gameRepo.getStats(
      mode: GameMode.clue,
      streakFreezes: await _rewardRepo.streakFreezes(),
    );
    final sessions = await _gameRepo.getFinishedDailySessions(
      mode: GameMode.clue,
    );

    // One batched read instead of a query per session — the breakdowns need
    // every game, not just the 20 most recent.
    final movies = await _movieRepo.getMoviesByIds(
      sessions.map((s) => s.movieId).toSet().toList(),
    );
    final moviesById = {for (final m in movies) m.id: m};

    final recent = [
      for (final s in sessions.take(20))
        SessionWithMovie(s, moviesById[s.movieId]),
    ];

    final stagesCompleted =
        (await _stageRepo.getAllStages(
          mode: 'clue',
        )).where((s) => s.isCompleted).length +
        (await _stageRepo.getAllStages(
          mode: 'poster',
        )).where((s) => s.isCompleted).length;

    state = StatsState(
      stats: stats,
      recentGames: recent,
      isLoading: false,
      insights: PlayInsights.from(sessions, moviesById),
      achievements: Achievements.evaluate(
        stats: stats,
        stagesCompleted: stagesCompleted,
        ticketsEarned: await _rewardRepo.totalEarned(),
      ),
    );
  }
}

final statsNotifierProvider = StateNotifierProvider<StatsNotifier, StatsState>((
  ref,
) {
  return StatsNotifier(
    ref.read(gameRepositoryProvider),
    ref.read(movieRepositoryProvider),
    ref.read(rewardRepositoryProvider),
    ref.read(stageRepositoryProvider),
  );
});
