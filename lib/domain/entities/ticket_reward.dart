import 'game_session.dart';

/// A ticket payout the player earned.
///
/// [key] is deterministic and unique per achievement instance, which is what
/// makes granting idempotent: the reward table has it as PRIMARY KEY, so a
/// reward can never pay out twice no matter how often the rules are evaluated.
/// Why a reward was granted. The visible wording is resolved in the presentation
/// layer, so the domain stays free of localised copy.
enum RewardKind { dailyWin, streakMilestone, stageComplete }

class TicketReward {
  final String key;
  final int amount;
  final RewardKind kind;

  /// Streak length or stage number, depending on [kind]; null for a daily win.
  final int? value;

  const TicketReward({
    required this.key,
    required this.amount,
    required this.kind,
    this.value,
  });

  @override
  bool operator ==(Object other) => other is TicketReward && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'TicketReward($key, +$amount)';
}

/// When the player earns tickets.
///
/// `PlayerTickets.extraTickets` existed from the start — read, decremented,
/// persisted — but nothing ever incremented it. The economy was one-way: 20
/// tickets a day and no way to earn more. These are the earning paths.
abstract final class RewardRules {
  /// Finishing every film of a stage in one mode.
  static const int stageCompletion = 10;

  /// Reaching a streak milestone.
  static const int streakMilestone = 5;
  static const int streakMilestoneEvery = 7;

  /// First daily win of the day, per mode.
  static const int dailyWin = 2;

  /// Rewards implied by a just-finished session.
  ///
  /// Pure: the caller is responsible for filtering out keys already claimed and
  /// for actually crediting the tickets.
  static List<TicketReward> evaluate({
    required GameSession finished,
    required bool stageNowComplete,
    required int currentStreak,
  }) {
    if (finished.status != GameStatus.won) return const [];

    final rewards = <TicketReward>[];
    final modeName = finished.mode.name;

    if (finished.isDaily) {
      rewards.add(
        TicketReward(
          key: 'daily_win_${modeName}_${finished.date}',
          amount: dailyWin,
          kind: RewardKind.dailyWin,
        ),
      );

      if (currentStreak > 0 && currentStreak % streakMilestoneEvery == 0) {
        rewards.add(
          TicketReward(
            // Keyed by the milestone, not the date, so hitting 7 once pays once.
            key: 'streak_$currentStreak',
            amount: streakMilestone,
            kind: RewardKind.streakMilestone,
            value: currentStreak,
          ),
        );
      }
    }

    if (finished.isStage && stageNowComplete) {
      rewards.add(
        TicketReward(
          key: 'stage_${modeName}_${finished.stageId}',
          amount: stageCompletion,
          kind: RewardKind.stageComplete,
          value: finished.stageId,
        ),
      );
    }

    return rewards;
  }
}
