/// Aggregate statistics for completed daily games.
class GameStats {
  final int totalGames;
  final int totalWins;
  final double winRate;
  final double averageCluesUsed;
  final int currentStreak;
  final int maxStreak;
  final Map<int, int> scoreDistribution;

  const GameStats({
    this.totalGames = 0,
    this.totalWins = 0,
    this.winRate = 0,
    this.averageCluesUsed = 0,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.scoreDistribution = const {},
  });
}
