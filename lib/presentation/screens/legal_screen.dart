import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/release_legal_l10n.dart';

enum LegalDocument { privacy, terms }

class LegalScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final legal = ReleaseLegalL10n.of(context);
    final copy = switch (document) {
      LegalDocument.privacy => legal.privacy,
      LegalDocument.terms => legal.terms,
    };

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/home'),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(copy.title, style: AppTypography.headlineMedium),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  Text(
                    copy.effectiveDate,
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...copy.sections.map(
                    (section) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.$1,
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.gold300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              section.$2,
                              style: AppTypography.bodySmall.copyWith(height: 1.55),
                            ),
                          ],
                        ),
                      ),
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
}
