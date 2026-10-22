import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Decorative film strip bar reminiscent of 35mm film perforations.
class FilmStrip extends StatelessWidget {
  final double height;
  final int perforations;

  const FilmStrip({super.key, this.height = 20, this.perforations = 18});

  @override
  Widget build(BuildContext context) {
    // Purely decorative: nothing here carries information, so screen readers
    // should skip it rather than announce 18 anonymous nodes.
    return ExcludeSemantics(
      child: Container(
        height: height,
        color: AppColors.obsidian950,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: List.generate(
            perforations,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
