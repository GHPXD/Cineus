import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/game_session.dart';
import '../../data/datasources/color_schema.dart';
import 'providers.dart';
import 'reward_notifier.dart';
import 'color_providers.dart';
import 'game_actions.dart';

/// A saved terminal game is a durable delivery intent, even if the process
/// stopped before its result page could ask for the reward.
final recoverGameplayRewardsProvider = Provider<Future<void> Function()>((ref) {
  final database = ref.read(databaseProvider),
      rewards = ref.read(rewardNotifierProvider.notifier);
  final colors = ref.read(colorRepositoryProvider),
      tickets = ref.read(ticketNotifierProvider.notifier);
  final refresh = ref.read(finishedGameRefreshProvider);
  Future<void>? pending;
  Future<void> recover() async {
    final db = await database.database;
    await ColorSchema.ensure(db);
    final rows = await db.rawQuery(
      """SELECT g.* FROM game_sessions g WHERE g.status='won' AND
      ((g.kind='daily' AND NOT EXISTS(SELECT 1 FROM ticket_rewards r WHERE r.key='daily_win_'||g.mode||'_'||g.date)) OR
       (g.kind='stage' AND NOT EXISTS(SELECT 1 FROM ticket_rewards r WHERE r.key='stage_'||g.mode||'_'||g.stage_id)))
      GROUP BY g.mode,g.kind,g.date,g.stage_id ORDER BY g.id DESC""",
    );
    for (final row in rows) {
      await rewards.evaluate(
        GameSession.fromMap(Map<String, dynamic>.from(row)),
      );
    }
    final latest = await db.rawQuery(
      "SELECT * FROM game_sessions WHERE kind='daily' AND status='won' GROUP BY mode HAVING id=MAX(id)",
    );
    for (final row in latest) {
      await rewards.evaluate(
        GameSession.fromMap(Map<String, dynamic>.from(row)),
      );
    }
    for (final row in await db.rawQuery(
      """SELECT id FROM color_sessions WHERE kind='daily' AND status='completed' AND
      NOT EXISTS(SELECT 1 FROM ticket_rewards r WHERE r.key='colors_daily_'||color_sessions.daily_date)""",
    )) {
      await ColorRewards.claim(colors, tickets, row['id'] as String);
    }
    refresh();
  }

  return () => pending ??= recover().whenComplete(() => pending = null);
});
