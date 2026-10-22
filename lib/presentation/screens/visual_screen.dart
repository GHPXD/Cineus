import 'dart:ui';
import 'package:flutter/semantics.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/game_actions.dart';
import '../providers/providers.dart';
import '../providers/play_notifier.dart';
import '../widgets/franchise_hint_snackbar.dart';
import '../widgets/extra_hints_bar.dart';
import '../widgets/gameplay_widgets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/cineus_poster.dart';
import '../visuals/cineus_assets.dart';

class VisualScreen extends ConsumerStatefulWidget {
  final SessionKind expectedKind;

  const VisualScreen({super.key, this.expectedKind = SessionKind.daily});

  @override
  ConsumerState<VisualScreen> createState() => _VisualScreenState();
}

class _VisualScreenState extends ConsumerState<VisualScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final current = ref.read(posterGameProvider);
      if (widget.expectedKind == SessionKind.daily && !current.isCurrentDaily) {
        ref.read(posterGameProvider.notifier).loadDaily();
      }
    });
  }

  void _back(PlayState state) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (state.stageId != null) {
      context.go('/visual/stage/${state.stageId}');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posterGameProvider);

    ref.listen<PlayState>(posterGameProvider, (prev, next) {
      if (prev?.isFinished == false && next.isFinished) {
        refreshAfterGameFinished(
          ref,
          mode: GameMode.poster,
          stageId: next.stageId,
          finished: next.session,
        );
        if (!mounted) return;
        context.go(
          next.session?.status == GameStatus.won
              ? '/visual/victory'
              : '/visual/defeat',
        );
      }
      if (next.lastGuessOutcome == GuessOutcome.franchise &&
          next.guessCount != prev?.guessCount) {
        showFranchiseHintSnackBar(context);
      }
      if (next.step > (prev?.step ?? next.step) && !next.isFinished) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          context.l10n.posterRevealedAnnouncement(next.step),
          Directionality.of(context),
        );
      }
    });

    final waitingForDaily =
        widget.expectedKind == SessionKind.daily &&
        !state.isCurrentDaily &&
        state.error == null;
    if (state.isLoading || waitingForDaily) {
      return _LoadingView(label: context.l10n.loadingGame);
    }
    if (state.error != null) {
      return _ErrorView(
        error: _errorMessage(context, state.error!),
        onRetry: widget.expectedKind == SessionKind.daily
            ? () => ref.read(posterGameProvider.notifier).loadDaily()
            : null,
        onBack: () => _back(state),
      );
    }
    if (state.session?.kind != widget.expectedKind || state.movie == null) {
      return _ErrorView(
        error: context.l10n.gameLoadFailed,
        onBack: () => _back(state),
      );
    }
    return _GameView(state: state, onBack: () => _back(state));
  }

  String _errorMessage(BuildContext context, PlayLoadError error) =>
      switch (error) {
        PlayLoadError.noMovies => context.l10n.noMoviesInDatabase,
        PlayLoadError.movieNotFound => context.l10n.movieNotFound,
        PlayLoadError.loadFailed => context.l10n.gameLoadFailed,
      };
}

class _LoadingView extends StatelessWidget {
  final String label;
  const _LoadingView({required this.label});

