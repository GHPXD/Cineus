import '../entities/ticket_reward.dart';

abstract class RewardRepository {
  /// Tries to claim [reward]. Returns true exactly once for each reward key.
  Future<bool> claim(TicketReward reward);

  /// Removes a claim whose corresponding ticket credit failed to persist.
  /// This is a compensating rollback so the reward remains retryable.
  Future<void> revoke(String key);

  Future<Set<String>> claimedKeys();
  Future<int> totalEarned();

  Future<Set<String>> streakFreezes();

  /// Protects [date] from breaking a streak. Returns false if already frozen.
  Future<bool> freezeStreakDay(String date);
}
