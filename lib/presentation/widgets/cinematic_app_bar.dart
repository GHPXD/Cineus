import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_l10n.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

/// Shared, scale-aware secondary header; the title can wrap without clipping.
class CinematicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final TextScaler textScaler;
  final CineusAssetId asset;
  const CinematicAppBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.textScaler,
    required this.asset,
    this.actions,
  });

  bool get enlarged => textScaler.scale(16) > 22;
  @override
  Size get preferredSize => Size.fromHeight(enlarged ? 114 : 76);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: preferredSize.height,
    titleSpacing: 8,
    leading: onBack == null
        ? null
        : IconButton(
            onPressed: onBack,
            tooltip: AppL10n.of(context).semBack,
            icon: const CineusIcon(CineusAssetId.back),
          ),
    actions: actions,
    title: Row(
      children: [
        if (!enlarged) ...[
          CineusIcon(asset, size: 30),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            title,
            style: AppTypography.pageTitle.copyWith(
              fontSize: enlarged ? 20 : 24,
            ),
          ),
        ),
      ],
    ),
    shape: const Border(bottom: BorderSide(color: AppColors.obsidian600)),
  );
}
