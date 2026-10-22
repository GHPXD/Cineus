import 'game_stats.dart';
import 'color_stats.dart';

/// One badge the player can unlock (D5).
///
/// Achievements are *derived*, never stored: every threshold is computed from the
/// same session history the statistics use. That means there is no separate state
/// to keep in sync, and a fix to the streak calculation retroactively corrects
/// the badges too.
class Achievement {
  /// Stable identifier. The visible title and description are resolved in the
  /// presentation layer — the domain must not carry localised copy.
  final String id;

  /// How far along the player is, 0–1.
  final double progress;

  /// Human-readable progress, e.g. `4 / 7`.
  final String progressLabel;

  const Achievement({
    required this.id,
    required this.progress,
    required this.progressLabel,
  });

  bool get isUnlocked => progress >= 1;
}

/// Definitions and evaluation for the badge set.
abstract final class Achievements {
  /// Extra badges keep independent score scales and use recorded results only.
  static List<Achievement> evaluateAdditional({
    required GameStats poster,
    required ColorStats colors,
    required int colorStagesCompleted,
  }) => [
    _counter(id: 'poster_first', current: poster.totalWins, target: 1),
    _counter(
      id: 'poster_perfect',
      current: poster.scoreDistribution[5] ?? 0,
      target: 1,
    ),
    _counter(id: 'colors_first', current: colors.games, target: 1),
    _counter(id: 'colors_25', current: colors.games, target: 25),
    _counter(
      id: 'colors_excellent',
      current: (colors.bestCents ?? 0) >= 900 ? 1 : 0,
      target: 1,
    ),
    _counter(id: 'colors_stages_3', current: colorStagesCompleted, target: 3),
  ];

  /// Evaluates every badge against the player's record.
  ///
  /// [perfectScores] is how many games were won on the first clue — the maximum
  /// score — which the distribution already tracks.
  static List<Achievement> evaluate({
    required GameStats stats,
    required int stagesCompleted,
    required int ticketsEarned,
  }) {
    final perfect = stats.scoreDistribution[10] ?? 0;

    return [
      _counter(id: 'first_win', current: stats.totalWins, target: 1),
      _counter(id: 'perfect', current: perfect, target: 1),
      _counter(id: 'streak_7', current: stats.maxStreak, target: 7),
      _counter(id: 'streak_30', current: stats.maxStreak, target: 30),
      _counter(id: 'games_50', current: stats.totalGames, target: 50),
      _counter(id: 'stages_5', current: stagesCompleted, target: 5),
      _counter(id: 'tickets_100', current: ticketsEarned, target: 100),
    ];
  }

  static Achievement _counter({
    required String id,
    required int current,
    required int target,
  }) {
    final capped = current > target ? target : current;
    return Achievement(
      id: id,
      progress: target == 0 ? 1 : capped / target,
      progressLabel: target == 1 ? '' : '$capped / $target',
    );
  }
}
