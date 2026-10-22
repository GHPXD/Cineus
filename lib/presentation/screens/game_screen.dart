import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/game_actions.dart';
import '../providers/play_notifier.dart';
import '../widgets/franchise_hint_snackbar.dart';
import '../widgets/clue_list_widget.dart';
import '../widgets/extra_hints_bar.dart';
import '../widgets/score_badge_widget.dart';
import '../widgets/gameplay_widgets.dart';
import '../widgets/cineus_icon.dart';
import '../visuals/cineus_assets.dart';

class GameScreen extends ConsumerStatefulWidget {
  final SessionKind expectedKind;
  final VoidCallback onNavigateToSearch;
  final VoidCallback onNavigateToVictory;
  final VoidCallback onNavigateToDefeat;
  final VoidCallback onNavigateToStats;
  final VoidCallback onNavigateToHowToPlay;
  final VoidCallback onNavigateBack;

  const GameScreen({
    super.key,
    this.expectedKind = SessionKind.daily,
    required this.onNavigateToSearch,
    required this.onNavigateToVictory,
    required this.onNavigateToDefeat,
    required this.onNavigateToStats,
    required this.onNavigateToHowToPlay,
    required this.onNavigateBack,
  });

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _scroll = ScrollController();
  final _cardKeys = {for (var n = 1; n <= 10; n++) n: GlobalKey()};
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _positionClue(int number) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _cardKeys[number]?.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: .05,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
      );
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.l10n.clueRevealedAnnouncement(number),
        Directionality.of(context),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final current = ref.read(clueGameProvider);
      // Daily routes are the only routes that can reconstruct themselves from
      // scratch. Explicit stage/challenge routes are loaded before navigation.
      // This prevents an old stage/challenge held by the global provider from
      // leaking into the Home daily CTA, including across the UTC day rollover.
      if (widget.expectedKind == SessionKind.daily && !current.isCurrentDaily) {
        ref.read(clueGameProvider.notifier).loadDaily();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clueGameProvider);

    ref.listen<PlayState>(clueGameProvider, (prev, next) {
      if (prev?.session?.status == GameStatus.playing) {
        final finished =
            next.session?.status == GameStatus.won ||
            next.session?.status == GameStatus.lost;
        if (finished) {
          refreshAfterGameFinished(
            ref,
            mode: GameMode.clue,
            stageId: next.stageId,
            finished: next.session,
          );
        }
        if (next.session?.status == GameStatus.won) {
          widget.onNavigateToVictory();
        } else if (next.session?.status == GameStatus.lost) {
          widget.onNavigateToDefeat();
        }
      }
      if (next.step > (prev?.step ?? next.step) && !next.isFinished) {
        _positionClue(next.step);
      }
      if (next.lastGuessOutcome == GuessOutcome.franchise &&
          next.guessCount != prev?.guessCount) {
        showFranchiseHintSnackBar(context);
      }
    });

    final waitingForDaily =
        widget.expectedKind == SessionKind.daily &&
        !state.isCurrentDaily &&
        state.error == null;
    if (state.isLoading || waitingForDaily) {
      return _GameLoadingView(label: context.l10n.loadingGame);
    }

    if (state.error != null) {
      return _GameErrorView(
        message: _errorMessage(context, state.error!),
        onRetry: widget.expectedKind == SessionKind.daily
            ? () => ref.read(clueGameProvider.notifier).loadDaily()
            : null,
        onBack: widget.onNavigateBack,
      );
    }

    if (state.session?.kind != widget.expectedKind ||
        state.movie == null ||
        state.session == null) {
      return _GameErrorView(
        message: context.l10n.gameLoadFailed,
        onBack: widget.onNavigateBack,
      );
    }

    final movie = state.movie!;
    final session = state.session!;

    if (session.isFinished) {
      return _buildFinishedState(context, session);
    }

    return GameplayFrame(
      header: GameplayHeader(
        state: state,
        onBack: widget.onNavigateBack,
        onStats: widget.onNavigateToStats,
        onHelp: widget.onNavigateToHowToPlay,
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScoreBadge(score: session.potentialScore),
            const SizedBox(height: 16),
            GuessFeedback(state: state),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(context.l10n.cluesHeader, style: AppTypography.labelSmall),
                Text(
                  context.l10n.cluesRevealed(
                    session.revealedClues,
                    state.rules.totalSteps,
                  ),
                  style: AppTypography.monoSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ExtraHintsBar(state: state),
            const SizedBox(height: 16),
            ClueList(
              allClues: movie.clues,
              revealedCount: session.revealedClues,
              cardKeys: _cardKeys,
            ),
          ],
        ),
      ),
      actions: GameplayActions(
        state: state,
        onSearch: widget.onNavigateToSearch,
      ),
    );
  }

  String _errorMessage(BuildContext context, PlayLoadError error) =>
      switch (error) {
        PlayLoadError.noMovies => context.l10n.noMoviesInDatabase,
        PlayLoadError.movieNotFound => context.l10n.movieNotFound,
        PlayLoadError.loadFailed => context.l10n.gameLoadFailed,
      };

  Widget _buildFinishedState(BuildContext context, GameSession session) {
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.status == GameStatus.won
                      ? context.l10n.youGotIt
                      : context.l10n.notThisTime,
                  style: AppTypography.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  session.status == GameStatus.won
                      ? context.l10n.scoreLine(session.score)
                      : context.l10n.tryAgainTomorrow,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: session.status == GameStatus.won
                      ? widget.onNavigateToVictory
                      : widget.onNavigateToDefeat,
                  child: Text(context.l10n.seeResult),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: widget.onNavigateBack,
                  child: Text(context.l10n.backHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameLoadingView extends StatelessWidget {
  final String label;
  const _GameLoadingView({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: Center(
        child: Semantics(
          liveRegion: true,
          label: label,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.gold300),
              const SizedBox(height: 16),
              Text(
                label,
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
}

class _GameErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onBack;

  const _GameErrorView({
    required this.message,
    required this.onBack,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
                  const CineusIcon(
                    CineusAssetId.error,
                    color: AppColors.ruby300,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  if (onRetry != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const CineusIcon(CineusAssetId.retry),
                        label: Text(context.l10n.retryAction),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onBack,
                      child: Text(context.l10n.back),
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
}
