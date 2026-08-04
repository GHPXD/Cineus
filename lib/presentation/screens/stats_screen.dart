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
import '../widgets/settings_section.dart';

class StatsScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const StatsScreen({super.key, required this.onBack});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(statsNotifierProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(statsNotifierProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold300),
        ),
      );
    }

    final stats = state.stats;

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Text(
                      l10n.statsTitle,
                      style: AppTypography.headlineMedium,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const FilmStrip(),
                  const SizedBox(height: 16),

                  // Stats grid
                  _buildStatsGrid(l10n, stats),
                  const SizedBox(height: 20),

                  // Streak badge
                  _buildStreakBadge(l10n, stats),
                  const SizedBox(height: 20),

                  // Score distribution
                  _buildScoreDistribution(l10n, stats),
                  const SizedBox(height: 20),

                  // Badges (D5)
                  _buildAchievements(l10n, state),
                  const SizedBox(height: 20),

                  // Genre / decade breakdowns (D8)
                  _buildInsights(l10n, state.insights),

                  // Recent games
                  _buildRecentGames(l10n, state.recentGames),
                  const SizedBox(height: 24),

                  // Language, reminder and challenge code
                  const SettingsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AppL10n l10n, GameStats stats) {
    return Row(
      children: [
        _StatTile(
          label: l10n.statGames,
          value: '${stats.totalGames}',
          color: AppColors.blue300,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: l10n.statWinsCaps,
          value: '${stats.totalWins}',
          color: AppColors.success400,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: l10n.statRate,
          value: stats.totalGames > 0
              ? '${(stats.winRate * 100).round()}%'
              : '—',
          color: AppColors.gold300,
        ),
        const SizedBox(width: 10),
        _StatTile(
          label: l10n.statAverage,
          value: stats.totalWins > 0
              ? stats.averageCluesUsed.toStringAsFixed(1)
              : '—',
          subtitle: l10n.statAverageSub,
          color: AppColors.amber300,
        ),
      ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.currentStreakTitle,
                style: AppTypography.titleSmall,
              ),
              Text(
                l10n.dayCount(stats.currentStreak),
                style: AppTypography.mono.copyWith(color: AppColors.gold300),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.bestLabel,
                style: AppTypography.bodySmall,
              ),
              Text(
                '${stats.maxStreak}',
                style: AppTypography.scoreSmall.copyWith(
                  color: AppColors.gold300,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistribution(AppL10n l10n, GameStats stats) {
    if (stats.scoreDistribution.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Center(
          child: Text(
            l10n.playToSeeDistribution,
            style: AppTypography.bodySmall,
          ),
        ),
      );
    }

    final maxCount = stats.scoreDistribution.values.fold<int>(
      0,
      (max, v) => v > max ? v : max,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
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
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$score',
                      style: AppTypography.monoSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          width: ((constraints.maxWidth * fraction)
                                  .clamp(count > 0 ? 20.0 : 0.0, constraints.maxWidth)),
                          height: 20,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 6),
                          child: count > 0
                              ? Text(
                                  '$count',
                                  style: AppTypography.monoSmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
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
              style: AppTypography.monoSmall
                  .copyWith(color: AppColors.gold300),
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

        // A one-line read before the tables — only shown once there is enough
        // history for the comparison to mean anything.
        if (best != null && worst != null && best.label != worst.label) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.blueDimGradient,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.blue300.withValues(alpha: 0.2)),
            ),
            child: Text(
              l10n.profileSummary(
                best.label,
                (best.winRate * 100).round(),
                worst.label,
                (worst.winRate * 100).round(),
              ),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.obsidian100, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (insights.byGenre.isNotEmpty)
          _BucketTable(
            title: l10n.byGenre,
            buckets: insights.byGenre.take(6),
          ),
        if (insights.byDecade.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BucketTable(title: l10n.byDecade, buckets: insights.byDecade),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRecentGames(AppL10n l10n, List<SessionWithMovie> games) {
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
          final color = isWin
              ? AppColors.scoreColor(session.score)
              : AppColors.ruby300;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isWin ? '${session.score}' : '✖',
                    style: AppTypography.mono.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: isWin ? 13 : 12,
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
                        session.date,
                        style: AppTypography.monoSmall,
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.scoreSmall.copyWith(
                color: color,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.overline.copyWith(
                color: AppColors.textTertiary,
                fontSize: 9,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: AppTypography.monoSmall.copyWith(fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }
}

/// One badge row: emoji, title, description and a progress bar.
class _AchievementRow extends StatelessWidget {
  final Achievement achievement;

  const _AchievementRow(this.achievement);

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final unlocked = achievement.isUnlocked;
    final color = unlocked ? AppColors.gold300 : AppColors.obsidian400;

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
              opacity: unlocked ? 1 : 0.35,
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
                                : AppColors.obsidian300,
                          ),
                        ),
                      ),
                      if (unlocked)
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.gold300, size: 16)
                      else if (achievement.progressLabel.isNotEmpty)
                        Text(
                          achievement.progressLabel,
                          style: AppTypography.monoSmall
                              .copyWith(color: color, fontSize: 10),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.achievementDescription(achievement.id),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
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

/// Win-rate table for a set of catalogue slices.
class _BucketTable extends StatelessWidget {
  final String title;
  final Iterable<InsightBucket> buckets;

  const _BucketTable({required this.title, required this.buckets});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.textSecondary, fontSize: 10),
          ),
          const SizedBox(height: 8),
          ...buckets.map((b) {
            final pct = (b.winRate * 100).round();
            return Semantics(
              label: AppL10n.of(context)
                  .bucketSemantics(b.label, pct, b.played),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        b.label,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.obsidian200,
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
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.scoreColor((b.winRate * 10).round()),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 58,
                      child: Text(
                        AppL10n.of(context).bucketValue(pct, b.played),
                        textAlign: TextAlign.right,
                        style: AppTypography.monoSmall.copyWith(fontSize: 10),
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
