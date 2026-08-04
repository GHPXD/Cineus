import '../entities/ticket_reward.dart';

abstract class RewardRepository {
  /// Records [reward] as paid out. Returns false when it was already claimed,
  /// in which case nothing is credited.
  Future<bool> claim(TicketReward reward);

  /// Keys already paid out.
  Future<Set<String>> claimedKeys();

  /// Total tickets ever earned through rewards.
  Future<int> totalEarned();

  /// Days the player paid to keep their streak alive (`YYYY-MM-DD`).
  Future<Set<String>> streakFreezes();

  /// Freezes [date]. Returns false when it was already frozen.
  Future<bool> freezeStreakDay(String date);
}
