import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/play_insights.dart';
import '../../domain/repositories/game_repository.dart';
import '../../l10n/app_l10n.dart';
import '../l10n_mappers.dart';
import '../providers/stats_notifier.dart';
import '../widgets/film_strip_widget.dart';
import '../widgets/tap_target.dart';

class StatsScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const StatsScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(statsNotifierProvider);

    if (state.isLoading && state.recentGames.isEmpty && state.stats.totalGames == 0) {
      return Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: Center(
          child: Semantics(
            liveRegion: true,
            label: l10n.statsTitle,
            child: const CircularProgressIndicator(color: AppColors.gold300),
          ),
        ),
      );
    }

    if (state.hasError) {
      return Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.query_stats_rounded,
                      size: 52,
                      color: AppColors.ruby300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.statsLoadFailed,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(statsNotifierProvider.notifier).load(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retryAction),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onBack,
                        child: Text(l10n.back),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final stats = state.stats;

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
                    label: l10n.semBack,
                    onTap: onBack,
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l10n.statsTitle,
                      style: AppTypography.headlineMedium,
                    ),
                  ),
                  if (state.isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold300,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    children: [
                      const FilmStrip(),
                      const SizedBox(height: 16),
                      _buildStatsGrid(context, l10n, stats),
                      const SizedBox(height: 20),
                      _buildStreakBadge(l10n, stats),
                      const SizedBox(height: 20),
                      _buildScoreDistribution(context, l10n, stats),
                      const SizedBox(height: 20),
                      _buildAchievements(l10n, state),
                      const SizedBox(height: 20),
                      _buildInsights(l10n, state.insights),
                      _buildRecentGames(context, l10n, state.recentGames),
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

  Widget _buildStatsGrid(
    BuildContext context,
    AppL10n l10n,
    GameStats stats,
  ) {
    final items = [
      _StatTile(
        label: l10n.statGames,
        value: '${stats.totalGames}',
        color: AppColors.blue300,
      ),
      _StatTile(
        label: l10n.statWinsCaps,
        value: '${stats.totalWins}',
        color: AppColors.success400,
      ),
      _StatTile(
        label: l10n.statRate,
        value: stats.totalGames > 0
            ? '${(stats.winRate * 100).round()}%'
            : '—',
        color: AppColors.gold300,
      ),
      _StatTile(
        label: l10n.statAverage,
        value: stats.totalWins > 0
            ? stats.averageCluesUsed.toStringAsFixed(1)
            : '—',
        subtitle: l10n.statAverageSub,
        color: AppColors.amber300,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        final gap = 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items) SizedBox(width: width, child: item),
          ],
        );
      },
    );
  }

  Widget _buildStreakBadge(AppL10n l10n, GameStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.goldDimGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold300.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.currentStreakTitle, style: AppTypography.titleSmall),
                Text(
                  l10n.dayCount(stats.currentStreak),
                  style: AppTypography.mono.copyWith(color: AppColors.gold300),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.bestLabel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${stats.maxStreak}',
                style: AppTypography.scoreSmall.copyWith(
                  color: AppColors.gold300,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistribution(
    BuildContext context,
    AppL10n l10n,
    GameStats stats,
  ) {
    if (stats.scoreDistribution.isEmpty) {
      return _Panel(
        child: Center(
          child: Text(
            l10n.playToSeeDistribution,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final maxCount = stats.scoreDistribution.values.fold<int>(
      0,
      (max, v) => v > max ? v : max,
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pointsDistribution,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(10, (i) {
            final score = 10 - i;
            final count = stats.scoreDistribution[score] ?? 0;
            final fraction = maxCount > 0 ? count / maxCount : 0.0;
            final color = AppColors.scoreColor(score);

            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$score',
                      style: AppTypography.monoSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: reduceMotion
                                ? Duration.zero
                                : const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            width: (constraints.maxWidth * fraction).clamp(
                              count > 0 ? 24.0 : 0.0,
                              constraints.maxWidth,
                            ),
                            height: 22,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 6),
                            child: count > 0
                                ? Text(
                                    '$count',
                                    style: AppTypography.monoSmall.copyWith(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievements(AppL10n l10n, StatsState state) {
    if (state.achievements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.achievementsHeader,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Text(
              '${state.unlockedAchievements} / ${state.achievements.length}',
              style: AppTypography.monoSmall.copyWith(color: AppColors.gold300),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...state.achievements.map(_AchievementRow.new),
      ],
    );
  }

  Widget _buildInsights(AppL10n l10n, PlayInsights insights) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final best = insights.bestGenre();
    final worst = insights.worstGenre();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourProfileHeader,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        if (best != null && worst != null && best.label != worst.label) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.blueDimGradient,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.blue300.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              l10n.profileSummary(
                best.label,
                (best.winRate * 100).round(),
                worst.label,
                (worst.winRate * 100).round(),
              ),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.obsidian100,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (insights.byGenre.isNotEmpty)
          _BucketTable(title: l10n.byGenre, buckets: insights.byGenre.take(6)),
        if (insights.byDecade.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BucketTable(title: l10n.byDecade, buckets: insights.byDecade),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecentGames(
    BuildContext context,
    AppL10n l10n,
    List<SessionWithMovie> games,
  ) {
    if (games.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentGamesHeader,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        ...games.map((g) {
          final session = g.session;
          final movie = g.movie;
          final isWin = session.status == GameStatus.won;
          final color =
              isWin ? AppColors.scoreColor(session.score) : AppColors.ruby300;
          final parsedDate = DateTime.tryParse(session.date);
          final dateLabel = parsedDate == null
              ? session.date
              : MaterialLocalizations.of(context).formatShortDate(parsedDate);

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isWin ? '${session.score}' : '✖',
                    style: AppTypography.mono.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie?.title ?? l10n.unknownMovie,
                        style: AppTypography.titleSmall.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        dateLabel,
                        style: AppTypography.monoSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  isWin
                      ? l10n.cluesUsedCount(session.revealedClues)
                      : l10n.defeatShort,
                  style: AppTypography.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTypography.scoreSmall.copyWith(
              color: color,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  final Achievement achievement;

  const _AchievementRow(this.achievement);

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final unlocked = achievement.isUnlocked;
    final color = unlocked ? AppColors.gold300 : AppColors.textTertiary;

    return Semantics(
      label: '${l10n.achievementTitle(achievement.id)}. '
          '${unlocked ? l10n.achievementUnlocked : l10n.achievementInProgress(achievement.progressLabel)}. '
          '${l10n.achievementDescription(achievement.id)}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: unlocked ? 0.05 : 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? AppColors.gold300.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.45,
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.achievementTitle(achievement.id),
                          style: AppTypography.titleSmall.copyWith(
                            fontSize: 13,
                            color: unlocked
                                ? AppColors.obsidian0
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (unlocked)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.gold300,
                          size: 16,
                        )
                      else if (achievement.progressLabel.isNotEmpty)
                        Text(
                          achievement.progressLabel,
                          style: AppTypography.monoSmall.copyWith(
                            color: color,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.achievementDescription(achievement.id),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  if (!unlocked && achievement.progress > 0) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: achievement.progress,
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.gold300),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketTable extends StatelessWidget {
  final String title;
  final Iterable<InsightBucket> buckets;

  const _BucketTable({required this.title, required this.buckets});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          ...buckets.map((b) {
            final pct = (b.winRate * 100).round();
            return Semantics(
              label: AppL10n.of(context)
                  .bucketSemantics(b.label, pct, b.played),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  children: [
                    SizedBox(
                      width: 104,
                      child: Text(
                        b.label,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: b.winRate,
                          minHeight: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.scoreColor((b.winRate * 10).round()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      child: Text(
                        AppL10n.of(context).bucketValue(pct, b.played),
                        textAlign: TextAlign.right,
                        style: AppTypography.monoSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}