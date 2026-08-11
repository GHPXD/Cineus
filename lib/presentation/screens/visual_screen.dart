import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/game_actions.dart';
import '../providers/providers.dart';
import '../providers/play_notifier.dart';
import '../widgets/extra_hints_bar.dart';
import '../widgets/tap_target.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────────────────────

class VisualScreen extends ConsumerStatefulWidget {
  const VisualScreen({super.key});

  @override
  ConsumerState<VisualScreen> createState() => _VisualScreenState();
}

class _VisualScreenState extends ConsumerState<VisualScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final s = ref.read(posterGameProvider);
      // Only load daily if nothing is already loaded (avoids overwriting a
      // stage-mode movie that was loaded before navigation).
      if (s.isLoading || s.movie == null) {
        ref.read(posterGameProvider.notifier).loadDaily();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posterGameProvider);

    ref.listen<PlayState>(posterGameProvider, (prev, next) {
      if (prev?.isFinished == false && next.isFinished) {
        // Stats, the daily card and the poster stage grid all derive from this.
        refreshAfterGameFinished(
          ref,
          mode: GameMode.poster,
          stageId: next.stageId,
          finished: next.session,
        );
        if (next.session?.status == GameStatus.won) {
          context.push('/visual/victory');
        } else {
          context.push('/visual/defeat');
        }
      }
      // Franchise hint
      if (next.lastGuessOutcome == GuessOutcome.franchise &&
          next.guessCount != prev?.guessCount) {
        showFranchiseHint(context);
      }
    });

    if (state.isLoading) return const _LoadingView();
    if (state.error != null) return _ErrorView(error: state.error!);
    return _GameView(state: state);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / Error
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppColors.obsidian950,
    body: Center(child: CircularProgressIndicator(color: AppColors.gold300)),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.obsidian950,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          error,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Game view
// ─────────────────────────────────────────────────────────────────────────────

