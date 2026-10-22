import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/daily_selector.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/player_tickets.dart';
import '../../domain/entities/ticket_reward.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/reward_repository.dart';
import '../../domain/repositories/stage_repository.dart';
import 'providers.dart';
import 'app_clock.dart';
import 'growth_provider.dart';

/// Rewards handed out since the last time the UI acknowledged them.
class RewardFeed {
  final List<TicketReward> pending;
  final bool hasError;

  const RewardFeed({this.pending = const [], this.hasError = false});

  bool get hasPending => pending.isNotEmpty;
  int get totalAmount => pending.fold(0, (sum, r) => sum + r.amount);
}

/// Evaluates the earning rules after a game and credits what is due.
class RewardNotifier extends StateNotifier<RewardFeed> {
  final RewardRepository _rewards;
  final StageRepository _stages;
  final GameRepository _games;
  final Future<void> Function(int amount) _credit;
  final Future<bool> Function(TicketReward reward, GameSession session)?
  _creditOnce;
  final Future<int> Function(GameSession session)? _stageBonus;
  GameSession? _failedSession;
  bool _retrying = false;

  RewardNotifier({
    required RewardRepository rewards,
    required StageRepository stages,
    required GameRepository games,
    required Future<void> Function(int amount) credit,
    Future<bool> Function(TicketReward reward, GameSession session)? creditOnce,
    Future<int> Function(GameSession session)? stageBonus,
  }) : _rewards = rewards,
       _stages = stages,
       _games = games,
       _credit = credit,
       _creditOnce = creditOnce,
       _stageBonus = stageBonus,
       super(const RewardFeed());

  /// Grants everything [finished] earned, skipping already-claimed rewards.
  Future<void> evaluate(GameSession finished) async {
    if (!mounted || finished.status != GameStatus.won) return;

    final stageNowComplete = await _isStageComplete(finished);
    final stats = await _games.getStats(
      mode: finished.mode,
      streakFreezes: await _rewards.streakFreezes(),
    );

    final candidates = RewardRules.evaluate(
      finished: finished,
      stageNowComplete: stageNowComplete,
      currentStreak: stats.currentStreak,
      stageBonus: finished.isStage
          ? await _stageBonus?.call(finished) ?? RewardRules.stageCompletion
          : RewardRules.stageCompletion,
    );

    final granted = <TicketReward>[];
    final claimed = _creditOnce == null
        ? <String>{}
        : await _rewards.claimedKeys();
    for (final reward in candidates) {
      // Production commits receipt and balance in one transaction. The legacy
      // callback remains a seam for older embedders, not the application path.
      if (_creditOnce != null) {
        if (claimed.contains(reward.key)) continue;
        if (await _creditOnce(reward, finished)) granted.add(reward);
        continue;
      }
      if (!await _rewards.claim(reward)) continue;

      try {
        await _credit(reward.amount);
      } catch (_) {
        // Claim + balance live behind separate repositories, so compensate the
        // first write if the second fails. Otherwise a transient DB failure
        // would permanently mark an unpaid reward as collected.
        await _rewards.revoke(reward.key);
        rethrow;
      }
      granted.add(reward);
    }

    if (granted.isNotEmpty && mounted) {
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

  /// Pays [cost] tickets to protect a missed day.
  ///
  /// The caller supplies debit/refund functions from [TicketNotifier]. If the
  /// database refuses or fails to record the freeze after payment, the exact
  /// charge is rolled back instead of silently losing the player's tickets.
  Future<bool> freezeMissedDay({
    required String date,
    required Future<TicketDebit?> Function(int cost) charge,
    required Future<void> Function(TicketDebit debit) refund,
    Future<void> Function(TicketDebit debit)? complete,
    int cost = streakFreezeCost,
  }) async {
    final existing = await _rewards.streakFreezes();
    if (existing.contains(date)) return false;
    if (!DailySelector.isDailyKey(date)) return false;

    final debit = await charge(cost);
    if (debit == null) return false;

    try {
      final frozen = await _rewards.freezeStreakDay(date);
      if (frozen) {
        await complete?.call(debit);
        return true;
      }
      await refund(debit);
      return false;
    } catch (_) {
      await refund(debit);
      rethrow;
    }
  }

  void reportFailure(GameSession finished) {
    if (!mounted) {
      return;
    }
    _failedSession = finished;
    state = RewardFeed(pending: state.pending, hasError: true);
  }

  Future<void> retryPending() async {
    if (!mounted || _retrying || _failedSession == null) {
      return;
    }
    final finished = _failedSession!;
    _retrying = true;
    state = RewardFeed(pending: state.pending);
    try {
      await evaluate(finished);
      _failedSession = null;
    } catch (_) {
      reportFailure(finished);
    } finally {
      _retrying = false;
    }
  }

  void acknowledge() => state = RewardFeed(hasError: state.hasError);

  static const int streakFreezeCost = 3;
}

final rewardNotifierProvider =
    StateNotifierProvider<RewardNotifier, RewardFeed>((ref) {
      final economy = ref.read(economyRepositoryProvider);
      return RewardNotifier(
        stageBonus: (s) => economy.bonus(s.mode.name, s.stageId),
        rewards: ref.read(rewardRepositoryProvider),
        stages: ref.read(stageRepositoryProvider),
        games: ref.read(gameRepositoryProvider),
        credit: (amount) =>
            ref.read(ticketNotifierProvider.notifier).addTickets(amount),
        creditOnce: (reward, session) => ref
            .read(ticketNotifierProvider.notifier)
            .creditOnce(
              key: reward.key,
              amount: reward.amount,
              verify: (db) async {
                // Re-check the persisted qualifying result in the transaction.
                final rows = await db.query(
                  'game_sessions',
                  columns: ['id'],
                  where: 'id = ? AND status = ? AND mode = ? AND movie_id = ?',
                  whereArgs: [
                    session.id,
                    'won',
                    session.mode.name,
                    session.movieId,
                  ],
                  limit: 1,
                );
                if (rows.isEmpty) throw StateError('No qualifying result');
              },
            ),
      );
    });

/// Days between the last finished daily game and today that were never played.
final recoverableStreakDayProvider = FutureProvider.autoDispose<String?>((
  ref,
) async {
  final games = ref.read(gameRepositoryProvider);
  final rewards = ref.read(rewardRepositoryProvider);
  // Capture dependencies before awaiting IO. A completed query can otherwise
  // attach a disposed autoDispose element to the clock's dependency graph.
  final today = DailySelector.dateFromKey(ref.watch(dailyDateProvider))!;

  final sessions = await games.getFinishedDailySessions(mode: GameMode.clue);
  if (sessions.isEmpty) return null;

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
