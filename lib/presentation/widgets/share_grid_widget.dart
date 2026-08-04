import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Wordle-style share grid showing game result as colored squares.
/// Gold = revealed before guess, Green = the winning guess, Gray = unused, Ruby = loss.
class ShareGrid extends StatelessWidget {
  final int revealedClues;
  final bool won;

  const ShareGrid({
    super.key,
    required this.revealedClues,
    required this.won,
  });

  @override
  Widget build(BuildContext context) {
    // The grid restates, in colour, what the score line above already says in
    // words — so it is decoration for a screen reader, not content.
    return ExcludeSemantics(
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        children: List.generate(10, (i) {
          final clueNum = i + 1;
          Color color;

          if (won) {
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
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }),
      ),
    );
  }

  /// Emoji grid for the share message.
  ///
  /// Only the grid: the surrounding sentence is composed by the caller from the
  /// localised template, so the message goes out in the sharer's language.
  String toEmojiGrid() {
    return List.generate(10, (i) {
      final clueNum = i + 1;
      if (won) {
        if (clueNum < revealedClues) return '🟨';
        if (clueNum == revealedClues) return '🟩';
        return '⬛';
      }
      return '🟥';
    }).join();
  }
}
