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
import '../widgets/reward_toast.dart';
import '../widgets/film_strip_widget.dart';
import '../widgets/poster_card_widget.dart';
import '../widgets/share_grid_widget.dart';

/// Which headline the result screen shows.
enum ResultBadge { win, lose }

/// What differs between the victory and defeat screens.
///
/// The two were separate 320-line files that shared the entry animation, the
/// poster card, the share block, the countdown and the whole navigation footer —
/// including the "next film" button, which had to be fixed twice when it turned
/// out to be handing out free stage plays.
class ResultConfig {
  final bool won;

  /// Which pill headline to show at the top.
  final ResultBadge badgeKey;

  /// Drives the pill, the score colour and the share button.
  final Color accent;

  /// Whether to show the "the film was" label above the poster.
  final bool showRevealLabel;

  final double posterHeight;

  /// Victory shows the big score; defeat shows the film's tagline instead.
  final bool showScore;
  final bool showTagline;

  /// Victory uses a filled share button, defeat an outlined one.
  final bool filledShareButton;

  /// Colours for the stage "next film" button.
  final Color nextFilmColor;
  final Color nextFilmForeground;

  const ResultConfig({
    required this.won,
    required this.badgeKey,
    required this.accent,
    required this.posterHeight,
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
    posterHeight: 260,
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
    posterHeight: 280,
    showTagline: true,
    nextFilmColor: AppColors.obsidian600,
    nextFilmForeground: Colors.white,
  );
}

/// Result screen for the clue game, in both outcomes.
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
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<double>(
      begin: 30,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Opens the platform share sheet, falling back to the clipboard.
  ///
  /// `share_plus` was a declared dependency with zero imports — the button only
  /// ever copied text. The fallback matters: the native sheet is unavailable on
  /// desktop and on browsers without the Web Share API.
  Future<void> _share(int challengeNumber, int score, int steps) async {
    final grid = ShareGrid(revealedClues: steps, won: config.won);
    final l10n = context.l10n;
    final text = config.won
        ? l10n.shareWin(
            '$challengeNumber',
            steps,
            ScoringRules.clue.totalSteps,
            score,
            grid.toEmojiGrid(),
          )
        : l10n.shareLose('$challengeNumber', grid.toEmojiGrid());

    var shared = false;
    try {
      final result = await Share.share(text, subject: 'Cineus');
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
        backgroundColor: (config.won ? AppColors.success500 : AppColors.ruby300)
            .withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Shares the film just played as a challenge (D10).
  ///
  /// Only offered after the game is over — sharing a film mid-play would leak the
  /// answer to the sender's own session.
  Future<void> _shareChallenge(int movieId) async {
    final l10n = context.l10n;
    final text = l10n.challengeShareText(
      ChallengeCode.encode(movieId),
      ChallengeCode.linkFor(movieId).toString(),
    );

    try {
      await Share.share(text, subject: 'Cineus');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.resultCopied),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

    // On a loss the whole board is spent, so the grid shows every step used.
    final gridSteps = config.won
        ? session.revealedClues
        : state.rules.totalSteps;

    return RewardToast(
      child: Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) => Opacity(
            opacity: _fade.value,
            child: Transform.translate(
              offset: Offset(0, _slide.value),
              child: child,
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const FilmStrip(),
                const SizedBox(height: 20),
                _buildBadge(),
                const SizedBox(height: 20),

                if (config.showScore) ...[
                  _buildScore(context, session.score),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      context.l10n.gotItOnClue(session.revealedClues),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.obsidian200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (config.showRevealLabel) ...[
                  Center(
                    child: Text(
                      context.l10n.theMovieWas,
                      style: AppTypography.overline.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                PosterCard(movie: movie, height: config.posterHeight),

                if (config.showTagline &&
                    movie.tagline != null &&
                    movie.tagline!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '"${movie.tagline}"',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.obsidian200,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                _buildShareBlock(state.challengeNumber, session, gridSteps),
                const SizedBox(height: 24),

                const CountdownTimer(),
                const SizedBox(height: 20),

                _buildNavigation(state),
                const SizedBox(height: 12),

                // Send this film to a friend (D10)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _shareChallenge(movie.id),
                    icon: const Icon(Icons.emoji_events_outlined, size: 18),
                    label: Text(context.l10n.challengeShareButton),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
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

  Widget _buildScore(BuildContext context, int score) {
    final scoreColor = AppColors.scoreColor(score);
    return Center(
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [scoreColor, scoreColor.withValues(alpha: 0.7)],
            ).createShader(bounds),
            child: Text(
              '$score',
              style: AppTypography.scoreLarge.copyWith(
                color: Colors.white,
                fontSize: 80,
              ),
            ),
          ),
          Text(
            context.l10n.scorePoints,
            style: AppTypography.overline.copyWith(
              color: scoreColor.withValues(alpha: 0.7),
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareBlock(
    int challengeNumber,
    GameSession session,
    int gridSteps,
  ) {
    Future<void> onShare() => _share(challengeNumber, session.score, gridSteps);

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
                    onPressed: onShare,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(context.l10n.share),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold300,
                      foregroundColor: AppColors.obsidian900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: Text(context.l10n.share),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(PlayState state) {
    final nextMovieId = _nextMovieInStage(state);
    final posterAsync = ref.watch(dailySessionProvider(GameMode.poster));
    final showPosterButton =
        !state.isStage && posterAsync.valueOrNull?.isFinished != true;
    final hasTickets = ref.watch(ticketNotifierProvider).hasTickets;

    return Column(
      children: [
        if (showPosterButton) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/visual/play'),
              icon: const Icon(
                Icons.image_search_rounded,
                size: 18,
                color: AppColors.obsidian900,
              ),
              label: Text(context.l10n.playPosterArrow),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold300,
                foregroundColor: AppColors.obsidian900,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (nextMovieId != null) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              // Starting the next film costs a ticket, same as launching it from
              // the stage list.
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
                      // `mounted` on the State: `context` here is State.context.
                      if (!started || !mounted) return;
                      context.go('/game');
                    }
                  : null,
              icon: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: config.nextFilmForeground,
              ),
              label: Text(
                hasTickets
                    ? context.l10n.nextFilmCost
                    : context.l10n.noTicketsForNext,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: config.nextFilmColor,
                foregroundColor: config.nextFilmForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
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
        ),
      ],
    );
  }

  /// Next film after the current one in the stage order, if any.
  static int? _nextMovieInStage(PlayState state) {
    if (!state.isStage || state.movie == null || state.stageMovieIds.isEmpty) {
      return null;
    }
    final idx = state.stageMovieIds.indexOf(state.movie!.id);
    if (idx < 0 || idx >= state.stageMovieIds.length - 1) return null;
    return state.stageMovieIds[idx + 1];
  }
}