class _GameView extends ConsumerWidget {
  final PlayState state;
  const _GameView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, state),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  const SizedBox(height: 20),
                  _PosterArea(state: state),
                  const SizedBox(height: 24),
                  _LevelPips(state: state),
                  const SizedBox(height: 20),
                  if (!state.isFinished) ...[
                    ExtraHintsBar(state: state),
                    const SizedBox(height: 18),
                    _ActionButtons(state: state),
                  ],
                  if (state.isFinished) const _FinishedBanner(),
                  const SizedBox(height: 12),
                  _GuessHistory(guesses: state.session?.guesses ?? []),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PlayState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          TapTarget(
            label: context.l10n.semBack,
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.obsidian700,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.obsidian600),
              ),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                size: 16,
                color: AppColors.obsidian100,
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                TextSpan(
                  text: '  ${context.l10n.navPosters}',
                  style: AppTypography.monoSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (state.isFinished)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.obsidian700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                state.session?.status == GameStatus.won
                    ? context.l10n.scoreWithCheck(state.session!.score)
                    : context.l10n.gameOver,
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.obsidian200,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.obsidian700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.worthPoints(state.currentScore),
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.gold300,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Poster with animated blur
// ─────────────────────────────────────────────────────────────────────────────

class _PosterArea extends StatefulWidget {
  final PlayState state;
  const _PosterArea({required this.state});
  @override
  State<_PosterArea> createState() => _PosterAreaState();
}

class _PosterAreaState extends State<_PosterArea>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _sigmaAnim;
  double _prevSigma = 22.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    final target = widget.state.blurSigma;
    _sigmaAnim = Tween<double>(begin: target, end: target).animate(_ctrl);
    _prevSigma = target;
  }

  @override
  void didUpdateWidget(_PosterArea old) {
    super.didUpdateWidget(old);
    final newSigma = widget.state.blurSigma;
    if (newSigma != _prevSigma) {
      _sigmaAnim = Tween<double>(
        begin: _prevSigma,
        end: newSigma,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
      _prevSigma = newSigma;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posterAsset = widget.state.posterAsset;
    if (posterAsset == null) return const SizedBox.shrink();

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 260,
          height: 390,
          child: AnimatedBuilder(
            animation: _sigmaAnim,
            builder: (_, child) {
              final sigma = _sigmaAnim.value;
              if (sigma <= 0.5) return child!;
              return ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: sigma,
                  sigmaY: sigma,
                  tileMode: TileMode.clamp,
                ),
                child: child,
              );
            },
            child: Image.asset(
              posterAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: AppColors.obsidian700,
                child: const Icon(
                  Icons.movie_outlined,
                  size: 80,
                  color: AppColors.textQuaternary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level pips
// ─────────────────────────────────────────────────────────────────────────────

class _LevelPips extends StatelessWidget {
  final PlayState state;
  const _LevelPips({required this.state});

  @override
  Widget build(BuildContext context) {
    const labels = ['90%', '70%', '45%', '15%', '0%'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final revealed = i < state.step;
            final current = i == state.step - 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: current ? 44 : 32,
                height: current ? 44 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: revealed
                      ? (current
                            ? AppColors.gold300
                            : AppColors.gold300.withValues(alpha: 0.35))
                      : AppColors.obsidian700,
                  border: Border.all(
                    color: revealed
                        ? AppColors.gold300.withValues(alpha: 0.6)
                        : AppColors.obsidian600,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: AppTypography.monoSmall.copyWith(
                    fontSize: current ? 9 : 8,
                    color: revealed
                        ? AppColors.obsidian900
                        : AppColors.obsidian500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          state.isFinished
              ? (state.session?.status == GameStatus.won
                    ? context.l10n.gotItAtLevel(state.step)
                    : context.l10n.betterLuckTomorrow)
              : context.l10n.blurAndPoints(state.blurLabel, state.currentScore),
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final PlayState state;
  const _ActionButtons({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/visual/search'),
            icon: const Icon(Icons.search_rounded, size: 20),
            label: Text(
              context.l10n.tryAnswerPoints(state.currentScore),
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.obsidian900,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold300,
              foregroundColor: AppColors.obsidian900,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
          ),
        ),
        if (state.canRevealMore) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton.icon(
              onPressed: () =>
                  ref.read(posterGameProvider.notifier).revealNext(),
              icon: const Icon(
                Icons.visibility_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              label: Text(
                context.l10n.revealMore,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Finished banner (shown in place of action buttons)
// ─────────────────────────────────────────────────────────────────────────────

class _FinishedBanner extends ConsumerWidget {
  const _FinishedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posterGameProvider);
    final won = state.session?.status == GameStatus.won;

    // Determine next movie in stage sequence
    int? nextMovieId;
    final movie = state.movie;
    if (state.stageId != null &&
        movie != null &&
        state.stageMovieIds.isNotEmpty) {
      final idx = state.stageMovieIds.indexOf(movie.id);
      if (idx >= 0 && idx < state.stageMovieIds.length - 1) {
        nextMovieId = state.stageMovieIds[idx + 1];
      }
    }

    // Advancing to the next film in a stage starts a new game, so it costs a
    // ticket exactly like starting it from the stage list would.
    final hasTickets = ref.watch(ticketNotifierProvider).hasTickets;
    final canAdvance = nextMovieId != null && hasTickets;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: (won ? AppColors.gold300 : AppColors.ruby300).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (won ? AppColors.gold300 : AppColors.ruby300).withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(won ? '🏆' : '💀', style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            state.movie?.title ?? '',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge,
          ),
          if (state.movie?.originalTitle != null &&
              state.movie!.originalTitle != state.movie!.title) ...[
            const SizedBox(height: 2),
            Text(
              state.movie!.originalTitle!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            won
                ? context.l10n.pointsPlain(state.session!.score)
                : context.l10n.youDidntGuess,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                if (nextMovieId == null || state.stageId == null) {
                  context.pop();
                  return;
                }
                if (!hasTickets) return;
                await startFilmWithTicket(
                  ref,
                  () => ref
                      .read(posterGameProvider.notifier)
                      .loadStageFilm(
                        nextMovieId!,
                        state.stageId!,
                        state.stageMovieIds,
                      ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: won ? AppColors.gold300 : AppColors.ruby300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Text(
                nextMovieId == null
                    ? context.l10n.finish
                    : canAdvance
                    ? context.l10n.nextWithTicket
                    : context.l10n.noTicketsShort,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.obsidian900,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wrong guess history
// ─────────────────────────────────────────────────────────────────────────────

class _GuessHistory extends StatelessWidget {
  final List<String> guesses;
  const _GuessHistory({required this.guesses});

  @override
  Widget build(BuildContext context) {
    if (guesses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.wrongAttemptsHeader,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ...guesses.map(
          (g) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ruby300.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.ruby300.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.close_rounded,
                    color: AppColors.ruby300,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    g,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.obsidian200,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Victory screen
// ─────────────────────────────────────────────────────────────────────────────

class VisualVictoryScreen extends ConsumerWidget {
  const VisualVictoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posterGameProvider);
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎬🏆', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 20),
                Text(
                  context.l10n.youRecognized,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  state.movie?.title ?? '',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.gold300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.pointsPlain(state.session?.score ?? 0),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => state.stageId != null
                        ? context.pop()
                        : context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      context.l10n.back,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.obsidian900,
                      ),
                    ),
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
// Defeat screen
// ─────────────────────────────────────────────────────────────────────────────

class VisualDefeatScreen extends ConsumerWidget {
  const VisualDefeatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posterGameProvider);
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💀🎬', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 20),
                Text(
                  context.l10n.didntRecognize,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.itWas(state.movie?.title ?? '?'),
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.ruby300,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => state.stageId != null
                        ? context.pop()
                        : context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ruby300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      context.l10n.back,
                      style: AppTypography.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
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
