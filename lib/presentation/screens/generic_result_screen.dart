import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/challenge_code.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/scoring_rules.dart';
import '../l10n_mappers.dart';
import '../providers/game_actions.dart';
import '../providers/play_notifier.dart';
import '../providers/providers.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/film_strip_widget.dart';
import '../widgets/poster_card_widget.dart';
import '../widgets/reward_toast.dart';
import '../widgets/share_grid_widget.dart';

enum ResultBadge { win, lose }

class ResultConfig {
  final bool won;
  final ResultBadge badgeKey;
  final Color accent;
  final bool showRevealLabel;
  final bool showScore;
  final bool showTagline;
  final bool filledShareButton;
  final Color nextFilmColor;
  final Color nextFilmForeground;

  const ResultConfig({
    required this.won,
    required this.badgeKey,
    required this.accent,
    this.showRevealLabel = false,
    this.showScore = false,
    this.showTagline = false,
    this.filledShareButton = false,
    required this.nextFilmColor,
    required this.nextFilmForeground,
  });

  static const victory = ResultConfig(
    won: true,
    badgeKey: ResultBadge.win,
    accent: AppColors.success400,
    showScore: true,
    filledShareButton: true,
    nextFilmColor: AppColors.gold300,
    nextFilmForeground: AppColors.obsidian900,
  );

  static const defeat = ResultConfig(
    won: false,
    badgeKey: ResultBadge.lose,
    accent: AppColors.ruby300,
    showRevealLabel: true,
    showTagline: true,
    nextFilmColor: AppColors.obsidian600,
    nextFilmForeground: Colors.white,
  );
}

class GenericResultScreen extends ConsumerStatefulWidget {
  final ResultConfig config;
  final VoidCallback onNavigateToStats;
  final VoidCallback onNavigateHome;

  const GenericResultScreen({
    super.key,
    required this.config,
    required this.onNavigateToStats,
    required this.onNavigateHome,
  });

  @override
  ConsumerState<GenericResultScreen> createState() =>
      _GenericResultScreenState();
}

