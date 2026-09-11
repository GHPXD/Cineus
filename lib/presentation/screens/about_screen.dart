import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Player-facing credits and third-party attribution.
///
/// TMDB requires attribution to live in an About/Credits-style section. Keep
/// the legal notice below verbatim even when the surrounding UI is localized.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const tmdbNotice =
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';

  @override
  Widget build(BuildContext context) {
    final copy = _AboutCopy.of(context);

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          children: [
            _Header(title: copy.title),
            Expanded(
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
                        Text(
                          'Cineus',
                          style: AppTypography.headlineMedium.copyWith(
                            color: AppColors.gold300,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(copy.appSummary, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Section(
                    title: copy.dataCreditsTitle,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(copy.tmdbExplanation, style: AppTypography.bodySmall),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.blue500.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.blue300.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TMDB',
                                style: AppTypography.titleSmall.copyWith(
                                  color: AppColors.blue300,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const SelectableText(
                                tmdbNotice,
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
                          icon: Icons.privacy_tip_outlined,
                          label: copy.privacy,
                          onTap: () => context.push('/privacy'),
                        ),
                        const Divider(height: 1),
                        _LegalTile(
                          icon: Icons.gavel_outlined,
                          label: copy.terms,
                          onTap: () => context.push('/terms'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    copy.contact,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
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
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
            icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
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
    );
  }
}

class _LegalTile extends StatelessWidget {
  final IconData icon;
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
      leading: Icon(icon, color: AppColors.gold300),
      title: Text(label, style: AppTypography.titleSmall),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}

class _AboutCopy {
  final String title;
  final String appSummary;
  final String dataCreditsTitle;
  final String tmdbExplanation;
  final String legalTitle;
  final String privacy;
  final String terms;
  final String contact;

  const _AboutCopy({
    required this.title,
    required this.appSummary,
    required this.dataCreditsTitle,
    required this.tmdbExplanation,
    required this.legalTitle,
    required this.privacy,
    required this.terms,
    required this.contact,
  });

  static _AboutCopy of(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return switch (language) {
      'pt' => _pt,
      'es' => _es,
      _ => _en,
    };
  }

  static const _pt = _AboutCopy(
    title: 'Sobre e créditos',
    appSummary:
        'Jogo de adivinhação de filmes, offline-first, com modos Dicas e Poster.',
    dataCreditsTitle: 'Dados e créditos',
    tmdbExplanation:
        'Parte dos metadados e imagens de filmes usados para preparar o catálogo do Cineus tem origem no The Movie Database (TMDB).',
    legalTitle: 'Legal',
    privacy: 'Política de Privacidade',
    terms: 'Termos de Uso',
    contact: 'Suporte e contato: github.com/GHPXD/Cineus/issues',
  );

  static const _en = _AboutCopy(
    title: 'About & credits',
    appSummary:
        'An offline-first movie guessing game with Clues and Poster modes.',
    dataCreditsTitle: 'Data & credits',
    tmdbExplanation:
        'Some movie metadata and images used to prepare the Cineus catalogue originate from The Movie Database (TMDB).',
    legalTitle: 'Legal',
    privacy: 'Privacy Policy',
    terms: 'Terms of Use',
    contact: 'Support and contact: github.com/GHPXD/Cineus/issues',
  );

  static const _es = _AboutCopy(
    title: 'Acerca de y créditos',
    appSummary:
        'Juego de adivinanzas de películas, offline-first, con modos Pistas y Póster.',
    dataCreditsTitle: 'Datos y créditos',
    tmdbExplanation:
        'Parte de los metadatos e imágenes utilizados para preparar el catálogo de Cineus provienen de The Movie Database (TMDB).',
    legalTitle: 'Legal',
    privacy: 'Política de Privacidad',
    terms: 'Términos de Uso',
    contact: 'Soporte y contacto: github.com/GHPXD/Cineus/issues',
  );
}
