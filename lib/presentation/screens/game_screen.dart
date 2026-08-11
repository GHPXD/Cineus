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
  final VoidCallback onNavigateToSearch;
  final VoidCallback onNavigateToVictory;
  final VoidCallback onNavigateToDefeat;
  final VoidCallback onNavigateToStats;
  final VoidCallback onNavigateToHowToPlay;
  final VoidCallback onNavigateBack;

  const GameScreen({
    super.key,
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
      if (current.movie == null) {
        ref.read(clueGameProvider.notifier).loadDaily();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clueGameProvider);

    // Redirect to result screens when game is over
    ref.listen<PlayState>(clueGameProvider, (prev, next) {
      if (prev?.session?.status == GameStatus.playing) {
        final finished =
            next.session?.status == GameStatus.won ||
            next.session?.status == GameStatus.lost;
        if (finished) {
          // Stats, the daily card and the stage grid all derive from this.
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
      // Franchise hint banner
      if (next.lastGuessOutcome == GuessOutcome.franchise &&
          next.guessCount != prev?.guessCount) {
        showFranchiseHint(context);
      }
    });

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold300),
        ),
      );
    }

    if (state.error != null) {
      return Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: Center(
          child: Text(state.error!, style: AppTypography.bodyMedium),
        ),
      );
    }

    final movie = state.movie!;
    final session = state.session!;

    // If already finished, show minimal state with navigation
    if (session.isFinished) {
      return _buildFinishedState(context, session);
    }

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          children: [
            // Game header
            _buildHeader(context, state.challengeNumber),

            // Scrollable content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                children: [
                  // Score badge
                  ScoreBadge(
                    score: session.potentialScore,
                    revealedClues: session.revealedClues,
                  ),
                  const SizedBox(height: 16),

                  // Clues section header
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

                  // Paid hints — cost tickets, not points
                  ExtraHintsBar(state: state),
                  const SizedBox(height: 18),

                  // Clue list
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

      // Bottom action bar
      bottomSheet: _buildBottomActions(context, session),
    );
  }

  Widget _buildHeader(BuildContext context, int challengeNumber) {
    final gameState = ref.watch(clueGameProvider);
    final isStage = gameState.isStage;
    final tickets = ref.watch(ticketNotifierProvider);

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
          Text.rich(
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
                if (!isStage)
                  TextSpan(
                    text: '  #$challengeNumber',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                if (isStage)
                  TextSpan(
                    text:
                        '  ${context.l10n.stageNumber('${gameState.stageId}')}',
                    style: AppTypography.monoSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          // Ticket badge
          Container(
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
          const SizedBox(width: 6),
          _HeaderButton(
            icon: Icons.bar_chart_rounded,
            label: context.l10n.semStats,
            onTap: widget.onNavigateToStats,
          ),
          const SizedBox(width: 6),
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
          // Clue progress indicator
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

          // Urgency banner
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
                      isLastClue
                          ? context.l10n.lastClueNowOrNever
                          : context.l10n.fewPointsLeft,
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

          // Guess button
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

          // Skip button — only shown when not on last clue
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
                icon: Icon(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.status == GameStatus.won
                    ? context.l10n.youGotIt
                    : context.l10n.notThisTime,
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                session.status == GameStatus.won
                    ? context.l10n.scoreLine(session.score)
                    : context.l10n.tryAgainTomorrow,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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
