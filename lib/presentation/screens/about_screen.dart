import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/release_legal_l10n.dart';
import '../l10n_mappers.dart';
import '../widgets/support_card.dart';
import '../widgets/cineus_brand.dart';
import '../widgets/cineus_icon.dart';
import '../visuals/cineus_assets.dart';

/// Player-facing credits and third-party attribution.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final copy = ReleaseLegalL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: copy.aboutTitle),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.goldDimGradient,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.gold300.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CineusBrandMark(size: 104),
                            const SizedBox(height: 12),
                            Text(
                              'Cineus',
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.gold300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              copy.appSummary,
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        title: copy.dataCreditsTitle,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              copy.tmdbExplanation,
                              style: AppTypography.bodySmall,
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.blue500.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.blue300.withValues(
                                    alpha: 0.24,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/credits/tmdb_official.png',
                                    key: const ValueKey('tmdb-credits'),
                                    width: 96,
                                    semanticLabel: 'The Movie Database',
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'TMDB',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.blue300,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const SelectableText(
                                    ReleaseLegalL10n.tmdbNotice,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _Section(
                        title: copy.legalTitle,
                        child: Column(
                          children: [
                            _LegalTile(
                              icon: CineusAssetId.privacy,
                              label: copy.privacyLabel,
                              onTap: () => context.push('/privacy'),
                            ),
                            const Divider(height: 1),
                            _LegalTile(
                              icon: CineusAssetId.terms,
                              label: copy.termsLabel,
                              onTap: () => context.push('/terms'),
                            ),
                            const Divider(height: 1),
                            _LegalTile(
                              icon: CineusAssetId.terms,
                              label: context.l10n.fontLicensesTitle,
                              onTap: () => context.push('/font-licenses'),
                            ),
                            const Divider(height: 1),
                            _LegalTile(
                              icon: CineusAssetId.modeColors,
                              label: context.l10n.colorCreditsTitle,
                              onTap: () => context.push('/colors/credits'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const SupportCard(),
                      const SizedBox(height: 12),
                      Text(
                        copy.contact,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

class _Header extends StatelessWidget {
  final String title;

  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.semBack,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            icon: const CineusIcon(CineusAssetId.back, size: 18),
            color: Colors.white,
          ),
          Expanded(child: Text(title, style: AppTypography.headlineMedium)),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  final CineusAssetId icon;
  final String label;
  final VoidCallback onTap;

  const _LegalTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CineusIcon(icon, color: AppColors.gold300),
      title: Text(label, style: AppTypography.titleSmall),
      trailing: const CineusIcon(
        CineusAssetId.chevron,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
