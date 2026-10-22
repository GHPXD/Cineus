import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/color_stats.dart';
import '../../domain/entities/saved_color_session.dart';
import '../providers/color_providers.dart';
import '../widgets/stats_dashboard.dart';
import '../widgets/color_play_background.dart';
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
import '../providers/progress_provider.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/cineus_state_art.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/tap_target.dart';

final _statsModeProvider = StateProvider<GameMode>((_) => GameMode.clue);

class StatsScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final GameMode? initialMode;
  final bool initialColors;

  const StatsScreen({
    super.key,
    required this.onBack,
    this.initialColors = false,
    this.initialMode,
  });

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  late GameMode _mode = widget.initialMode ?? ref.read(_statsModeProvider);
  late bool _colors = widget.initialColors;
  bool _achievements = false;
  final _scroll = ScrollController(keepScrollOffset: false);
  @override
  void didUpdateWidget(covariant StatsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColors != widget.initialColors ||
        oldWidget.initialMode != widget.initialMode) {
      _colors = widget.initialColors;
      _mode = widget.initialMode ?? ref.read(_statsModeProvider);
      _achievements = false;
      _top();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _top() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  VoidCallback get onBack => widget.onBack;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mode = _mode;
    final provider = mode == GameMode.poster
        ? posterStatsNotifierProvider
        : statsNotifierProvider;
    final state = ref.watch(provider);

    final achievementsState = ref.watch(allAchievementsProvider);
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: ColorPlayBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                key: const ValueKey('stats-scroll'),
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TapTarget(
                        key: const ValueKey('stats-back'),
                        label: l10n.semBack,
                        onTap: onBack,
                        child: const CineusIcon(CineusAssetId.back),
                      ),
                      Text(
                        l10n.statsTitle,
                        style: AppTypography.headlineMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StatsTabs(
                    children: [
                      for (final m in GameMode.values)
                        StatsTab(
                          key: ValueKey('stats-mode-${m.name}'),
                          label: m == GameMode.clue
                              ? l10n.modeClues
                              : l10n.modePoster,
                          icon: m == GameMode.clue
                              ? CineusAssetId.modeClues
                              : CineusAssetId.modePoster,
                          selected: !_colors && mode == m,
                          onPressed: () {
                            ref.read(_statsModeProvider.notifier).state = m;
                            setState(() {
                              _mode = m;
                              _colors = false;
                            });
                            _top();
                          },
                        ),
                      StatsTab(
                        key: const ValueKey('stats-mode-colors'),
                        label: l10n.colorModeTitle,
                        icon: CineusAssetId.modeColors,
                        selected: _colors,
                        onPressed: () {
                          setState(() => _colors = true);
                          _top();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatsTabs(
                    children: [
                      StatsTab(
                        key: const ValueKey('stats-overview'),
                        label: l10n.statsOverview,
                        selected: !_achievements,
                        onPressed: () {
                          setState(() => _achievements = false);
                          _top();
                        },
                      ),
                      StatsTab(
                        key: const ValueKey('stats-achievements'),
                        label: l10n.statsAchievementsTab,
                        selected: _achievements,
                        onPressed: () {
                          setState(() => _achievements = true);
                          _top();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (!_achievements)
                    DropdownButtonFormField<ActivityScope>(
                      icon: const CineusIcon(CineusAssetId.chevron, size: 18),
                      isExpanded: true,
                      key: const ValueKey('stats-context'),
                      initialValue: ref.watch(activityScopeProvider),
                      decoration: InputDecoration(
                        labelText: l10n.activityContext,
                      ),
                      items: [
                        for (final scope in ActivityScope.values)
                          DropdownMenuItem(
                            value: scope,
                            child: Text(switch (scope) {
                              ActivityScope.all => l10n.activityAll,
                              ActivityScope.daily => l10n.activityDaily,
                              ActivityScope.stages => l10n.activityStage,
                              ActivityScope.invitations => l10n.activityInvites,
                              ActivityScope.practice => l10n.practiceMode,
                            }),
                          ),
                      ],
                      onChanged: (scope) {
                        if (scope != null) {
                          ref.read(activityScopeProvider.notifier).state =
                              scope;
                        }
                      },
                    ),
                  const SizedBox(height: 12),
                  if (_achievements) ...[
                    _buildAchievements(l10n, achievementsState),
                  ] else if (_colors) ...[
                    _buildColorOverview(context, l10n),
                  ] else if (state.hasError) ...[
                    _error(l10n, () => ref.read(provider.notifier).load()),
                  ] else if (state.isLoading &&
                      state.stats.totalGames == 0) ...[
                    const Center(child: CircularProgressIndicator()),
                  ] else ...[
                    Text(
                      '${mode == GameMode.clue ? l10n.modeClues : l10n.modePoster} · ${state.stats.totalGames}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (state.stats.totalGames == 0) ...[
                      _Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CineusStateArt(CineusStateKind.empty),
                            const SizedBox(height: 12),
                            Text(
                              l10n.statsEmptyTitle,
                              style: AppTypography.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.statsEmptyBody,
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    _buildStatsGrid(context, l10n, state.stats, mode),
                    const SizedBox(height: 18),
                    _buildStreakBadge(l10n, state),
                    if (state.stats.totalGames > 0) ...[
                      const SizedBox(height: 18),
                      _buildScoreDistribution(context, l10n, state.stats, mode),
                      const SizedBox(height: 18),
                      _buildInsights(l10n, state.insights),
                      _buildRecentGames(context, l10n, state.recentGames, mode),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _error(AppL10n l, VoidCallback retry) => _Panel(
    child: Column(
      children: [
        const CineusStateArt(CineusStateKind.error),
        const SizedBox(height: 12),
        Text(l.statsLoadFailed, style: AppTypography.titleMedium),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: retry, child: Text(l.retryAction)),
      ],
    ),
  );

  Widget _buildStatsGrid(
    BuildContext context,
    AppL10n l10n,
    GameStats stats,
    GameMode mode,
  ) {
    final items = [
      StatsMetric(
        icon: CineusAssetId.homeGames,
        label: l10n.statGames,
        value: '${stats.totalGames}',
        color: AppColors.blue300,
      ),
      StatsMetric(
        icon: CineusAssetId.homeTrophy,
        label: l10n.statWinsCaps,
        value: '${stats.totalWins}',
        color: AppColors.success400,
      ),
      StatsMetric(
        icon: CineusAssetId.categoryGoal,
        label: l10n.statRate,
        value: stats.totalGames > 0 ? '${(stats.winRate * 100).round()}%' : '—',
        color: AppColors.gold300,
      ),
      StatsMetric(
        icon: CineusAssetId.stats,
        label: l10n.statAverage,
        value: stats.totalWins > 0
            ? stats.averageCluesUsed.toStringAsFixed(1)
            : '—',
        subtitle: mode == GameMode.clue
            ? l10n.statAverageSub
            : l10n.statAveragePosterSub,
        color: AppColors.amber300,
      ),
    ];

    return StatsGrid(children: items);
  }

  String _colorScore(int? cents) => cents == null
      ? '—'
      : NumberFormat(
          '0.00',
          Localizations.localeOf(context).languageCode,
        ).format(cents / 100);

  Widget _buildColorOverview(BuildContext context, AppL10n l) {
    return ref
        .watch(colorSessionsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) =>
              _error(l, () => ref.invalidate(colorSessionsProvider)),
          data: (sessions) {
            final scope = ref.watch(activityScopeProvider);
            final filtered = sessions
                .where(
                  (s) => switch (scope) {
                    ActivityScope.all => true,
                    ActivityScope.daily => s.kind == ColorSessionKind.daily,
                    ActivityScope.stages => s.isStage,
                    ActivityScope.invitations => false,
                    ActivityScope.practice =>
                      s.kind == ColorSessionKind.training && !s.isStage,
                  },
                )
                .toList();
            final stats = ColorStats.fromSessions(filtered);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${l.colorModeTitle} · ${stats.games}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                if (stats.games == 0) ...[
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CineusStateArt(CineusStateKind.empty),
                        const SizedBox(height: 12),
                        Text(
                          l.statsEmptyTitle,
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.colorHistoryEmpty,
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                StatsGrid(
                  children: [
                    StatsMetric(
                      label: l.statGames,
                      value: '${stats.games}',
                      icon: CineusAssetId.homeGames,
                      color: AppColors.blue300,
                    ),
                    StatsMetric(
                      label: l.colorStatsBest,
                      value: _colorScore(stats.bestCents),
                      icon: CineusAssetId.homeTrophy,
                      color: AppColors.success400,
                    ),
                    StatsMetric(
                      label: l.colorStatsRoundsPlayed,
                      value: '${stats.games * 5}',
                      icon: CineusAssetId.categoryGoal,
                      color: AppColors.gold300,
                    ),
                    StatsMetric(
                      label: l.statAverage,
                      value: _colorScore(stats.averageCents),
                      subtitle: l.colorStatsPointScale,
                      icon: CineusAssetId.stats,
                      color: AppColors.amber300,
                    ),
                  ],
                ),
                if (stats.games > 0) ...[
                  const SizedBox(height: 18),
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.colorStatsRounds,
                          style: AppTypography.titleMedium,
                        ),
                        const SizedBox(height: 14),
                        for (final (i, average) in stats.roundAverages.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      l.colorStatsRound(i + 1),
                                      style: AppTypography.bodySmall,
                                    ),
                                    Text(
                                      _colorScore(average),
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.gold200,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Semantics(
                                  label: l.colorScoreValue(
                                    _colorScore(average),
                                  ),
                                  child: LinearProgressIndicator(
                                    value: (average ?? 0) / 1000,
                                    minHeight: 7,
                                    borderRadius: BorderRadius.circular(8),
                                    backgroundColor: AppColors.obsidian600,
                                    color: AppColors.gold200,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(l.colorStatsRecent, style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  for (final result in stats.recent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        onPressed: () => context.push(
                          '/colors/session/${Uri.encodeComponent(result.id)}',
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            Text(
                              (result.isStage
                                      ? l.colorStageTitle(result.stageId!)
                                      : result.dailyDate) ??
                                  DateFormat.yMd(
                                    Localizations.localeOf(
                                      context,
                                    ).languageCode,
                                  ).format(result.updatedAt.toLocal()),
                            ),
                            Text(
                              l.colorScoreValue(
                                _colorScore(result.game.averageCents),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        );
  }

  Widget _buildStreakBadge(AppL10n l, StatsState state) {
    final stats = state.stats;
    return _Panel(
      key: const ValueKey('streak-summary'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CineusIcon(CineusAssetId.streak, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.currentStreakTitle,
                  style: AppTypography.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stats.currentStreak == 0
                ? l.streakEmpty
                : l.dayCount(stats.currentStreak),
            style: AppTypography.titleLarge.copyWith(color: AppColors.gold300),
          ),
          const SizedBox(height: 8),
          Text(
            '${l.bestLabel}: ${l.dayCount(stats.maxStreak)}',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l.guideDailyTitle, style: AppTypography.bodySmall),
            children: [Text(l.streakDailyHelp, style: AppTypography.bodySmall)],
          ),
          if (state.protectedDays.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const CineusIcon(
                  CineusAssetId.streakProtection,
                  color: AppColors.blue300,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.protectedDays(state.protectedDays.length),
                    style: AppTypography.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l.protectedDaysHelp,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreDistribution(
    BuildContext context,
    AppL10n l10n,
    GameStats stats,
    GameMode mode,
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
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(mode == GameMode.clue ? 10 : 5, (i) {
            final maxScore = mode == GameMode.clue ? 10 : 5;
            final score = maxScore - i;
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
                              count > 0
                                  ? (MediaQuery.textScalerOf(
                                              context,
                                            ).scale(11) *
                                            3)
                                        .clamp(0.0, constraints.maxWidth)
                                  : 0.0,
                              constraints.maxWidth,
                            ),
                            height:
                                MediaQuery.textScalerOf(context).scale(11) + 12,
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

  Widget _buildAchievements(AppL10n l, AsyncValue<List<Achievement>> state) =>
      state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => _error(l, () {
          ref.read(statsNotifierProvider.notifier).load();
          ref.read(posterStatsNotifierProvider.notifier).load();
          ref.invalidate(colorSessionsProvider);
          ref.invalidate(allAchievementsProvider);
        }),
        data: (achievements) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.achievementsHeader, style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(
              l.achievementProgress(
                achievements.where((a) => a.isUnlocked).length,
                achievements.length,
              ),
              style: AppTypography.bodySmall.copyWith(color: AppColors.gold300),
            ),
            const SizedBox(height: 14),
            ...achievements.map(_AchievementRow.new),
          ],
        ),
      );

  Widget _buildInsights(AppL10n l10n, PlayInsights insights) {
    if (insights.isEmpty) return const SizedBox.shrink();

    final best = insights.bestGenre();
    final worst = insights.worstGenre();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yourProfileHeader,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0,
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
    GameMode mode,
  ) {
    if (games.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentGamesHeader,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0,
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
          final parsedDate = DateTime.tryParse(session.date);
          final dateLabel = parsedDate == null
              ? session.date
              : MaterialLocalizations.of(context).formatShortDate(parsedDate);

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF101D32),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF273C59)),
            ),
            child: Row(
              children: [
                Container(
                  width: MediaQuery.textScalerOf(context).scale(16) + 20,
                  height: MediaQuery.textScalerOf(context).scale(16) + 20,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isWin ? '${session.score}' : '×',
                    style: AppTypography.mono.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
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
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        isWin
                            ? (mode == GameMode.clue
                                  ? l10n.cluesUsedCount(session.revealedClues)
                                  : l10n.pointsPlain(session.score))
                            : l10n.defeatShort,
                        style: AppTypography.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
  const _Panel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => StatsPanel(child: child);
}

class _AchievementRow extends StatelessWidget {
  final Achievement achievement;
  const _AchievementRow(this.achievement);
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final unlocked = achievement.isUnlocked;
    final scope = achievement.id.startsWith('colors_')
        ? l.achievementScopeColors
        : achievement.id.startsWith('poster_')
        ? l.achievementScopeDailyPoster
        : achievement.id == 'stages_5'
        ? l.achievementScopeStagesBoth
        : achievement.id == 'tickets_100'
        ? l.achievementScopeRewardsBoth
        : l.achievementScopeDailyClues;
    final status = unlocked
        ? l.achievementUnlocked
        : achievement.progressLabel.isEmpty
        ? l.achievementLockedLabel
        : l.achievementInProgress(achievement.progressLabel);
    final title = l.achievementTitle(achievement.id);
    return Semantics(
      label:
          '$title. $scope. $status. ${l.achievementDescription(achievement.id)}',
      excludeSemantics: true,
      child: Container(
        key: ValueKey('achievement-${achievement.id}'),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.obsidian800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? AppColors.gold300.withValues(alpha: .45)
                : AppColors.obsidian600,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CineusIcon(
                  CineusAssets.forAchievement(achievement.id),
                  size: 52,
                  state: unlocked
                      ? CineusIconState.normal
                      : CineusIconState.muted,
                  color: unlocked ? AppColors.gold300 : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        scope,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.blue300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l.achievementDescription(achievement.id),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CineusIcon(
                  unlocked ? CineusAssetId.completed : CineusAssetId.lock,
                  size: 18,
                  color: unlocked ? AppColors.gold300 : AppColors.textSecondary,
                ),
                Text(
                  status,
                  style: AppTypography.bodySmall.copyWith(
                    color: unlocked
                        ? AppColors.gold300
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (!unlocked) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: achievement.progress,
                color: AppColors.blue300,
                backgroundColor: AppColors.obsidian600,
                minHeight: 4,
              ),
            ],
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
              label: AppL10n.of(
                context,
              ).bucketSemantics(b.label, pct, b.played),
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
                          color: AppColors.textSecondary,
                          fontSize: 12,
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
