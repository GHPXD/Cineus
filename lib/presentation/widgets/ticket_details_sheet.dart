import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/daily_selector.dart';
import '../../domain/entities/player_tickets.dart';
import '../../domain/entities/commercial_product.dart';
import '../l10n_mappers.dart';
import '../providers/app_clock.dart';
import '../providers/providers.dart';
import '../providers/commercial_provider.dart';
import '../providers/monetization_notifier.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';
import 'rewarded_tickets_card.dart';
import 'commerce_placeholders.dart';
import 'commercial_offers_panel.dart';

Future<void> showTicketDetails(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: AppColors.obsidian950,
      builder: (_) => const TicketDetailsSheet(),
    );

class TicketDetailsSheet extends ConsumerStatefulWidget {
  const TicketDetailsSheet({super.key});
  @override
  ConsumerState<TicketDetailsSheet> createState() => _TicketDetailsSheetState();
}

class _TicketDetailsSheetState extends ConsumerState<TicketDetailsSheet>
    with WidgetsBindingObserver {
  Timer? _clock;
  String? _day;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _day = DailySelector.todayKey(ref.read(appClockProvider)());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(ticketNotifierProvider.notifier).refreshBalance());
      }
    });
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
  }

  void _tick({bool resumed = false}) {
    if (!mounted) return;
    final day = DailySelector.todayKey(ref.read(appClockProvider)());
    if (resumed || day != _day) {
      _day = day;
      unawaited(ref.read(ticketNotifierProvider.notifier).refreshBalance());
      unawaited(ref.read(monetizationNotifierProvider.notifier).load());
      ref.invalidate(commercialEntitlementsProvider);
    }
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick(resumed: true);
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(ticketNotifierProvider);
    final status = ref.watch(ticketBalanceStatusProvider);
    final l = context.l10n;
    final offers = ref.watch(commercialOffersProvider);
    final access = ref.watch(activeCommercialEntitlementsProvider);
    final membership = access.asData?.value
        .where(
          (right) => CommercialCatalog.byId(
            right.productId,
          )!.benefits.contains(CommercialBenefit.removeInterruptions),
        )
        .firstOrNull;
    final plusAvailable =
        offers.asData?.value.any(
          (offer) => offer.productId == CommercialCatalog.plus.id,
        ) ??
        false;
    final remaining = DailySelector.timeUntilNextChallenge(
      ref.read(appClockProvider)(),
    );
    Widget balance(String label, String value) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.obsidian900,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF243D58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.titleMedium),
        ],
      ),
    );
    return SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * .88,
          ),
          child: SingleChildScrollView(
            key: const ValueKey('ticket-details-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CineusIcon(CineusAssetId.ticket, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.ticketDetailsTitle,
                        style: AppTypography.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const CineusIcon(CineusAssetId.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (status.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (status.hasError) ...[
                  Text(l.ticketBalanceFailed, style: AppTypography.bodyMedium),
                  TextButton(
                    onPressed: () => ref
                        .read(ticketNotifierProvider.notifier)
                        .refreshBalance(),
                    child: Text(l.retryAction),
                  ),
                ] else ...[
                  Text(
                    l.ticketBalance(tickets.total),
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.gold300,
                    ),
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: balance(
                            l.ticketDaily,
                            l.ticketDailyDetail(
                              tickets.dailyTickets,
                              tickets.dailyTickets >
                                      PlayerTickets.maxDailyTickets
                                  ? tickets.dailyTickets
                                  : PlayerTickets.maxDailyTickets,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: balance(
                            l.ticketBonus,
                            tickets.extraTickets.toString(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const RewardedTicketsCard(),
                const SizedBox(height: 12),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 16),
                  trailing: const CineusIcon(CineusAssetId.chevron, size: 18),
                  title: Text(
                    l.ticketLearnMore,
                    style: AppTypography.bodySmall,
                  ),
                  children: [
                    Text(l.ticketUsageInfo, style: AppTypography.bodySmall),
                    const SizedBox(height: 6),
                    Text(l.ticketResetInfo, style: AppTypography.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      l.ticketResetCountdown(
                        remaining.inHours.toString(),
                        remaining.inMinutes
                            .remainder(60)
                            .toString()
                            .padLeft(2, '0'),
                      ),
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (tickets.paidTickets > 0)
                  balance(l.purchasedTickets, '${tickets.paidTickets}'),
                if (ref.watch(commercialConfigurationProvider).tickets)
                  CommercialOffersPanel(
                    productIds: {
                      CommercialCatalog.tickets20.id,
                      CommercialCatalog.tickets60.id,
                    },
                  )
                else
                  const TicketPacksPlaceholder(),
                const SizedBox(height: 20),
                if (membership != null)
                  Container(
                    key: const ValueKey('commerce-active-benefits'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF19170B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF69581D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CineusIcon(CineusAssetId.premium, size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                membership.productId ==
                                        CommercialCatalog.club.id
                                    ? l.commerceClub
                                    : l.commercePlus,
                                style: AppTypography.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.commerceBenefitsActive,
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.commerceAdFreeActive,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  )
                else if (offers.isLoading ||
                    offers.hasError ||
                    access.isLoading ||
                    access.hasError)
                  const CommercialAvailabilityNotice(checkEntitlements: true)
                else if (plusAvailable)
                  CommercialOffersPanel(productIds: {CommercialCatalog.plus.id})
                else
                  Container(
                    key: const ValueKey('plus-offer-placeholder'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF19170B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF69581D)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const CineusIcon(CineusAssetId.premium, size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l.commercePlus,
                                style: AppTypography.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l.commercePlusTerms,
                          style: AppTypography.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: null,
                          child: Text(l.commerceComingSoon),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
