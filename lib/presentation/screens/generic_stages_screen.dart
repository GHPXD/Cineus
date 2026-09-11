import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/stage.dart';
import '../../l10n/app_l10n.dart';
import '../providers/providers.dart';

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
                error: (_, __) => Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.movie_filter_outlined,
                            size: 48,
                            color: AppColors.ruby300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.gameLoadFailed,
                            textAlign: TextAlign.center,
                            style: AppTypography.titleMedium,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (config.isPoster) {
                                ref.invalidate(posterStageNotifierProvider);
                              } else {
                                ref.invalidate(stageNotifierProvider);
                              }
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.retryAction),
                          ),
                        ],
                      ),
                    ),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
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
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<Stage> stages) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            mainAxisExtent: 190,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: stages.length,
          itemBuilder: (context, i) {
            final stage = stages[i];
            return _StageCard(
              stage: stage,
              emoji: config.playingEmoji,
              onTap: stage.isLocked
                  ? null
                  : () => context.push(config.routeBuilder(stage.id)),
            );
          },
        ),
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
    final name = l10n.stageNumber('${stage.id}');

    final borderColor = completed
        ? AppColors.success400.withValues(alpha: 0.5)
        : !locked
            ? AppColors.gold300.withValues(alpha: 0.4)
            : AppColors.obsidian600;

    return Semantics(
      button: !locked,
      enabled: !locked,
      onTap: onTap,
      label: locked
          ? l10n.stageSemanticsLocked(name)
          : completed
              ? l10n.stageSemanticsComplete(name)
              : l10n.stageSemanticsProgress(
                  name,
                  stage.completedCount,
                  stage.totalMovies,
                ),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _StageCoverArt(stageId: stage.id, locked: locked),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 78,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: locked ? 0.58 : 0.88),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            locked ? '🔒' : completed ? '✅' : emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const Spacer(),
                          if (!locked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: completed
                                    ? AppColors.success400.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${stage.completedCount}/${stage.totalMovies}',
                                style: AppTypography.monoSmall.copyWith(
                                  color: completed
                                      ? AppColors.success400
                                      : AppColors.gold300,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        name,
                        style: AppTypography.labelLarge.copyWith(
                          color: locked
                              ? AppColors.textTertiary
                              : AppColors.obsidian0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locked ? l10n.locked : l10n.filmsCount(stage.totalMovies),
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 12,
                          color: locked
                              ? AppColors.textQuaternary
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (!locked && !completed && stage.completedCount > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: stage.progress,
                            minHeight: 4,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.15),
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

class _StageCoverArt extends StatelessWidget {
  final int stageId;
  final bool locked;

  const _StageCoverArt({required this.stageId, required this.locked});

  static const _palettes = <List<Color>>[
    [Color(0xFF08162C), Color(0xFF1A3A6A), Color(0xFFC8922A)],
    [Color(0xFF120822), Color(0xFF2E1258), Color(0xFFA880D0)],
    [Color(0xFF061808), Color(0xFF0C3018), Color(0xFF48BB60)],
    [Color(0xFF1C0606), Color(0xFF4A0C0C), Color(0xFFE04848)],
    [Color(0xFF060C18), Color(0xFF0C2244), Color(0xFF40B8D8)],
    [Color(0xFF181008), Color(0xFF3C2A08), Color(0xFFD89030)],
    [Color(0xFF060618), Color(0xFF141450), Color(0xFF7878E0)],
    [Color(0xFF160806), Color(0xFF3A1404), Color(0xFFD86030)],
    [Color(0xFF041414), Color(0xFF082E2E), Color(0xFF28C0B0)],
    [Color(0xFF0E0618), Color(0xFF261042), Color(0xFFCC60A8)],
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _FilmEdge(color: accent.withValues(alpha: 0.35)),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _FilmEdge(color: accent.withValues(alpha: 0.35)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppL10n.of(context).stageWord,
                  style: TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: accent.withValues(alpha: 0.75),
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
                    height: 1,
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