import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/extra_hint.dart';
import '../../domain/entities/game_session.dart';
import 'play_notifier.dart';
import 'providers.dart';
import 'reward_notifier.dart';
import 'stats_notifier.dart';
import 'telemetry_provider.dart';

/// Shared side effects that every entry point into a game must perform.

/// Charges one ticket and then runs [start]. If the load fails, the exact debit
/// is rolled back so a broken navigation/data load can never eat a ticket.
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
    await tickets.refundDebit(debit);
    return false;
  } catch (_) {
    await tickets.refundDebit(debit);
    rethrow;
  }
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

  if (finished != null) {
    unawaited(
      ref.read(productTelemetryProvider).track(
        'game_completed',
        properties: {
          'mode': finished.mode.name,
          'kind': finished.kind.name,
          'outcome': finished.status.name,
          'score': finished.score,
          'revealed_steps': finished.revealedClues,
        },
      ),
    );
  }

  final credit = finished == null
      ? Future<void>.value()
      : ref.read(rewardNotifierProvider.notifier).evaluate(finished);

  credit.whenComplete(() {
    // Rewards can alter cross-mode achievements/ticket totals, so refresh both
    // views even though the finished session belongs to only one mode.
    ref.invalidate(statsNotifierProvider);
    ref.invalidate(posterStatsNotifierProvider);
    ref.invalidate(dailySessionProvider);
    ref.invalidate(recoverableStreakDayProvider);
  });
}

/// Rebuilds the streak-dependent providers after a freeze is bought.
void refreshStreakData(WidgetRef ref) {
  ref.invalidate(statsNotifierProvider);
  ref.invalidate(posterStatsNotifierProvider);
  ref.invalidate(recoverableStreakDayProvider);
}

/// Buys one [hint] for the current game, charging tickets only if the hint can
/// actually be persisted. Failed/duplicate grants are automatically refunded.
Future<bool> buyHintWithTicket(
  WidgetRef ref,
  GameMode mode,
  ExtraHint hint,
) async {
  final tickets = ref.read(ticketNotifierProvider.notifier);
  final debit = await tickets.debitTickets(count: hint.ticketCost);
  if (debit == null) return false;

  try {
    final granted = await ref
        .read((mode == GameMode.poster ? posterGameProvider : clueGameProvider)
            .notifier)
        .grantHint(hint);
    if (granted) {
      unawaited(
        ref.read(productTelemetryProvider).track(
          'extra_hint_bought',
          properties: {
            'mode': mode.name,
            'hint': hint.name,
            'ticket_cost': hint.ticketCost,
          },
        ),
      );
      return true;
    }
    await tickets.refundDebit(debit);
    return false;
  } catch (_) {
    await tickets.refundDebit(debit);
    rethrow;
  }
}
