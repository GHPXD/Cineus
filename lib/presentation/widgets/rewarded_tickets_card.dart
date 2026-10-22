import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/monetization.dart';
import '../l10n_mappers.dart';
import '../providers/monetization_notifier.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

/// A placeholder never opens an ad or grants a reward.
class RewardedTicketsCard extends ConsumerWidget {
  const RewardedTicketsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monetizationNotifierProvider);
    if (ref.watch(hideVideoOffersProvider).asData?.value == true) {
      return const SizedBox.shrink();
    }
    final configured =
        state.rewardedAvailable ||
        ref.watch(rewardedConfigurationReadyProvider);
    final l = context.l10n;
    final capped = state.rewardedRemaining == 0;
    return Container(
      key: const ValueKey('rewarded-ticket-placement'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102740), Color(0xFF07121F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold300.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CineusIcon(CineusAssetId.video, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l.rewardedTitle, style: AppTypography.titleMedium),
              ),
              const SizedBox(width: 8),
              const CineusIcon(CineusAssetId.ticket, size: 24),
              const SizedBox(width: 5),
              Text(
                '+${MonetizationPolicy.rewardedTicketAmount}',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.gold300,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('rewarded-ad-preview'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.obsidian950.withValues(alpha: .65),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF29435B)),
            ),
            child: Column(
              children: [
                const CineusIcon(CineusAssetId.inProgress, size: 38),
                const SizedBox(height: 8),
                Text(
                  !configured ? l.rewardedPreviewLabel : l.adSpaceLabel,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            capped
                ? l.rewardedLimitReached
                : !configured
                ? l.rewardedPlaceholderBody
                : l.rewardedBody(
                    MonetizationPolicy.rewardedTicketAmount,
                    state.rewardedRemaining,
                  ),
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 14),
          FilledButton(
            key: const ValueKey('rewarded-watch'),
            onPressed: state.busy || state.isLoading || capped || !configured
                ? null
                : state.rewardPending
                ? () => ref.read(monetizationNotifierProvider.notifier).load()
                : state.rewardedAvailable
                ? () async {
                    final rewarded = await ref
                        .read(monetizationNotifierProvider.notifier)
                        .watchRewardedForTickets();
                    if (!context.mounted) return;
                    final failed = ref
                        .read(monetizationNotifierProvider)
                        .hasError;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          rewarded
                              ? l.rewardedDone
                              : ref
                                    .read(monetizationNotifierProvider)
                                    .rewardPending
                              ? l.helpPendingBody
                              : failed
                              ? l.rewardedFailed
                              : l.rewardedCancelled,
                        ),
                      ),
                    );
                  }
                : () => ref.read(monetizationNotifierProvider.notifier).load(),
            child: Text(
              state.busy
                  ? l.rewardedWatching
                  : state.rewardPending
                  ? l.helpPending
                  : state.isLoading
                  ? l.rewardedLoading
                  : capped
                  ? l.rewardedLimitReached
                  : !configured
                  ? l.commerceComingSoon
                  : state.rewardedAvailable
                  ? l.rewardedAction(MonetizationPolicy.rewardedTicketAmount)
                  : l.rewardedRetry,
            ),
          ),
          if (configured &&
              !state.rewardedAvailable &&
              !state.isLoading &&
              !capped) ...[
            const SizedBox(height: 8),
            Text(
              l.rewardedUnavailable,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
