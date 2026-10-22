import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// The character and the full-width controls occupy a single ivory canvas.
class ColorStudio extends StatelessWidget {
  final Widget art, controls;
  final Widget? tools, hint, heading;
  const ColorStudio({
    super.key,
    required this.art,
    required this.controls,
    this.tools,
    this.hint,
    this.heading,
  });
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('colors-studio'),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xffFBF6E8),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.gold200, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (heading != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            child: heading!,
          ),
        Stack(
          children: [
            art,
            if (tools != null) Positioned(top: 0, right: 0, child: tools!),
          ],
        ),
        if (hint != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: hint!),
        Container(
          key: const ValueKey('colors-studio-panel'),
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF101D33), Color(0xFF061121)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.obsidian600),
          ),
          child: controls,
        ),
      ],
    ),
  );
}

/// Gold action surface with a visible disabled state; button semantics stay native.
class ColorActionSurface extends StatelessWidget {
  final Widget child;
  final bool enabled;
  const ColorActionSurface({
    super.key,
    required this.child,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: enabled
          ? const LinearGradient(
              colors: [Color(0xFFFFD650), Color(0xFFFFC42D), Color(0xFFFFDB68)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      color: enabled ? null : AppColors.obsidian600,
      border: enabled
          ? Border.all(color: AppColors.gold100.withValues(alpha: .7))
          : null,
    ),
    child: child,
  );
}
