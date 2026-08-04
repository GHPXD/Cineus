import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/daily_selector.dart';
import '../l10n_mappers.dart';

/// Countdown to next daily challenge (midnight).
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  Duration _remaining = DailySelector.timeUntilNextChallenge();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining = DailySelector.timeUntilNextChallenge();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.nextChallengeIn,
          style: AppTypography.overline.copyWith(
            color: AppColors.textQuaternary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: h),
              TextSpan(
                text: ':',
                style: AppTypography.scoreSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              TextSpan(text: m),
              TextSpan(
                text: ':',
                style: AppTypography.scoreSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              TextSpan(text: s),
            ],
            style: AppTypography.scoreSmall.copyWith(
              color: AppColors.obsidian100,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}
