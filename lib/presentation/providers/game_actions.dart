import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/extra_hint.dart';
import '../../domain/entities/game_session.dart';
import 'play_notifier.dart';
import 'providers.dart';
import 'reward_notifier.dart';
import 'stats_notifier.dart';

/// Shared side effects that every entry point into a game must perform.

/// Charges one ticket and then runs [start].
///
/// The debit is rolled back when loading/resetting the film fails, so a broken
/// asset/database read can never consume a ticket without starting a game.
Future<bool> startFilmWithTicket(
  WidgetRef ref,
  Future<bool> Function() start,
) async {
  final tickets = ref.read(ticketNotifierProvider.notifier);
  final debit = await tickets.debitTickets();
  if (debit == null) return false;

  try {
    final started = await start();
    if (started) return true;
  } catch (_) {
    // The UI gets its controlled error state from the game notifier. Regardless
    // of the failure shape, money-like state must be restored here.
  }

  await tickets.refundDebit(debit);
  return false;
}

/// Rebuilds everything that derives from finished-game data.
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
/// Persistence can fail after the debit, so hints use the same rollback rule as
/// starting a film.
Future<bool> buyHintWithTicket(
  WidgetRef ref,
  GameMode mode,
  ExtraHint hint,
) async {
  final tickets = ref.read(ticketNotifierProvider.notifier);
  final debit = await tickets.debitTickets(count: hint.ticketCost);
  if (debit == null) return false;

  try {
    await ref
        .read((mode == GameMode.poster ? posterGameProvider : clueGameProvider)
            .notifier)
        .grantHint(hint);
    return true;
  } catch (_) {
    await tickets.refundDebit(debit);
    return false;
  }
}
