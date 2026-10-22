import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../providers/monetization_notifier.dart';
import '../providers/providers.dart';
import '../providers/rewarded_help_provider.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

class RoundHelpOption {
  final String id, title;
  final String? detail;
  final CineusAssetId asset;
  final Future<bool> Function() purchase;
  const RoundHelpOption({
    required this.id,
    required this.title,
    required this.asset,
    required this.purchase,
    this.detail,
  });
}

Future<void> showRoundHelp(
  BuildContext context, {
  required String gameKey,
  required List<RoundHelpOption> options,
  Future<bool> Function()? freeHint,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  showDragHandle: true,
  backgroundColor: AppColors.obsidian950,
  builder: (_) =>
      RoundHelpSheet(gameKey: gameKey, options: options, freeHint: freeHint),
);

class RoundHelpSheet extends ConsumerStatefulWidget {
  final String gameKey;
  final List<RoundHelpOption> options;
  final Future<bool> Function()? freeHint;
  const RoundHelpSheet({
    super.key,
    required this.gameKey,
    required this.options,
    this.freeHint,
  });
  @override
  ConsumerState<RoundHelpSheet> createState() => _RoundHelpSheetState();
}

class _RoundHelpSheetState extends ConsumerState<RoundHelpSheet> {
  String? _selected;
  bool _busy = false;
  String? _message;

  Future<void> _run(
    Future<HelpResult> Function() action, {
    bool video = false,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    final l = context.l10n;
    try {
      final result = await action();
      if (!mounted) return;
      if (result == HelpResult.granted || result == HelpResult.savedAsTickets) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        if (video) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                result == HelpResult.granted ? l.helpDone : l.helpStored,
              ),
            ),
          );
        }
      } else {
        ref.invalidate(rewardedHelpUsageProvider(widget.gameKey));
        setState(
          () => _message = switch (result) {
            HelpResult.pending => l.helpPendingBody,
            HelpResult.cancelled => l.rewardedCancelled,
            HelpResult.unavailable => l.rewardedUnavailable,
            _ => l.hintSaveFailed,
          },
        );
      }
    } catch (_) {
      if (mounted) setState(() => _message = l.hintSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final usageState = ref.watch(rewardedHelpUsageProvider(widget.gameKey));
    final usage = usageState.asData?.value;
    final ads = ref.watch(monetizationNotifierProvider);
    final configured =
        ads.rewardedAvailable || ref.watch(rewardedConfigurationReadyProvider);
    final hideVideos = ref.watch(hideVideoOffersProvider).asData?.value == true;
    final balance = ref.watch(ticketNotifierProvider);
    final balanceStatus = ref.watch(ticketBalanceStatusProvider);
    final bound = usage != null && !usage.used;
    final selectedId = bound ? usage.option : _selected;
    final selected =
        widget.options.where((o) => o.id == selectedId).firstOrNull ??
        widget.options.firstOrNull;
    final videoOption = bound
        ? widget.options.where((o) => o.id == usage.option).firstOrNull
        : selected;
    final disabled =
        _busy || ads.busy || balanceStatus.isLoading || balanceStatus.hasError;
    return SafeArea(
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * .88,
          ),
          child: SingleChildScrollView(
            key: const ValueKey('round-help-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CineusIcon(CineusAssetId.help, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(l.helpTitle, style: AppTypography.titleLarge),
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
                const SizedBox(height: 16),
                if (widget.options.isEmpty)
                  Text(l.helpNoAvailable, style: AppTypography.bodyMedium),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in widget.options)
                      ChoiceChip(
                        key: ValueKey('help-option-${option.id}'),
                        avatar: CineusIcon(option.asset, size: 20),
                        showCheckmark: false,
                        label: Text(option.title),
                        selected: selected?.id == option.id,
                        onSelected: disabled || bound
                            ? null
                            : (_) => setState(() => _selected = option.id),
                      ),
                  ],
                ),
                if (selected?.detail case final String detail) ...[
                  const SizedBox(height: 12),
                  Text(detail, style: AppTypography.bodySmall),
                ],
                const SizedBox(height: 18),
                Text(
                  balanceStatus.hasError
                      ? l.ticketBalanceFailed
                      : l.ticketBalance(balance.total),
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('help-pay-ticket'),
                  onPressed: disabled || !balance.hasTickets || selected == null
                      ? null
                      : () {
                          final choice = bound && videoOption != null
                              ? videoOption
                              : widget.options
                                        .where((o) => o.id == _selected)
                                        .firstOrNull ??
                                    selected;
                          _run(
                            () async => await choice.purchase()
                                ? HelpResult.granted
                                : HelpResult.failed,
                          );
                        },
                  icon: const CineusIcon(
                    CineusAssetId.ticket,
                    size: 22,
                    color: AppColors.obsidian950,
                  ),
                  label: Text(l.helpUseTicket),
                ),
                if (!hideVideos) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const ValueKey('help-watch-video'),
                    onPressed:
                        disabled ||
                            usageState.isLoading ||
                            usageState.hasError ||
                            (usage?.used ?? false) ||
                            (!configured && usage == null) ||
                            (ads.isLoading && usage == null) ||
                            (ads.rewardedRemaining == 0 && usage == null)
                        ? null
                        : () {
                            final actions = ref.read(
                              rewardedHelpActionsProvider,
                            );
                            final choice = bound
                                ? videoOption
                                : widget.options
                                          .where((o) => o.id == _selected)
                                          .firstOrNull ??
                                      selected;
                            if (choice == null) {
                              if (usage != null) {
                                _run(
                                  () => actions.acquire(
                                    gameKey: widget.gameKey,
                                    option: usage.option,
                                    purchase: () async => false,
                                  ),
                                  video: true,
                                );
                              }
                              return;
                            }
                            if (!ads.rewardedAvailable && usage == null) {
                              ref
                                  .read(monetizationNotifierProvider.notifier)
                                  .load();
                              return;
                            }
                            _run(
                              () => actions.acquire(
                                gameKey: widget.gameKey,
                                option: choice.id,
                                purchase: choice.purchase,
                              ),
                              video: true,
                            );
                          },
                    icon: const CineusIcon(CineusAssetId.video, size: 23),
                    label: Text(
                      _busy || ads.busy
                          ? l.rewardedWatching
                          : usage?.pending == true
                          ? l.helpPending
                          : usage?.ready == true
                          ? l.helpClaim
                          : usage?.used == true
                          ? l.helpVideoUsed
                          : !configured
                          ? l.helpVideoSoon
                          : ads.rewardedRemaining == 0
                          ? l.rewardedLimitReached
                          : ads.isLoading
                          ? l.rewardedLoading
                          : !ads.rewardedAvailable
                          ? l.rewardedRetry
                          : l.helpWatch,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (usage?.used != true)
                    Text(
                      usage?.pending == true
                          ? l.helpPendingBody
                          : l.helpAdOffer,
                      style: AppTypography.bodySmall,
                    ),
                  const SizedBox(height: 6),
                  Text(l.helpVideoTerms, style: AppTypography.bodySmall),
                ],
                if (usageState.hasError)
                  TextButton(
                    onPressed: () => ref.invalidate(
                      rewardedHelpUsageProvider(widget.gameKey),
                    ),
                    child: Text(l.retryAction),
                  ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(_message!, style: AppTypography.bodyMedium),
                  ),
                ],
                if (widget.freeHint != null) ...[
                  const SizedBox(height: 18),
                  const Divider(),
                  TextButton(
                    key: const ValueKey('help-free-hint'),
                    onPressed: disabled
                        ? null
                        : () => _run(
                            () async => await widget.freeHint!()
                                ? HelpResult.granted
                                : HelpResult.failed,
                          ),
                    child: Text(l.helpColorSimple),
                  ),
                  Text(
                    l.helpColorSimpleBody,
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
