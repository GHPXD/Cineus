import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/utils/daily_selector.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/player_tickets.dart';
import '../../domain/entities/ticket_reward.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/repositories/stage_repository.dart';
import 'providers.dart';

class RewardFeed {
  final List<TicketReward> pending;

  const RewardFeed({this.pending = const []});

  bool get hasPending => pending.isNotEmpty;
  int get totalAmount => pending.fold(0, (sum, r) => sum + r.amount);
}

class RewardNotifier extends StateNotifier<RewardFeed> {
  final RewardRepository _rewards;
  final StageRepository _stages;
  final GameRepository _games;
  final Future<void> Function(int amount) _credit;

  RewardNotifier({
    required RewardRepository rewards,
    required StageRepository stages,
    required GameRepository games,
    required Future<void> Function(int amount) credit,
  }) : _rewards = rewards,
       _stages = stages,
       _games = games,
       _credit = credit,
       super(const RewardFeed());

  Future<void> evaluate(GameSession finished) async {
    if (finished.status != GameStatus.won) return;

    final stageNowComplete = await _isStageComplete(finished);
    final stats = await _games.getStats(
      mode: finished.mode,
      streakFreezes: await _rewards.streakFreezes(),
    );

    final candidates = RewardRules.evaluate(
      finished: finished,
      stageNowComplete: stageNowComplete,
      currentStreak: stats.currentStreak,
    );

    final granted = <TicketReward>[];
    for (final reward in candidates) {
      if (await _rewards.claim(reward)) {
        await _credit(reward.amount);
        granted.add(reward);
      }
    }

    if (granted.isNotEmpty) {
      state = RewardFeed(pending: [...state.pending, ...granted]);
    }
  }

  Future<bool> _isStageComplete(GameSession finished) async {
    if (!finished.isStage) return false;
    final mode = finished.mode == GameMode.poster ? 'poster' : 'clue';
    final stages = await _stages.getAllStages(mode: mode);
    final stage = stages.where((s) => s.id == finished.stageId).firstOrNull;
    return stage?.isCompleted ?? false;
  }

  /// Pays tickets to protect a missed day, refunding the exact debit whenever
  /// persistence rejects or fails the freeze.
  Future<bool> freezeMissedDay({
    required String date,
    required Future<TicketDebit?> Function(int cost) charge,
    required Future<void> Function(TicketDebit debit) refund,
    int cost = streakFreezeCost,
  }) async {
    final existing = await _rewards.streakFreezes();
    if (existing.contains(date)) return false;
    if (!DailySelector.isDailyKey(date)) return false;

    final debit = await charge(cost);
    if (debit == null) return false;

    try {
      final frozen = await _rewards.freezeStreakDay(date);
      if (frozen) return true;
    } catch (_) {
      // Refund below. Repository details deliberately do not leak to the UI.
    }

    await refund(debit);
    return false;
  }

  void acknowledge() => state = const RewardFeed();

  static const int streakFreezeCost = 3;
}

final rewardNotifierProvider =
    StateNotifierProvider<RewardNotifier, RewardFeed>((ref) {
      return RewardNotifier(
        rewards: ref.read(rewardRepositoryProvider),
        stages: ref.read(stageRepositoryProvider),
        games: ref.read(gameRepositoryProvider),
        credit: (amount) =>
            ref.read(ticketNotifierProvider.notifier).addTickets(amount),
      );
    });

final recoverableStreakDayProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final games = ref.read(gameRepositoryProvider);
  final rewards = ref.read(rewardRepositoryProvider);

  final sessions = await games.getFinishedDailySessions(mode: GameMode.clue);
  if (sessions.isEmpty) return null;

  final today = DailySelector.dateFromKey(DailySelector.todayKey())!;
  final latest = DailySelector.dateFromKey(sessions.first.date);
  if (latest == null) return null;

  final gap = today.difference(latest).inDays;
  if (gap != 2) return null;

  final missed = DailySelector.todayKey(latest.add(const Duration(days: 1)));
  final frozen = await rewards.streakFreezes();
  if (frozen.contains(missed)) return null;
  if (sessions.first.status != GameStatus.won) return null;

  return missed;
});
