import 'package:flutter/material.dart';

import '../l10n_mappers.dart';
import '../../core/theme/app_colors.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

void showFranchiseHintSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const CineusIcon(
            CineusAssetId.lastAttempt,
            color: AppColors.obsidian950,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.franchiseHint,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.gold700,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
