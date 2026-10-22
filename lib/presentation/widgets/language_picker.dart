import 'cineus_icon.dart';
import '../visuals/cineus_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../providers/locale_notifier.dart';

/// Language selector (D9).
///
/// Offers the device default plus the three supported languages, each named in
/// its own language — a player looking for "Español" should not have to know the
/// Portuguese word for it.
class LanguagePicker extends ConsumerWidget {
  const LanguagePicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(localeNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.languageTitle.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: AppColors.obsidian800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.obsidian600),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final option in LocaleNotifier.options)
                _LanguageRow(
                  label: option == null
                      ? l10n.languageSystem
                      : LocaleNotifier.nameOf(option),
                  isSelected: option?.languageCode == selected?.languageCode,
                  onTap: () =>
                      ref.read(localeNotifierProvider.notifier).select(option),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // The catalogue itself is Portuguese; be upfront rather than let a
        // Spanish player wonder why the clues did not change.
        Text(
          l10n.contentLanguageNote,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected
                        ? AppColors.obsidian0
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                const CineusIcon(
                  CineusAssetId.completed,
                  color: AppColors.gold300,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
