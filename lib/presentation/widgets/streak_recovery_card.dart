import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../providers/game_actions.dart';
import '../l10n_mappers.dart';
import '../providers/providers.dart';
import '../providers/reward_notifier.dart';

class StreakRecoveryCard extends ConsumerStatefulWidget {
  const StreakRecoveryCard({super.key});

  @override
  ConsumerState<StreakRecoveryCard> createState() => _StreakRecoveryCardState();
}

class _StreakRecoveryCardState extends ConsumerState<StreakRecoveryCard> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final recoverable = ref.watch(recoverableStreakDayProvider).valueOrNull;
    if (recoverable == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final tickets = ref.watch(ticketNotifierProvider);
    const cost = RewardNotifier.streakFreezeCost;
    final canAfford = tickets.total >= cost;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.amberDimGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amber400.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.streakAtRisk,
                    style: AppTypography.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.streakRecoverBody(_formatDay(recoverable), cost),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.obsidian200,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: canAfford && !_working
                    ? () => _recover(recoverable)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber400,
                  foregroundColor: AppColors.obsidian900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _working
                      ? l10n.protecting
                      : canAfford
                      ? l10n.protectStreak(cost)
                      : l10n.needTickets(cost),
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.obsidian900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recover(String date) async {
    setState(() => _working = true);
    HapticFeedback.mediumImpact();

    final tickets = ref.read(ticketNotifierProvider.notifier);
    final ok = await ref
        .read(rewardNotifierProvider.notifier)
        .freezeMissedDay(
          date: date,
          charge: (cost) => tickets.debitTickets(count: cost),
          refund: tickets.refundDebit,
        );

    if (!mounted) return;
    setState(() => _working = false);

    if (ok) {
      refreshStreakData(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.streakProtected),
          backgroundColor: AppColors.success500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  static String _formatDay(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    return '${parts[2]}/${parts[1]}';
  }
}
