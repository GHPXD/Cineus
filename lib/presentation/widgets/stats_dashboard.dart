import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

class StatsPanel extends StatelessWidget {
  final Widget child;
  final bool highlighted;
  const StatsPanel({super.key, required this.child, this.highlighted = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF14243E), Color(0xFF081325)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: highlighted
            ? AppColors.gold200.withValues(alpha: .65)
            : const Color(0xFF273C59),
      ),
    ),
    child: child,
  );
}

class StatsGrid extends StatelessWidget {
  final List<Widget> children;
  const StatsGrid({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final columns = scale > 1.3 && c.maxWidth < 380
          ? 1
          : c.maxWidth >= 620 && scale <= 1.3
          ? 4
          : 2;
      return Column(
        children: [
          for (var start = 0; start < children.length; start += columns) ...[
            if (start > 0) const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: 10),
                    Expanded(
                      child: start + column < children.length
                          ? children[start + column]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

class StatsMetric extends StatelessWidget {
  final String label, value;
  final String? subtitle;
  final CineusAssetId icon;
  final Color color;
  const StatsMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color = AppColors.gold200,
  });
  @override
  Widget build(BuildContext context) => StatsPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CineusIcon(icon, size: 28),
        const SizedBox(height: 12),
        Text(
          value,
          style: AppTypography.scoreSmall.copyWith(color: color, fontSize: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: AppTypography.bodySmall.copyWith(fontSize: 11),
          ),
      ],
    ),
  );
}

/// Equal-width mode selectors, with a vertical fallback for large text.
class StatsTabs extends StatelessWidget {
  final List<Widget> children;
  const StatsTabs({super.key, required this.children});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final stacked = MediaQuery.textScalerOf(context).scale(14) > 22;
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF101D32),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF273C59)),
        ),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              )
            : Row(
                children: [
                  for (final child in children) Expanded(child: child),
                ],
              ),
      );
    },
  );
}

class StatsTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final CineusAssetId? icon;
  const StatsTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? AppColors.gold200 : Colors.transparent,
        foregroundColor: selected
            ? AppColors.obsidian950
            : AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        textStyle: AppTypography.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            CineusIcon(icon!, size: 25, color: AppColors.gold200),
            const SizedBox(height: 6),
          ],
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
