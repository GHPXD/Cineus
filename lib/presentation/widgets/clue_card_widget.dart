import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/clue.dart';
import '../../l10n/app_l10n.dart';

enum ClueCardState { revealed, locked, next }

class ClueCard extends StatelessWidget {
  final Clue? clue;
  final int clueNumber;
  final String category;
  final ClueCardState cardState;
  final bool isLatest;

  const ClueCard({
    super.key,
    this.clue,
    required this.clueNumber,
    required this.category,
    required this.cardState,
    this.isLatest = false,
  });

  @override
  Widget build(BuildContext context) {
    return switch (cardState) {
      ClueCardState.revealed => _buildRevealed(context),
      ClueCardState.locked => _buildLocked(context),
      ClueCardState.next => _buildNext(context),
    };
  }

  Widget _buildRevealed(BuildContext context) {
    final emoji = AppConstants.emojiForCategory(category);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isLatest ? null : AppColors.cardGradient,
        color: isLatest ? null : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLatest
              ? AppColors.blue300.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.09),
          width: isLatest ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ClueNumberBadge(
                number: clueNumber,
                color: isLatest ? AppColors.blue300 : AppColors.gold300,
                bgColor: isLatest
                    ? AppColors.blue300.withValues(alpha: 0.18)
                    : AppColors.gold300.withValues(alpha: 0.12),
              ),
              const SizedBox(width: 10),
              Text(
                category.toUpperCase(),
                style: AppTypography.overline.copyWith(
                  color: isLatest ? AppColors.blue300 : AppColors.obsidian300,
                ),
              ),
              const Spacer(),
              if (isLatest)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blue300.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.blue300.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    AppL10n.of(context).clueNew,
                    style: AppTypography.overline.copyWith(
                      fontSize: 9,
                      color: AppColors.blue200,
                      letterSpacing: 1,
                    ),
                  ),
                )
              else
                Text(emoji, style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            clue?.text ?? '',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.obsidian100,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocked(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.025),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            _ClueNumberBadge(
              number: clueNumber,
              color: AppColors.textTertiary,
              bgColor: Colors.white.withValues(alpha: 0.04),
            ),
            const SizedBox(width: 10),
            Text(
              category.toUpperCase(),
              style: AppTypography.overline.copyWith(
                color: AppColors.textQuaternary,
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.lock_rounded,
              size: 14,
              color: AppColors.textQuaternary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNext(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.blueDimGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.blue300.withValues(alpha: 0.4),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: Row(
        children: [
          _ClueNumberBadge(
            number: clueNumber,
            color: AppColors.blue300,
            bgColor: AppColors.blue300.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 10),
          Text(
            category.toUpperCase(),
            style: AppTypography.overline.copyWith(
              color: AppColors.blue300,
            ),
          ),
          const Spacer(),
          Text(
            '• • • • • •',
            style: AppTypography.monoSmall.copyWith(
              color: AppColors.blue300.withValues(alpha: 0.4),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClueNumberBadge extends StatelessWidget {
  final int number;
  final Color color;
  final Color bgColor;

  const _ClueNumberBadge({
    required this.number,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString().padLeft(2, '0'),
        style: AppTypography.monoSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}