class _GenericResultScreenState extends ConsumerState<GenericResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  ResultConfig get config => widget.config;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(begin: 22, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _shareResult(
    PlayState state,
    GameSession session,
    int steps,
  ) async {
    final grid = ShareGrid(revealedClues: steps, won: config.won);
    final gridText = grid.toEmojiGrid();
    final total = ScoringRules.clue.totalSteps;
    final l10n = context.l10n;

    final text = switch (session.kind) {
      SessionKind.daily => config.won
          ? l10n.shareWin(
              '${state.challengeNumber}',
              steps,
              total,
              session.score,
              gridText,
            )
          : l10n.shareLose('${state.challengeNumber}', gridText),
      SessionKind.stage => config.won
          ? l10n.shareStageWin(
              session.stageId,
              steps,
              total,
              session.score,
              gridText,
            )
          : l10n.shareStageLose(session.stageId, gridText),
      SessionKind.challenge => config.won
          ? l10n.shareFriendWin(steps, total, session.score, gridText)
          : l10n.shareFriendLose(gridText),
    };

    var shared = false;
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: 'Cineus'),
      );
      shared = result.status == ShareResultStatus.success;
    } catch (_) {
      shared = false;
    }

    if (!mounted) return;
    if (!shared) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          shared ? context.l10n.resultShared : context.l10n.resultCopied,
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor:
            (config.won ? AppColors.success500 : AppColors.ruby300)
                .withValues(alpha: 0.92),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareChallenge(int movieId) async {
    final text = context.l10n.challengeShareText(
      ChallengeCode.encode(movieId),
      ChallengeCode.linkFor(movieId).toString(),
    );
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'Cineus'),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.resultCopied),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clueGameProvider);
    final movie = state.movie;
    final session = state.session;

    if (movie == null || session == null) {
      return const Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold300),
        ),
      );
    }

    final gridSteps =
        config.won ? session.revealedClues : state.rules.totalSteps;

    return RewardToast(
      child: Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) => Opacity(
                  opacity: _fade.value,
                  child: Transform.translate(
                    offset: Offset(0, _slide.value),
                    child: child,
                  ),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  children: [
                    const FilmStrip(),
                    const SizedBox(height: 20),
                    _contextPill(state, session),
                    const SizedBox(height: 12),
                    _buildBadge(),
                    const SizedBox(height: 20),
                    if (config.showScore) ...[
                      _buildScore(session.score),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.gotItOnClue(session.revealedClues),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                    if (config.showRevealLabel) ...[
                      Text(
                        context.l10n.theMovieWas,
                        textAlign: TextAlign.center,
                        style: AppTypography.overline.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 270),
                        child: PosterCard(movie: movie),
                      ),
                    ),
                    if (config.showTagline &&
                        movie.tagline != null &&
                        movie.tagline!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '“${movie.tagline}”',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildShareBlock(state, session, gridSteps),
                    if (session.isDaily) ...[
                      const SizedBox(height: 24),
                      const CountdownTimer(),
                    ],
                    const SizedBox(height: 20),
                    _buildNavigation(state),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _shareChallenge(movie.id),
                        icon: const Icon(
                          Icons.emoji_events_outlined,
                          size: 18,
                        ),
                        label: Text(context.l10n.challengeShareButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contextPill(PlayState state, GameSession session) {
    final label = switch (session.kind) {
      SessionKind.daily => '${context.l10n.dailyChallengeLabel} #${state.challengeNumber}',
      SessionKind.stage => context.l10n.stageNumber('${session.stageId}'),
      SessionKind.challenge => context.l10n.challengeBadge,
    };
    return Center(
      child: Text(
        label,
        style: AppTypography.monoSmall.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: config.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: config.accent.withValues(alpha: 0.3)),
        ),
        child: Text(
          config.badgeKey == ResultBadge.win
              ? context.l10n.resultWin
              : context.l10n.resultLose,
          style: AppTypography.labelLarge.copyWith(
            color: config.won ? AppColors.success300 : config.accent,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildScore(int score) {
    final scoreColor = AppColors.scoreColor(score);
    return Column(
      children: [
        Text(
          '$score',
          style: AppTypography.scoreLarge.copyWith(
            color: scoreColor,
            fontSize: 76,
          ),
        ),
        Text(
          context.l10n.scorePoints,
          style: AppTypography.overline.copyWith(
            color: scoreColor,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildShareBlock(
    PlayState state,
    GameSession session,
    int gridSteps,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(
            context.l10n.yourResult,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ShareGrid(revealedClues: gridSteps, won: config.won),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: config.filledShareButton
                ? ElevatedButton.icon(
                    onPressed: () => _shareResult(state, session, gridSteps),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(context.l10n.share),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _shareResult(state, session, gridSteps),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(context.l10n.share),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(PlayState state) {
    final session = state.session!;
    final nextMovieId = _nextMovieInStage(state);
    final hasTickets = ref.watch(ticketNotifierProvider).hasTickets;
    final poster = ref.watch(dailySessionProvider(GameMode.poster)).valueOrNull;

    if (session.isStage) {
      return Column(
        children: [
          if (nextMovieId != null) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: hasTickets
                    ? () async {
                        final started = await startFilmWithTicket(
                          ref,
                          () => ref
                              .read(clueGameProvider.notifier)
                              .loadStageFilm(
                                nextMovieId,
                                state.stageId!,
                                state.stageMovieIds,
                              ),
                        );
                        if (!started || !mounted) return;
                        context.go('/game?source=stage');
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  hasTickets
                      ? context.l10n.nextFilmCost
                      : context.l10n.noTicketsForNext,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.nextFilmColor,
                  foregroundColor: config.nextFilmForeground,
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/stages/${state.stageId}'),
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: Text(context.l10n.backToStages),
            ),
          ),
        ],
      );
    }

    if (session.isDaily) {
      final posterFinished = poster?.isFinished == true;
      return Column(
        children: [
          if (!posterFinished) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/visual/play?source=daily'),
                icon: const Icon(Icons.image_search_rounded, size: 18),
                label: Text(context.l10n.playPosterArrow),
              ),
            ),
            const SizedBox(height: 10),
          ],
          _secondaryNavigation(),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onNavigateHome,
            icon: const Icon(Icons.home_rounded, size: 18),
            label: Text(context.l10n.backHome),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onNavigateToStats,
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: Text(context.l10n.statsTitle),
          ),
        ),
      ],
    );
  }

  Widget _secondaryNavigation() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onNavigateToStats,
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: Text(context.l10n.statsTitle),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onNavigateHome,
            icon: const Icon(Icons.home_rounded, size: 18),
            label: Text(context.l10n.navHome),
          ),
        ),
      ],
    );
  }

  static int? _nextMovieInStage(PlayState state) {
    if (!state.isStage || state.movie == null || state.stageMovieIds.isEmpty) {
      return null;
    }
    final idx = state.stageMovieIds.indexOf(state.movie!.id);
    if (idx < 0 || idx >= state.stageMovieIds.length - 1) return null;
    return state.stageMovieIds[idx + 1];
  }
}