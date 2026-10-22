import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/commercial_product.dart';
import '../providers/commercial_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';
import 'adaptive_banner.dart';
import '../providers/growth_provider.dart';
import '../providers/monetization_notifier.dart';

/// Reserved inventory, never an advertiser or a simulated impression.
class AdvertisementPlaceholder extends ConsumerWidget {
  const AdvertisementPlaceholder({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(activeCommercialEntitlementsProvider);
    if (access.isLoading ||
        access.hasError ||
        (access.asData?.value.any(
              (e) => CommercialCatalog.byId(
                e.productId,
              )!.benefits.contains(CommercialBenefit.removeInterruptions),
            ) ??
            false)) {
      return const SizedBox.shrink();
    }
    final config = ref.watch(commercialConfigurationProvider);
    final ads = ref.watch(mobileAdsConfigurationProvider);
    final growth = ref.watch(growthConfigurationProvider);
    final holdout = growth.bannerHoldout;
    if (config.banners &&
        ads.enabled(config) &&
        ads.validUnit(ads.bannerUnit, config.environment)) {
      return !growth.ready || holdout
          ? const SizedBox.shrink()
          : const AdaptiveBanner();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF08121E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF23374C)),
      ),
      child: Row(
        children: [
          const CineusIcon(CineusAssetId.video, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.adSpaceLabel,
                  style: AppTypography.labelSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.adSpaceReserved,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EarnTicketsEntry extends StatelessWidget {
  final VoidCallback onTap;
  const EarnTicketsEntry({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF0B1A2A),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFF294661)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CineusIcon(CineusAssetId.video, size: 38),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.earnTickets,
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.earnTicketsSubtitle,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const CineusIcon(CineusAssetId.chevron, size: 20),
          ],
        ),
      ),
    ),
  );
}

class TicketPacksPlaceholder extends StatelessWidget {
  const TicketPacksPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget pack(String title) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.obsidian900,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF29435B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: CineusIcon(CineusAssetId.ticket, size: 34),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: null, child: Text(l.commerceComingSoon)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.ticketPacksTitle, style: AppTypography.titleMedium),
        const SizedBox(height: 6),
        Text(l.ticketPacksNote, style: AppTypography.bodySmall),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth < 290 ||
                MediaQuery.textScalerOf(context).scale(14) > 22) {
              return Column(
                children: [
                  pack(l.ticketPackSmall),
                  const SizedBox(height: 12),
                  pack(l.ticketPackLarge),
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: pack(l.ticketPackSmall)),
                  const SizedBox(width: 12),
                  Expanded(child: pack(l.ticketPackLarge)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class OptionalStorePlaceholder extends StatelessWidget {
  const OptionalStorePlaceholder({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.obsidian900,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFF5B4C28)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const CineusIcon(CineusAssetId.premium, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.commerceOptionalExtras,
                style: AppTypography.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(context.l10n.commerceOptionalBody, style: AppTypography.bodySmall),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: null,
          child: Text(context.l10n.commerceComingSoon),
        ),
      ],
    ),
  );
}
