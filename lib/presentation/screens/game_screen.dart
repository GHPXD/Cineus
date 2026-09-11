import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/game_actions.dart';
import '../providers/play_notifier.dart';
import '../providers/providers.dart';
import '../widgets/clue_list_widget.dart';
import '../widgets/extra_hints_bar.dart';
import '../widgets/score_badge_widget.dart';
import '../widgets/tap_target.dart';

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
        final finished = next.session?.status == GameStatus.won ||
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
      if (next.lastGuessOutcome == GuessOutcome.franchise &&
          next.guessCount != prev?.guessCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.franchiseHint,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF8B6914),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    final waitingForDaily = widget.expectedKind == SessionKind.daily &&
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

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                children: [
                  ScoreBadge(
                    score: session.potentialScore,
                    revealedClues: session.revealedClues,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        context.l10n.cluesHeader,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        context.l10n.cluesRevealed(
                          session.revealedClues,
                          state.rules.totalSteps,
                        ),
                        style: AppTypography.monoSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ExtraHintsBar(state: state),
                  const SizedBox(height: 18),
                  ClueList(
                    allClues: movie.clues,
                    revealedCount: session.revealedClues,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomActions(context, session),
    );
  }

  String _errorMessage(BuildContext context, PlayLoadError error) => switch (error) {
        PlayLoadError.noMovies => context.l10n.noMoviesInDatabase,
        PlayLoadError.movieNotFound => context.l10n.movieNotFound,
        PlayLoadError.loadFailed => context.l10n.gameLoadFailed,
      };

  Widget _buildHeader(BuildContext context, PlayState gameState) {
    final tickets = ref.watch(ticketNotifierProvider);
    final session = gameState.session!;

    final contextLabel = switch (session.kind) {
      SessionKind.daily => '#${gameState.challengeNumber}',
      SessionKind.stage => context.l10n.stageNumber('${session.stageId}'),
      SessionKind.challenge => context.l10n.challengeBadge,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _HeaderButton(
            icon: Icons.arrow_back_ios_rounded,
            label: context.l10n.semBack,
            onTap: widget.onNavigateBack,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Cineus',
                    style: TextStyle(
                      fontFamily: AppFonts.playfair,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '  $contextLabel',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            label: context.l10n.semTicketBalance(tickets.total),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gold900.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold300.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '🎫 ${tickets.total}',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.gold300,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          _HeaderButton(
            icon: Icons.bar_chart_rounded,
            label: context.l10n.semStats,
            onTap: widget.onNavigateToStats,
          ),
          _HeaderButton(
            icon: Icons.help_outline_rounded,
            label: context.l10n.semHelp,
            onTap: widget.onNavigateToHowToPlay,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, GameSession session) {
    final score = session.potentialScore;
    final isUrgent = score <= 3;
    final clueNum = session.revealedClues;
    final isLastClue = clueNum >= 10;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        bottomInset > 0 ? bottomInset + 8 : 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.obsidian950.withValues(alpha: 0),
            AppColors.obsidian950,
            AppColors.obsidian950,
          ],
          stops: const [0, 0.28, 1],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(10, (i) {
                final revealed = i < clueNum;
                final current = i == clueNum - 1;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: current ? 20 : 8,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: revealed
                        ? (current ? AppColors.gold300 : AppColors.obsidian400)
                        : AppColors.obsidian700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          if (isUrgent && !isLastClue)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.ruby300.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.ruby300.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.fewPointsLeft,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ruby300,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isLastClue)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.ruby300.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.ruby300.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.lastClueNowOrNever,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.ruby300,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                widget.onNavigateToSearch();
              },
              icon: const Text('🎬', style: TextStyle(fontSize: 18)),
              label: Text(
                isLastClue
                    ? context.l10n.lastAttempt
                    : context.l10n.tryAnswerClue(clueNum),
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.obsidian900,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUrgent
                    ? AppColors.ruby300
                    : AppColors.gold300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
            ),
          ),
          if (!isLastClue) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(clueGameProvider.notifier).revealNext();
                },
                icon: const Icon(
                  Icons.skip_next_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                label: Text(
                  context.l10n.skipToClue(clueNum + 1),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

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
                  const Icon(
                    Icons.movie_filter_outlined,
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
                        icon: const Icon(Icons.refresh_rounded),
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

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapTarget(
      label: label,
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}