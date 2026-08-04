import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../providers/providers.dart';

class HowToPlayScreen extends ConsumerWidget {
  final VoidCallback onDismiss;

  /// First-run presentation: hides the close button (there is nothing to go back
  /// to) and records that the guide was seen so it never shows again.
  final bool isOnboarding;

  const HowToPlayScreen({
    super.key,
    required this.onDismiss,
    this.isOnboarding = false,
  });

  Future<void> _dismiss(WidgetRef ref) async {
    if (isOnboarding) {
      await ref.read(appMetaRepositoryProvider).markOnboardingSeen();
      ref.invalidate(onboardingSeenProvider);
    }
    onDismiss();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.obsidian900,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  if (!isOnboarding)
                    IconButton(
                      onPressed: () => _dismiss(ref),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  Text(
                    l10n.quickGuide,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.gold300,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  Text(
                    l10n.howItWorks,
                    style: AppTypography.displaySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _RuleCard(
                    emoji: '🎞️',
                    bgColor: AppColors.gold300.withValues(alpha: 0.12),
                    title: l10n.rule1Title,
                    description:
                        l10n.rule1Desc,
                  ),
                  const SizedBox(height: 12),

                  _RuleCard(
                    emoji: '🏆',
                    bgColor: AppColors.gold300.withValues(alpha: 0.12),
                    title: l10n.rule2Title,
                    description:
                        l10n.rule2Desc,
                    child: _buildScorePips(),
                  ),
                  const SizedBox(height: 12),

                  _RuleCard(
                    emoji: '🌐',
                    bgColor: AppColors.blue300.withValues(alpha: 0.12),
                    title: l10n.rule3Title,
                    description:
                        l10n.rule3Desc,
                  ),
                  const SizedBox(height: 12),

                  _RuleCard(
                    emoji: '📅',
                    bgColor: AppColors.success400.withValues(alpha: 0.12),
                    title: l10n.rule4Title,
                    description:
                        l10n.rule4Desc,
                  ),
                ],
              ),
            ),

            // CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => _dismiss(ref),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.gotItLetsPlay),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScorePips() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: List.generate(AppConstants.totalClues, (i) {
          final score = 10 - i;
          final color = AppColors.scoreColor(score);
          return Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            alignment: Alignment.center,
            child: Text(
              '$score',
              style: AppTypography.monoSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final String emoji;
  final Color bgColor;
  final String title;
  final String description;
  final Widget? child;

  const _RuleCard({
    required this.emoji,
    required this.bgColor,
    required this.title,
    required this.description,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(height: 1.7),
                ),
                if (child != null) child!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
