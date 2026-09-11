import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cineus/data/repositories/reward_repository_impl.dart';
import 'package:cineus/domain/entities/ticket_reward.dart';

import 'support/test_database.dart';

void main() {
  late Database db;
  late RewardRepositoryImpl rewards;

  setUp(() async {
    db = await openTestDatabase();
    rewards = RewardRepositoryImpl(
      TestDatabaseProvider(db),
      now: () => DateTime.utc(2026, 9, 10, 12),
    );
  });

  tearDown(() async => db.close());

  test('revoke desfaz claim sem crédito e mantém recompensa recuperável', () async {
    const reward = TicketReward(
      key: 'rollback_reward',
      amount: 2,
      kind: RewardKind.dailyWin,
    );

    expect(await rewards.claim(reward), isTrue);
    expect(await rewards.totalEarned(), 2);
    expect(await rewards.claimedKeys(), contains(reward.key));

    await rewards.revoke(reward.key);

    expect(await rewards.totalEarned(), 0);
    expect(await rewards.claimedKeys(), isNot(contains(reward.key)));
    expect(await rewards.claim(reward), isTrue,
        reason: 'o bônus precisa poder ser tentado novamente após rollback');
  });
}
