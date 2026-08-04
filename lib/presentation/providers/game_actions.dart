import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_session.dart';
import '../../domain/entities/extra_hint.dart';
import 'play_notifier.dart';
import 'providers.dart';
import 'reward_notifier.dart';
import 'stats_notifier.dart';

/// Shared side effects that every entry point into a game must perform.
///
/// These used to be duplicated (or simply forgotten) at each call site: the
/// ticket was only charged from the stage list, and only the poster mode
/// refreshed its stage grid. Routing everything through here keeps the two modes
/// and the five entry points in step.

/// Charges one ticket and then runs [start].
///
/// Returns false — without running [start] — when the player has no tickets
/// left, so the caller can leave the player where they are.
Future<bool> startFilmWithTicket(
  WidgetRef ref,
  Future<void> Function() start,
) async {
  final consumed =
      await ref.read(ticketNotifierProvider.notifier).consumeTicket();
  if (!consumed) return false;
  await start();
  return true;
}

/// Rebuilds everything that derives from finished-game data.
///
/// Call whenever a session reaches a terminal state. Without this, the home
/// screen kept showing the stats it loaded at app start, and a stage grid kept
/// showing a stale `completedCount` with the next stage still locked.
void refreshAfterGameFinished(
  WidgetRef ref, {
  required GameMode mode,
  int? stageId,
  GameSession? finished,
}) {
  if (stageId != null) {
    ref
        .read(mode == GameMode.poster
            ? posterStageNotifierProvider.notifier
            : stageNotifierProvider.notifier)
        .load();
  }

  // Rewards are evaluated before the stats are invalidated so the refreshed
  // balance and streak land in the same rebuild. Claims are keyed, so calling
  // this twice for one session credits nothing extra.
  final credit = finished == null
      ? Future<void>.value()
      : ref.read(rewardNotifierProvider.notifier).evaluate(finished);

  credit.whenComplete(() {
    ref.invalidate(statsNotifierProvider);
    ref.invalidate(dailySessionProvider);
    ref.invalidate(recoverableStreakDayProvider);
  });
}

/// Rebuilds the streak-dependent providers after a freeze is bought.
void refreshStreakData(WidgetRef ref) {
  ref.invalidate(statsNotifierProvider);
  ref.invalidate(recoverableStreakDayProvider);
}

/// Buys one [hint] for the current game, charging tickets.
///
/// Returns false when the player cannot pay. Buying a hint deliberately does not
/// burn a reveal step — the cost is tickets, not points.
Future<bool> buyHintWithTicket(
  WidgetRef ref,
  GameMode mode,
  ExtraHint hint,
) async {
  final paid = await ref
      .read(ticketNotifierProvider.notifier)
      .consumeTicket(count: hint.ticketCost);
  if (!paid) return false;

  await ref
      .read((mode == GameMode.poster ? posterGameProvider : clueGameProvider)
          .notifier)
      .grantHint(hint);
  return true;
}
