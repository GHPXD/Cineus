import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/extra_hint.dart';
import '../../domain/entities/game_session.dart';
import 'play_notifier.dart';
import 'providers.dart';
import 'reward_notifier.dart';
import 'stats_notifier.dart';
import 'telemetry_provider.dart';
import 'progress_provider.dart';
import 'journey_provider.dart';
import '../screens/mastery_screen.dart';
import 'growth_provider.dart';
import '../../data/services/friendly_challenges.dart';

/// Shared side effects that every entry point into a game must perform.
final finishedGameRefreshProvider = Provider<void Function()>((ref) {
  var active = true;
  ref.onDispose(() => active = false);
  return () {
    if (!active) {
      return;
    }
    ref.invalidate(statsNotifierProvider);
    ref.invalidate(posterStatsNotifierProvider);
    ref.invalidate(dailySessionProvider);
    ref.invalidate(recoverableStreakDayProvider);
    ref.invalidate(presenceProvider);
    ref.invalidate(continuingGameProvider);
    ref.invalidate(journeyProgressProvider);
    ref.invalidate(masteryProvider);
  };
});

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
    if (started) {
      await tickets.completeDebit(debit);
      return true;
    }
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
        .read(
          mode == GameMode.poster
              ? posterStageNotifierProvider.notifier
              : stageNotifierProvider.notifier,
        )
        .load();
  }

  if (finished != null) {
    final gateway = ref.read(growthGatewayProvider);
    if (gateway != null) {
      unawaited(
        FriendlyChallenges(
          ref.read(databaseProvider),
          gateway,
        ).flush().catchError((Object _) {}),
      );
    }
    unawaited(
      ref
          .read(productTelemetryProvider)
          .record(
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

  final refresh = ref.read(finishedGameRefreshProvider);
  final rewards = ref.read(rewardNotifierProvider.notifier);
  final credit = finished == null
      ? Future<void>.value()
      : rewards.evaluate(finished);

  // A victory replaces the game page before rewards finish. Capture a callback
  // owned by the provider scope; the old page's WidgetRef is already disposed.
  unawaited(
    credit.then<void>(
      (_) => refresh(),
      onError: (Object error, StackTrace stack) {
        if (finished != null) {
          rewards.reportFailure(finished);
        }
        refresh();
      },
    ),
  );
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
  ExtraHint hint, {
  int? expectedSessionId,
}) async {
  final tickets = ref.read(ticketNotifierProvider.notifier);
  // Capture dependencies before awaits: leaving the screen disposes WidgetRef,
  // but must not turn a successfully persisted hint into a refunded free hint.
  final game = ref.read(
    (mode == GameMode.poster ? posterGameProvider : clueGameProvider).notifier,
  );
  final telemetry = ref.read(productTelemetryProvider);
  final debit = await tickets.debitTickets(count: hint.ticketCost);
  if (debit == null) return false;

  try {
    final granted = await game.grantHint(
      hint,
      expectedSessionId: expectedSessionId,
    );
    if (granted) {
      await tickets.completeDebit(debit);
      unawaited(
        telemetry.record(
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