  @override
  Widget build(BuildContext context) => Scaffold(
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

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final VoidCallback onBack;

  const _ErrorView({required this.error, required this.onBack, this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  size: 48,
                  color: AppColors.ruby300,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
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

class _GameView extends ConsumerWidget {
  final PlayState state;
  final VoidCallback onBack;

  const _GameView({required this.state, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GameplayFrame(
      header: GameplayHeader(state: state, onBack: onBack),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          children: [
            _PosterArea(
              state: state,
              maxHeight: (constraints.maxHeight * .55).clamp(100.0, 320.0),
            ),
            const SizedBox(height: 16),
            _LevelPips(state: state),
            const SizedBox(height: 12),
            GuessFeedback(state: state),
            if (!state.isFinished) ExtraHintsBar(state: state),
            if (state.isFinished) const _FinishedBanner(),
          ],
        ),
      ),
      actions: state.isFinished
          ? const SizedBox.shrink()
          : GameplayActions(
              state: state,
              onSearch: () => context.push('/visual/search'),
            ),
    );
  }
}

class _PosterArea extends StatefulWidget {
  final PlayState state;
  final double maxHeight;
  const _PosterArea({required this.state, required this.maxHeight});

  @override
  State<_PosterArea> createState() => _PosterAreaState();
}

class _PosterAreaState extends State<_PosterArea>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
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
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _sigmaAnim = AlwaysStoppedAnimation(newSigma);
      } else {
        _sigmaAnim = Tween<double>(
          begin: _prevSigma,
          end: newSigma,
        ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
        _ctrl
          ..reset()
          ..forward();
      }
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
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxHeight * 2 / 3),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _sigmaAnim,
              builder: (_, child) {
                final sigma = _sigmaAnim.value;
                return CineusPoster(
                  movieId: widget.state.movie!.id,
                  frameBuilder: (_, image, frame, synchronous) => sigma <= .5
                      ? image
                      : ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: sigma,
                            sigmaY: sigma,
                            tileMode: TileMode.clamp,
                          ),
                          child: image,
                        ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelPips extends StatelessWidget {
  final PlayState state;
  const _LevelPips({required this.state});

  @override
  Widget build(BuildContext context) {
    const labels = ['90%', '70%', '45%', '15%', '0%'];
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(5, (i) {
            final revealed = i < state.step;
            final current = i == state.step - 1;
            return IntrinsicWidth(
              child: AnimatedContainer(
                duration: (MediaQuery.disableAnimationsOf(context))
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                constraints: BoxConstraints(
                  minWidth: current ? 46 : 36,
                  minHeight: current ? 46 : 36,
                ),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
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
                    fontSize: current ? 11 : 10,
                    color: revealed
                        ? AppColors.obsidian900
                        : AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.posterStep(state.step, state.rules.totalSteps),
          style: AppTypography.labelLarge,
        ),
        Text(
          state.isFinished
              ? (state.session?.status == GameStatus.won
                    ? context.l10n.gotItAtLevel(state.step)
                    : context.l10n.betterLuckTomorrow)
              : context.l10n.blurAndPoints(state.blurLabel, state.currentScore),
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FinishedBanner extends ConsumerWidget {
  const _FinishedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posterGameProvider);
    final won = state.session?.status == GameStatus.won;

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
          CineusIcon(
            won ? CineusAssetId.resultVictory : CineusAssetId.resultDefeat,
            size: 40,
            color: won ? AppColors.gold300 : AppColors.ruby300,
          ),
          const SizedBox(height: 8),
          Text(
            state.movie?.title ?? '',
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge,
          ),
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
                  if (state.stageId != null) {
                    context.go('/visual/stage/${state.stageId}');
                  } else {
                    context.go('/home');
                  }
                  return;
                }
                if (!hasTickets) return;
                final started = await startFilmWithTicket(
                  ref,
                  () => ref
                      .read(posterGameProvider.notifier)
                      .loadStageFilm(
                        nextMovieId!,
                        state.stageId!,
                        state.stageMovieIds,
                      ),
                );
                if (!started || !context.mounted) return;
                context.go('/visual/play?source=stage');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: won ? AppColors.gold300 : AppColors.ruby300,
              ),
              child: Text(
                nextMovieId == null
                    ? context.l10n.finish
                    : canAdvance
                    ? context.l10n.nextWithTicket
                    : context.l10n.noTicketsShort,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.obsidian900,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VisualVictoryScreen extends ConsumerWidget {
  const VisualVictoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posterGameProvider);
    return _PosterResultScreen(state: state, won: true);
  }
}

class VisualDefeatScreen extends ConsumerWidget {
  const VisualDefeatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posterGameProvider);
    return _PosterResultScreen(state: state, won: false);
  }
}

class _PosterResultScreen extends StatelessWidget {
  final PlayState state;
  final bool won;

  const _PosterResultScreen({required this.state, required this.won});

  @override
  Widget build(BuildContext context) {
    final movie = state.movie;
    final session = state.session;
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              children: [
                Center(
                  child: CineusIcon(
                    won
                        ? CineusAssetId.resultVictory
                        : CineusAssetId.resultDefeat,
                    size: 64,
                    color: won ? AppColors.gold300 : AppColors.ruby300,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  won
                      ? context.l10n.youRecognized
                      : context.l10n.didntRecognize,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  won
                      ? (movie?.title ?? '')
                      : context.l10n.itWas(movie?.title ?? '?'),
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium.copyWith(
                    color: won ? AppColors.gold300 : AppColors.ruby300,
                  ),
                ),
                if (won) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.pointsPlain(session?.score ?? 0),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      if (state.stageId != null) {
                        context.go('/visual/stage/${state.stageId}');
                      } else {
                        context.go('/home');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: won
                          ? AppColors.gold300
                          : AppColors.ruby300,
                    ),
                    child: Text(
                      state.stageId != null
                          ? context.l10n.backToStages
                          : context.l10n.backHome,
                      style: AppTypography.labelLarge.copyWith(
                        color: won ? AppColors.obsidian900 : Colors.white,
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
