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
import 'color_providers.dart';
import '../../domain/entities/color_stats.dart';
import 'progress_provider.dart';

class StatsState {
  final GameStats stats;
  final List<SessionWithMovie> recentGames;
  final bool isLoading;
  final bool hasError;
  final PlayInsights insights;
  final List<Achievement> achievements;
  final Set<String> protectedDays;

  const StatsState({
    this.stats = const GameStats(),
    this.recentGames = const [],
    this.isLoading = true,
    this.hasError = false,
    this.insights = const PlayInsights(),
    this.achievements = const [],
    this.protectedDays = const {},
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
  final GameMode mode;
  final Future<List<GameSession>> Function()? _sessions;
  int _generation = 0;

  StatsNotifier(
    this._gameRepo,
    this._movieRepo,
    this._rewardRepo,
    this._stageRepo, {
    required this.mode,
    Future<List<GameSession>> Function()? sessions,
  }) : _sessions = sessions,
       super(const StatsState()) {
    load();
  }

  Future<void> load() async {
    final generation = ++_generation;
    state = StatsState(
      stats: state.stats,
      recentGames: state.recentGames,
      insights: state.insights,
      achievements: state.achievements,
      protectedDays: state.protectedDays,
      isLoading: true,
    );

    try {
      final freezes = await _rewardRepo.streakFreezes();
      final dailyStats = await _gameRepo.getStats(
        mode: mode,
        streakFreezes: freezes,
      );
      final sessions =
          await (_sessions?.call() ??
              _gameRepo.getFinishedDailySessions(mode: mode));
      final wins = sessions.where((s) => s.status == GameStatus.won).toList();
      final distribution = <int, int>{};
      for (final win in wins) {
        distribution.update(win.score, (v) => v + 1, ifAbsent: () => 1);
      }
      final stats = _sessions == null
          ? dailyStats
          : GameStats(
              totalGames: sessions.length,
              totalWins: wins.length,
              winRate: sessions.isEmpty ? 0 : wins.length / sessions.length,
              averageCluesUsed: wins.isEmpty
                  ? 0
                  : wins.fold<int>(0, (v, s) => v + s.revealedClues) /
                        wins.length,
              currentStreak: dailyStats.currentStreak,
              maxStreak: dailyStats.maxStreak,
              scoreDistribution: distribution,
            );

      final movies = await _movieRepo.getMoviesByIds(
        sessions.map((s) => s.movieId).toSet().toList(),
      );
      final moviesById = {for (final m in movies) m.id: m};

      final recent = [
        for (final s in sessions.take(20))
          SessionWithMovie(s, moviesById[s.movieId]),
      ];

      var achievements = const <Achievement>[];
      if (mode == GameMode.clue) {
        final stagesCompleted =
            (await _stageRepo.getAllStages(
              mode: 'clue',
            )).where((s) => s.isCompleted).length +
            (await _stageRepo.getAllStages(
              mode: 'poster',
            )).where((s) => s.isCompleted).length;
        final ticketsEarned = await _rewardRepo.totalEarned();
        achievements = Achievements.evaluate(
          stats: dailyStats,
          stagesCompleted: stagesCompleted,
          ticketsEarned: ticketsEarned,
        );
      }

      if (!mounted || generation != _generation) return;

      state = StatsState(
        stats: stats,
        recentGames: recent,
        isLoading: false,
        insights: PlayInsights.from(sessions, moviesById),
        achievements: achievements,
        protectedDays: freezes,
      );
    } catch (_) {
      if (!mounted || generation != _generation) return;
      state = StatsState(
        stats: state.stats,
        recentGames: state.recentGames,
        insights: state.insights,
        achievements: state.achievements,
        protectedDays: state.protectedDays,
        isLoading: false,
        hasError: true,
      );
    }
  }
}

StatsNotifier _buildStats(Ref ref, GameMode mode) {
  final progress = ref.read(progressRepositoryProvider);
  final scope = ref.read(activityScopeProvider);
  return StatsNotifier(
    ref.read(gameRepositoryProvider),
    ref.read(movieRepositoryProvider),
    ref.read(rewardRepositoryProvider),
    ref.read(stageRepositoryProvider),
    mode: mode,
    sessions: () => progress.films(mode, scope),
  );
}

/// Clue stats remain the default provider because Home historically shows the
/// clue daily streak and achievement summary.
final statsNotifierProvider = StateNotifierProvider<StatsNotifier, StatsState>((
  ref,
) {
  ref.watch(activityScopeProvider);
  return _buildStats(ref, GameMode.clue);
});

/// Poster daily history is tracked independently so its 1–5 score scale never
/// pollutes the 1–10 clue distribution.
final posterStatsNotifierProvider =
    StateNotifierProvider<StatsNotifier, StatsState>((ref) {
      ref.watch(activityScopeProvider);
      return _buildStats(ref, GameMode.poster);
    });

/// One achievement collection across all modes. Updates follow source providers;
/// no separate badge database, duplicated reward, or stored unlock state.
final allAchievementsProvider = FutureProvider.autoDispose<List<Achievement>>((
  ref,
) async {
  final clues = ref.watch(statsNotifierProvider);
  final poster = ref.watch(posterStatsNotifierProvider);
  final sessionsFuture = ref.watch(colorSessionsProvider.future);
  final stagesFuture = ref.watch(colorStageProgressProvider.future);
  final games = ref.read(gameRepositoryProvider);
  final rewards = ref.read(rewardRepositoryProvider);
  final sessions = await sessionsFuture;
  final stages = await stagesFuture;
  if (clues.hasError || poster.hasError) {
    throw StateError('Statistics unavailable');
  }
  return [
    ...clues.achievements,
    ...Achievements.evaluateAdditional(
      poster: await games.getStats(
        mode: GameMode.poster,
        streakFreezes: await rewards.streakFreezes(),
      ),
      colors: ColorStats.fromSessions(sessions),
      colorStagesCompleted: stages.where((s) => s.finished).length,
    ),
  ];
});
