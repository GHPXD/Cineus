import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_l10n.dart';

/// Displays the current score with color tier transitions.
/// Gold (10-8) → Blue (7-5) → Amber (4-3) → Ruby (2-1).
class ScoreBadge extends StatelessWidget {
  final int score;
  const ScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(score);
    final gradient = AppColors.scoreDimGradient(score);
    final borderColor = AppColors.scoreBorderColor(score);

    final badge = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text(
                '$score',
                style: AppTypography.scoreLarge.copyWith(color: color),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppL10n.of(context).scorePoints,
                    style: AppTypography.labelSmall.copyWith(
                      color: color,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    AppL10n.of(context).scoreAvailable,
                    style: AppTypography.monoSmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return badge;
  }
}
