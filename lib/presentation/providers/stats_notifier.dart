import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final bool hasError;
  final PlayInsights insights;
  final List<Achievement> achievements;

  const StatsState({
    this.stats = const GameStats(),
    this.recentGames = const [],
    this.isLoading = true,
    this.hasError = false,
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
  int _generation = 0;

  StatsNotifier(
    this._gameRepo,
    this._movieRepo,
    this._rewardRepo,
    this._stageRepo,
  ) : super(const StatsState()) {
    load();
  }

  Future<void> load() async {
    final generation = ++_generation;
    state = StatsState(
      stats: state.stats,
      recentGames: state.recentGames,
      insights: state.insights,
      achievements: state.achievements,
      isLoading: true,
    );

    try {
      final freezes = await _rewardRepo.streakFreezes();
      final stats = await _gameRepo.getStats(
        mode: GameMode.clue,
        streakFreezes: freezes,
      );
      final sessions =
          await _gameRepo.getFinishedDailySessions(mode: GameMode.clue);

      final movies = await _movieRepo.getMoviesByIds(
        sessions.map((s) => s.movieId).toSet().toList(),
      );
      final moviesById = {for (final m in movies) m.id: m};

      final recent = [
        for (final s in sessions.take(20))
          SessionWithMovie(s, moviesById[s.movieId]),
      ];

      final stagesCompleted = (await _stageRepo.getAllStages(mode: 'clue'))
              .where((s) => s.isCompleted)
              .length +
          (await _stageRepo.getAllStages(mode: 'poster'))
              .where((s) => s.isCompleted)
              .length;

      final ticketsEarned = await _rewardRepo.totalEarned();
      if (!mounted || generation != _generation) return;

      state = StatsState(
        stats: stats,
        recentGames: recent,
        isLoading: false,
        insights: PlayInsights.from(sessions, moviesById),
        achievements: Achievements.evaluate(
          stats: stats,
          stagesCompleted: stagesCompleted,
          ticketsEarned: ticketsEarned,
        ),
      );
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = StatsState(
        stats: state.stats,
        recentGames: state.recentGames,
        insights: state.insights,
        achievements: state.achievements,
        isLoading: false,
        hasError: true,
      );
    }
  }
}

final statsNotifierProvider =
    StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(
    ref.read(gameRepositoryProvider),
    ref.read(movieRepositoryProvider),
    ref.read(rewardRepositoryProvider),
    ref.read(stageRepositoryProvider),
  );
});