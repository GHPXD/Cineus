import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/stage.dart';
import '../providers/providers.dart';
import '../../l10n/app_l10n.dart';

/// Configuration that differentiates Clues stages from Poster stages.
class StagesConfig {
  final String playingEmoji;
  final bool isPoster;
  final String Function(int stageId) routeBuilder;

  const StagesConfig({
    required this.playingEmoji,
    this.isPoster = false,
    required this.routeBuilder,
  });

  String title(AppL10n l10n) => isPoster ? l10n.navPosters : l10n.navFilms;

  String subtitle(AppL10n l10n) =>
      isPoster ? l10n.stagesSubtitlePosters : l10n.stagesSubtitleClues;

  static const clues = StagesConfig(
    playingEmoji: '🎬',
    routeBuilder: _cluesRoute,
  );

  static const posters = StagesConfig(
    playingEmoji: '🖼️',
    isPoster: true,
    routeBuilder: _postersRoute,
  );

  static String _cluesRoute(int id) => '/stages/$id';
  static String _postersRoute(int id) => '/visual/stage/$id';
}

/// Generic stages grid screen. Used for both Clue stages and Poster stages.
class GenericStagesScreen extends ConsumerWidget {
  final StagesConfig config;

  const GenericStagesScreen({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = config.isPoster
        ? ref.watch(posterStageNotifierProvider)
        : ref.watch(stageNotifierProvider);

    final l10n = AppL10n.of(context);

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: stagesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold300),
                ),
                error: (e, _) => Center(
                  child: Text(
                    l10n.genericLoadError,
                    style: AppTypography.bodyMedium,
                  ),
                ),
                data: (stages) => _buildGrid(context, stages),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(config.title(l10n), style: AppTypography.displaySmall),
          const SizedBox(height: 4),
          Text(
            config.subtitle(l10n),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Stage> stages) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: stages.length,
      itemBuilder: (context, i) => _StageCard(
        stage: stages[i],
        emoji: config.playingEmoji,
        onTap: stages[i].isLocked
            ? null
            : () => context.push(config.routeBuilder(stages[i].id)),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final Stage stage;
  final String emoji;
  final VoidCallback? onTap;

  const _StageCard({required this.stage, required this.emoji, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final locked = stage.isLocked;
    final completed = stage.isCompleted;

    Color borderColor;
    if (completed) {
      borderColor = AppColors.success400.withValues(alpha: 0.5);
    } else if (!locked) {
      borderColor = AppColors.gold300.withValues(alpha: 0.4);
    } else {
      borderColor = AppColors.obsidian600;
    }

    return Semantics(
      button: !locked,
      enabled: !locked,
      label: locked
          ? l10n.stageSemanticsLocked(stage.name)
          : completed
          ? l10n.stageSemanticsComplete(stage.name)
          : l10n.stageSemanticsProgress(
              stage.name,
              stage.completedCount,
              stage.totalMovies,
            ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // Stage cover art (unique per stage, handles locked state)
                Positioned.fill(
                  child: _StageCoverArt(stageId: stage.id, locked: locked),
                ),
                // Bottom gradient for text readability
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: locked ? 0.5 : 0.82),
                        ],
                      ),
                    ),
                  ),
                ),
                // Card content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            locked
                                ? '🔒'
                                : completed
                                ? '✅'
                                : emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const Spacer(),
                          if (!locked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: completed
                                    ? AppColors.success400.withValues(
                                        alpha: 0.25,
                                      )
                                    : Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${stage.completedCount}/${stage.totalMovies}',
                                style: AppTypography.monoSmall.copyWith(
                                  fontSize: 10,
                                  color: completed
                                      ? AppColors.success400
                                      : AppColors.gold300,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        stage.name,
                        style: AppTypography.labelLarge.copyWith(
                          color: locked
                              ? AppColors.obsidian400
                              : AppColors.obsidian0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locked
                            ? l10n.locked
                            : l10n.filmsCount(stage.totalMovies),
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: locked
                              ? AppColors.obsidian500
                              : AppColors.obsidian300,
                        ),
                      ),
                      if (!locked &&
                          !completed &&
                          stage.completedCount > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stage.progress,
                            minHeight: 3,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.15,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.gold300,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cinema-themed stage cover art. Each stageId gets a unique color palette.
// Renders: gradient background, film-hole edges, Roman numeral in center.
// ─────────────────────────────────────────────────────────────────────────────

class _StageCoverArt extends StatelessWidget {
  final int stageId;
  final bool locked;

  const _StageCoverArt({required this.stageId, required this.locked});

  // 10 distinct dark / cinematic palettes [gradientTop, gradientBottom, accent]
  static const _palettes = <List<Color>>[
    [Color(0xFF08162C), Color(0xFF1A3A6A), Color(0xFFC8922A)], // navy + gold
    [
      Color(0xFF120822),
      Color(0xFF2E1258),
      Color(0xFFA880D0),
    ], // purple + lavender
    [Color(0xFF061808), Color(0xFF0C3018), Color(0xFF48BB60)], // forest + mint
    [
      Color(0xFF1C0606),
      Color(0xFF4A0C0C),
      Color(0xFFE04848),
    ], // crimson + flame
    [Color(0xFF060C18), Color(0xFF0C2244), Color(0xFF40B8D8)], // steel + cyan
    [
      Color(0xFF181008),
      Color(0xFF3C2A08),
      Color(0xFFD89030),
    ], // amber + warm gold
    [
      Color(0xFF060618),
      Color(0xFF141450),
      Color(0xFF7878E0),
    ], // indigo + periwinkle
    [Color(0xFF160806), Color(0xFF3A1404), Color(0xFFD86030)], // rust + orange
    [Color(0xFF041414), Color(0xFF082E2E), Color(0xFF28C0B0)], // teal + aqua
    [Color(0xFF0E0618), Color(0xFF261042), Color(0xFFCC60A8)], // violet + rose
  ];

  static String _roman(int n) {
    const v = [50, 40, 10, 9, 5, 4, 1];
    const s = ['L', 'XL', 'X', 'IX', 'V', 'IV', 'I'];
    var r = '';
    var x = n;
    for (var i = 0; i < v.length; i++) {
      while (x >= v[i]) {
        r += s[i];
        x -= v[i];
      }
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[(stageId - 1) % _palettes.length];
    final top = locked ? const Color(0xFF0A0A0A) : palette[0];
    final bot = locked ? const Color(0xFF181818) : palette[1];
    final accent = locked ? const Color(0xFF2E2E2E) : palette[2];
    final roman = _roman(stageId);
    final fontSize = roman.length <= 2
        ? 42.0
        : roman.length <= 4
        ? 34.0
        : roman.length <= 6
        ? 26.0
        : 21.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [top, bot],
        ),
      ),
      child: Stack(
        children: [
          // Film perforation holes — top edge
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _FilmEdge(color: accent.withValues(alpha: 0.35)),
          ),
          // Film perforation holes — bottom edge
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _FilmEdge(color: accent.withValues(alpha: 0.35)),
          ),
          // Center: stage label + Roman numeral
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppL10n.of(context).stageWord,
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: accent.withValues(alpha: 0.65),
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  roman,
                  style: TextStyle(
                    fontFamily: AppFonts.playfair,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Film strip perforation holes drawn as a row of small circles.
class _FilmEdge extends StatelessWidget {
  final Color color;
  const _FilmEdge({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          6,
          (_) => Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }
}
