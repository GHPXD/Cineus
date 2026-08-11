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
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
            color: AppColors.textQuaternary,
            fontSize: 11,
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
                        : AppColors.obsidian200,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
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
