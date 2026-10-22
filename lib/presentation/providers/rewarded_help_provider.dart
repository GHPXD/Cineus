import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/rewarded_help_repository.dart';
import '../../domain/entities/monetization.dart';
import 'app_clock.dart';
import 'providers.dart';
import 'monetization_notifier.dart';
import 'telemetry_provider.dart';
import 'ticket_notifier.dart';

Future<bool> purchaseRoundHelp(
  TicketNotifier tickets,
  Future<bool> Function() grant,
) async {
  final debit = await tickets.debitTickets();
  if (debit == null) return false;
  try {
    if (await grant()) {
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

final rewardedHelpRepositoryProvider = Provider<RewardedHelpRepository>(
  (ref) => RewardedHelpRepository(
    ref.read(databaseProvider),
    ref.read(appClockProvider),
  ),
);
final rewardedHelpUsageProvider = FutureProvider.autoDispose
    .family<HelpVideoUsage?, String>((ref, key) async {
      final usage = await ref.watch(rewardedHelpRepositoryProvider).read(key);
      if (usage?.pending ?? false) {
        final timer = Timer(const Duration(seconds: 3), ref.invalidateSelf);
        ref.onDispose(timer.cancel);
      }
      return usage;
    });

enum HelpResult {
  granted,
  savedAsTickets,
  pending,
  cancelled,
  unavailable,
  failed,
}

/// Captures durable dependencies before the ad opens. UI dismissal never grants
/// help to the next movie or question, nor refunds a successfully saved help.
final rewardedHelpActionsProvider = Provider<RewardedHelpActions>(
  (ref) => RewardedHelpActions(
    ref.read(rewardedHelpRepositoryProvider),
    ref.read(monetizationNotifierProvider.notifier),
    ref.read(productTelemetryProvider),
  ),
);

class RewardedHelpActions {
  final RewardedHelpRepository repository;
  final MonetizationNotifier monetization;
  final ProductTelemetry telemetry;
  bool _busy = false;
  RewardedHelpActions(this.repository, this.monetization, this.telemetry);

  Future<HelpResult> acquire({
    required String gameKey,
    required String option,
    required Future<bool> Function() purchase,
  }) async {
    if (_busy) return HelpResult.unavailable;
    _busy = true;
    try {
      var usage = await repository.read(gameKey);
      if (usage?.used ?? false) return HelpResult.unavailable;
      if (usage?.pending ?? false) {
        await monetization.load();
        usage = await repository.read(gameKey);
        if (usage?.pending ?? false) return HelpResult.pending;
      }
      if (usage == null) {
        if (!monetization.canWatchRewarded) return HelpResult.unavailable;
        if (!await repository.reserve(gameKey, option)) {
          return HelpResult.unavailable;
        }
        final result = await monetization.watchRewardedForHelp(
          onAttempt: (attempt) => repository.bind(gameKey, attempt),
        );
        if (result == RewardedVideoResult.pending) return HelpResult.pending;
        if (result != RewardedVideoResult.rewarded) {
          await repository.cancel(gameKey);
          return switch (result) {
            RewardedVideoResult.cancelled => HelpResult.cancelled,
            RewardedVideoResult.unavailable => HelpResult.unavailable,
            _ => HelpResult.failed,
          };
        }
        await repository.confirmed(gameKey);
        usage = await repository.read(gameKey);
      }
      if (usage?.option != option || !await repository.claim(gameKey, option)) {
        return HelpResult.unavailable;
      }
      // The +2 is already delivered. If this target is gone/finished, the normal
      // ticket purchase refunds its debit and both tickets remain in the wallet.
      final granted = await purchase();
      unawaited(monetization.load());
      await telemetry.record(
        'rewarded_help_delivered',
        properties: {'outcome': granted ? 'help_and_ticket' : 'tickets'},
      );
      return granted ? HelpResult.granted : HelpResult.savedAsTickets;
    } catch (_) {
      return HelpResult.failed;
    } finally {
      _busy = false;
    }
  }
}
