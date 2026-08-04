import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_l10n.dart';

/// Displays the current score with color tier transitions.
/// Gold (10-8) → Blue (7-5) → Amber (4-3) → Ruby (2-1, pulsing).
class ScoreBadge extends StatelessWidget {
  final int score;
  final int revealedClues;
  final bool compact;

  const ScoreBadge({
    super.key,
    required this.score,
    required this.revealedClues,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.scoreColor(score);
    final gradient = AppColors.scoreDimGradient(score);
    final borderColor = AppColors.scoreBorderColor(score);

    final isUrgent = score <= 2;
    final badge = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: compact ? 10 : 16,
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: (compact ? AppTypography.scoreMedium : AppTypography.scoreLarge)
                    .copyWith(color: color),
              ),
              const SizedBox(width: 10),
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
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              _hintText(AppL10n.of(context), score, revealedClues),
              style: AppTypography.bodySmall.copyWith(
                color: color.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );

    if (isUrgent) {
      return _PulsingWrapper(child: badge);
    }
    return badge;
  }

  String _hintText(AppL10n l10n, int score, int revealed) {
    if (score >= 9) return l10n.scoreHintMax;
    if (score >= 5) return l10n.scoreHintStillWorth(revealed);
    if (score >= 3) return l10n.scoreHintRunningOut;
    if (score >= 2) return l10n.scoreHintNextLeaves(revealed + 1, score - 1);
    return l10n.scoreHintLastChance;
  }
}

class _PulsingWrapper extends StatefulWidget {
  final Widget child;

  const _PulsingWrapper({required this.child});

  @override
  State<_PulsingWrapper> createState() => _PulsingWrapperState();
}

class _PulsingWrapperState extends State<_PulsingWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.ruby300.withValues(alpha: 0.3 * _anim.value),
              blurRadius: 48 * _anim.value,
              spreadRadius: -4,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
