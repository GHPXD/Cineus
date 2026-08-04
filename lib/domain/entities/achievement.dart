import 'game_stats.dart';

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

  /// Language-independent, so it stays here.
  final String emoji;

  /// How far along the player is, 0–1.
  final double progress;

  /// Human-readable progress, e.g. `4 / 7`.
  final String progressLabel;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.progress,
    required this.progressLabel,
  });

  bool get isUnlocked => progress >= 1;
}

/// Definitions and evaluation for the badge set.
abstract final class Achievements {
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
      _counter(
        id: 'first_win',
        emoji: '🎬',
        current: stats.totalWins,
        target: 1,
      ),
      _counter(
        id: 'perfect',
        emoji: '💎',
        current: perfect,
        target: 1,
      ),
      _counter(
        id: 'streak_7',
        emoji: '🔥',
        current: stats.maxStreak,
        target: 7,
      ),
      _counter(
        id: 'streak_30',
        emoji: '🏅',
        current: stats.maxStreak,
        target: 30,
      ),
      _counter(
        id: 'games_50',
        emoji: '🎟️',
        current: stats.totalGames,
        target: 50,
      ),
      _counter(
        id: 'stages_5',
        emoji: '🗂️',
        current: stagesCompleted,
        target: 5,
      ),
      _counter(
        id: 'tickets_100',
        emoji: '💰',
        current: ticketsEarned,
        target: 100,
      ),
    ];
  }

  static Achievement _counter({
    required String id,
    required String emoji,
    required int current,
    required int target,
  }) {
    final capped = current > target ? target : current;
    return Achievement(
      id: id,
      emoji: emoji,
      progress: target == 0 ? 1 : capped / target,
      progressLabel: target == 1 ? '' : '$capped / $target',
    );
  }
}
