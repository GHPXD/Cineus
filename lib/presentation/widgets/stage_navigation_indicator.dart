import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

/// A decorative indicator; the whole stage card is the accessible tap target.
class StageNavigationIndicator extends StatelessWidget {
  final bool locked, completed;
  const StageNavigationIndicator({
    super.key,
    required this.locked,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: locked ? const Color(0xCC18293E) : null,
        border: locked ? null : Border.all(color: AppColors.gold300),
      ),
      child: Center(
        child: locked
            ? const ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Color(0xFFAFBBD4),
                  BlendMode.srcIn,
                ),
                child: CineusIcon(CineusAssetId.lock, size: 17),
              )
            : CineusIcon(
                completed ? CineusAssetId.completed : CineusAssetId.chevron,
                size: 17,
                color: AppColors.gold300,
              ),
      ),
    ),
  );
}
