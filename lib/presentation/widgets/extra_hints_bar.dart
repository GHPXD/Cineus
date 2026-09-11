import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/extra_hint.dart';
import '../../domain/entities/movie.dart';
import '../../l10n/app_l10n.dart';
import '../l10n_mappers.dart';
import '../providers/game_actions.dart';
import '../providers/play_notifier.dart';
import '../providers/providers.dart';
import 'tap_target.dart';

class ExtraHintsBar extends ConsumerWidget {
  final PlayState state;

  const ExtraHintsBar({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movie = state.movie;
    if (movie == null || state.isFinished) return const SizedBox.shrink();

    final hasTickets = ref.watch(ticketNotifierProvider).hasTickets;
    final purchased = state.purchasedHints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              context.l10n.extraHintsHeader,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              context.l10n.extraHintsNoPointCost,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final hint in ExtraHint.values)
              _HintChip(
                hint: hint,
                label: context.l10n.hintLabel(hint),
                revealedValue: purchased.contains(hint)
                    ? _valueFor(hint, movie, context.l10n)
                    : null,
                enabled: hasTickets,
                onBuy: () => _buy(context, ref, hint),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    ExtraHint hint,
  ) async {
    HapticFeedback.selectionClick();
    final bought = await buyHintWithTicket(ref, state.mode, hint);
    if (bought || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.noTicketsForHint),
        backgroundColor: AppColors.ruby900,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static String _valueFor(ExtraHint hint, Movie movie, AppL10n l10n) {
    return switch (hint) {
      ExtraHint.director =>
        movie.director.isEmpty ? l10n.unknownDirector : movie.director,
      ExtraHint.year => '${movie.year}',
      ExtraHint.runtime => movie.runtime == null || movie.runtime == 0
          ? '—'
          : l10n.runtimeMinutes(movie.runtime!),
    };
  }
}

class _HintChip extends StatelessWidget {
  final ExtraHint hint;
  final String label;
  final String? revealedValue;
  final bool enabled;
  final VoidCallback onBuy;

  const _HintChip({
    required this.hint,
    required this.label,
    required this.revealedValue,
    required this.enabled,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final bought = revealedValue != null;
    final color = bought ? AppColors.blue300 : AppColors.gold300;
    final canBuy = !bought && enabled;
    final semanticLabel = bought
        ? '$label: $revealedValue'
        : AppL10n.of(context).buyHintSemantics(label, hint.ticketCost);

    return TapTarget(
      label: semanticLabel,
      onTap: canBuy ? onBuy : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 42),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: bought ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: enabled || bought ? 0.45 : 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(hint.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                bought ? '$label: $revealedValue' : label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: bought
                      ? AppColors.obsidian0
                      : enabled
                          ? color
                          : AppColors.textTertiary,
                  fontWeight: bought ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            if (!bought) ...[
              const SizedBox(width: 6),
              Text(
                enabled
                    ? AppL10n.of(context).oneTicket
                    : AppL10n.of(context).noTicketsLower,
                style: AppTypography.monoSmall.copyWith(
                  color: enabled ? color : AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}