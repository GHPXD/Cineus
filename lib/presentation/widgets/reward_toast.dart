import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_l10n.dart';
import '../l10n_mappers.dart';
import '../providers/reward_notifier.dart';

/// Shows a snackbar whenever tickets are credited (D1), then acknowledges them.
///
/// Wrap any screen where a reward can land. Acknowledging inside the listener is
/// what keeps a reward from being announced twice if two wrapped screens are
/// alive at the same time.
class RewardToast extends ConsumerWidget {
  final Widget child;

  const RewardToast({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<RewardFeed>(rewardNotifierProvider, (prev, next) {
      if (!next.hasPending) return;

      final l10n = AppL10n.of(context);
      final reasons =
          next.pending.map(l10n.rewardReason).join(' · ');
      final total = next.totalAmount;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🎫', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.ticketsEarned(total),
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.obsidian900,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      reasons,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.obsidian800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.gold300,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      ref.read(rewardNotifierProvider.notifier).acknowledge();
    });

    return child;
  }
}
