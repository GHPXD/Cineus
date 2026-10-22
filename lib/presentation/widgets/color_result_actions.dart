import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/saved_color_session.dart';
import '../../l10n/app_l10n.dart';
import '../providers/color_providers.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';
import 'color_share_card.dart';
import 'editorial_feedback.dart';
import 'result_break.dart';
import 'ticket_details_sheet.dart';

class ColorResultActions extends ConsumerStatefulWidget {
  final SavedColorSession session;
  const ColorResultActions({super.key, required this.session});
  @override
  ConsumerState<ColorResultActions> createState() => _ColorResultActionsState();
}

class _ColorResultActionsState extends ConsumerState<ColorResultActions> {
  bool _sharing = false;
  bool _opening = false;
  Future<void> _practice() async {
    if (_opening) return;
    setState(() => _opening = true);
    final repo = ref.read(colorRepositoryProvider);
    try {
      final next = await repo.review(widget.session);
      if (mounted) {
        context.pushReplacement(
          '/colors/session/${Uri.encodeComponent(next.id)}',
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _next() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await maybeShowResultBreak(
        ref,
        'colors:${widget.session.id}',
        isCurrent: () =>
            mounted && (ModalRoute.of(context)?.isCurrent ?? false),
      );
      if (!mounted) return;
      final stages = await ref.read(colorStageProgressProvider.future);
      final current = stages
          .where((s) => s.stage.id == widget.session.stageId)
          .firstOrNull;
      final next = current != null && !current.finished
          ? current
          : stages.where((s) => !s.locked && !s.finished).firstOrNull;
      if (!mounted) return;
      if (next == null) {
        context.go('/colors');
        return;
      }
      final match =
          List.generate(
            next.stage.matches,
            (i) => i,
          ).where((i) => next.record(i)?.status != 'completed').firstOrNull ??
          0;
      final record = await startColorStage(
        ref,
        next.stage.id,
        match < 0 ? 0 : match,
      );
      if (record != null && mounted) {
        context.pushReplacement(
          '/colors/session/${Uri.encodeComponent(record.id)}',
        );
      } else if (mounted) {
        await showTicketDetails(context);
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    _sharing = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        showDragHandle: true,
        builder: (_) =>
            ColorSharePanel(data: ColorShareData.fromSession(widget.session)),
      );
    } finally {
      _sharing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context),
        daily = widget.session.kind == ColorSessionKind.daily;
    final reward = daily
        ? ref.watch(colorDailyRewardProvider(widget.session.id))
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.session.isStage)
          FilledButton(
            onPressed: _opening ? null : _next,
            child: Text(l.nextAction),
          ),
        if (daily)
          Container(
            key: const ValueKey('colors-reward-status'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blue300.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CineusIcon(CineusAssetId.ticket, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reward!.isLoading
                            ? l.colorRewardSaving
                            : reward.hasError
                            ? l.colorRewardFailed
                            : l.colorRewardEarned,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (reward.hasError)
                  TextButton(
                    key: const ValueKey('colors-reward-retry'),
                    onPressed: () => ref.invalidate(
                      colorDailyRewardProvider(widget.session.id),
                    ),
                    child: Text(l.colorRetry),
                  ),
              ],
            ),
          ),
        if (daily) const SizedBox(height: 16),
        OutlinedButton.icon(
          key: const ValueKey('colors-open-share'),
          onPressed: _share,
          icon: const CineusIcon(CineusAssetId.share, size: 20),
          label: Text(l.shareCardTitle),
        ),
        TextButton(
          onPressed: _opening ? null : _practice,
          child: Text(l.practiceAgain),
        ),
        TextButton.icon(
          key: const ValueKey('colors-result-stats'),
          onPressed: () => context.go('/colors/stats'),
          icon: const CineusIcon(CineusAssetId.stats, size: 20),
          label: Text(l.colorStatsTitle),
        ),
        EditorialFeedbackButton(
          mode: 'colors',
          question: widget.session.game.questions.last.id,
        ),
      ],
    );
  }
}
