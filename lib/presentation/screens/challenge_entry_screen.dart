import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../widgets/settings_section.dart';
import '../widgets/tap_target.dart';

class ChallengeEntryScreen extends StatelessWidget {
  const ChallengeEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  TapTarget(
                    label: context.l10n.semBack,
                    onTap: () => context.pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      context.l10n.challengeOpenTitle,
                      style: AppTypography.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldDimGradient,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold300.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            '🎬',
                            style: TextStyle(fontSize: 34),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.l10n.challengeSectionTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.quickActionChallengeSub,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const ChallengeCodeOpener(showHeading: false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}