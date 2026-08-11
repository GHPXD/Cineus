import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/domain/entities/player_tickets.dart';
import 'package:cineus/domain/repositories/game_repository.dart';
import 'package:cineus/domain/repositories/reward_repository.dart';
import 'package:cineus/domain/repositories/stage_repository.dart';
import 'package:cineus/presentation/providers/reward_notifier.dart';

void main() {
  RewardNotifier build(RewardRepository rewards) => RewardNotifier(
    rewards: rewards,
    stages: _UnusedStageRepository(),
    games: _UnusedGameRepository(),
    credit: (_) async {},
  );

  test(
    'streak freeze refunds the exact debit when repository rejects it',
    () async {
      final notifier = build(_RejectingRewardRepository());
      TicketDebit? refunded;

      final ok = await notifier.freezeMissedDay(
        date: '2026-08-10',
        charge: (_) async =>
            const TicketDebit(dailyTickets: 2, extraTickets: 1),
        refund: (debit) async => refunded = debit,
      );

      expect(ok, isFalse);
      expect(refunded?.dailyTickets, 2);
      expect(refunded?.extraTickets, 1);
    },
  );

  test('streak freeze refunds when repository throws', () async {
    final notifier = build(_ThrowingRewardRepository());
    var refundCount = 0;

    final ok = await notifier.freezeMissedDay(
      date: '2026-08-10',
      charge: (_) async => const TicketDebit(dailyTickets: 3, extraTickets: 0),
      refund: (debit) async => refundCount += debit.total,
    );

    expect(ok, isFalse);
    expect(refundCount, 3);
  });
}

class _RejectingRewardRepository implements RewardRepository {
  @override
  Future<bool> freezeStreakDay(String date) async => false;

  @override
  Future<Set<String>> streakFreezes() async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ThrowingRewardRepository implements RewardRepository {
  @override
  Future<bool> freezeStreakDay(String date) async =>
      throw StateError('disk full');

  @override
  Future<Set<String>> streakFreezes() async => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedStageRepository implements StageRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedGameRepository implements GameRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
