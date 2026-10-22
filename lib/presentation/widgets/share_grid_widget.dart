import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Wordle-style share grid showing game result as colored squares.
/// Gold = revealed before guess, Green = the winning guess, Gray = unused, Ruby = loss.
class ShareGrid extends StatelessWidget {
  final int revealedClues;
  final bool won;
  final int totalSteps;
  final int? score;

  const ShareGrid({
    super.key,
    required this.revealedClues,
    required this.won,
    this.totalSteps = 10,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    // The grid restates, in colour, what the score line above already says in
    // words — so it is decoration for a screen reader, not content.
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = score != null && constraints.maxWidth.isFinite
            ? ((constraints.maxWidth - 3 * (totalSteps - 1)) / totalSteps)
                  .clamp(1.0, 26.0)
            : 26.0;
        return ExcludeSemantics(
          child: Wrap(
            alignment: score != null
                ? WrapAlignment.center
                : WrapAlignment.start,
            spacing: 3,
            runSpacing: 3,
            children: List.generate(totalSteps, (i) {
              final clueNum = i + 1;
              Color color;

              if (score != null) {
                color = !won || clueNum <= revealedClues
                    ? scoreColor
                    : AppColors.obsidian600;
              } else if (won) {
                if (clueNum < revealedClues) {
                  color = AppColors.gold300;
                } else if (clueNum == revealedClues) {
                  color = AppColors.success400;
                } else {
                  color = AppColors.obsidian600;
                }
              } else {
                color = AppColors.ruby800;
              }

              return Container(
                width: tileWidth,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  double get performance => (score! / totalSteps).clamp(0.0, 1.0);

  Color get scoreColor => performance >= .7
      ? AppColors.success400
      : performance >= .4
      ? AppColors.gold300
      : AppColors.ruby300;

  /// Emoji grid for the share message.
  ///
  /// Only the grid: the surrounding sentence is composed by the caller from the
  /// localised template, so the message goes out in the sharer's language.
  String toEmojiGrid() {
    return List.generate(totalSteps, (i) {
      final clueNum = i + 1;
      if (score != null) {
        if (won && clueNum > revealedClues) return '⬛';
        return performance >= .7
            ? '🟩'
            : performance >= .4
            ? '🟨'
            : '🟥';
      }
      if (won) {
        if (clueNum < revealedClues) return '🟨';
        if (clueNum == revealedClues) return '🟩';
        return '⬛';
      }
      return '🟥';
    }).join();
  }
}
