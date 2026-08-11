import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/daily_selector.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/movie.dart';
import '../../l10n/app_l10n.dart';
import '../l10n_mappers.dart';
import '../providers/game_actions.dart';
import '../providers/play_notifier.dart';
import '../providers/providers.dart';
import '../widgets/tap_target.dart';

// ---------------------------------------------------------------------------
// Configuration for generic stage detail
// ---------------------------------------------------------------------------

/// What differs between the clue stage list and the poster stage list.
///
/// Now that both modes run through one [PlayNotifier], the mode alone is enough
/// — the config used to carry `loadAction`/`resetAction` closures purely to
/// reach whichever of the two notifiers applied.
class StageDetailConfig {
  final GameMode mode;
  final String playRoute;

  const StageDetailConfig({required this.mode, required this.playRoute});

  bool get isPoster => mode == GameMode.poster;

  /// "Film" / "Poster" — used for the placeholder name of an unplayed slot.
  String itemLabel(AppL10n l10n) => isPoster ? l10n.itemPoster : l10n.itemFilm;

  /// "films done" / "posters done" — the progress line in the header.
  String doneLabel(AppL10n l10n) =>
      isPoster ? l10n.postersDone : l10n.filmsDone;

  StateNotifierProvider<PlayNotifier, PlayState> get gameProvider =>
      isPoster ? posterGameProvider : clueGameProvider;
}

// ---------------------------------------------------------------------------
// Per-film slot provider (auto-disposes; refreshes when any game ends)
// ---------------------------------------------------------------------------

final _slotProvider = FutureProvider.autoDispose.family<_SlotData, _SlotArgs>((
  ref,
  args,
) async {
  // Re-fetch whenever a game session status changes (win or lose)
  ref.watch(clueGameProvider.select((s) => s.session?.status));
  ref.watch(posterGameProvider.select((s) => s.session?.status));

  final movieRepo = ref.watch(movieRepositoryProvider);
  final gameRepo = ref.watch(gameRepositoryProvider);

  final movie = await movieRepo.getMovieById(args.movieId);
  final session = await gameRepo.getStageSession(
    args.mode,
    args.stageId,
    args.movieId,
  );

  return _SlotData(movie: movie, session: session);
});

class _SlotArgs {
  final GameMode mode;
  final int stageId;
  final int movieId;
  const _SlotArgs(this.mode, this.stageId, this.movieId);

  @override
  bool operator ==(Object other) =>
      other is _SlotArgs &&
      mode == other.mode &&
      stageId == other.stageId &&
      movieId == other.movieId;

  @override
  int get hashCode => Object.hash(mode, stageId, movieId);
}

class _SlotData {
  final Movie? movie;
  final GameSession? session;
  const _SlotData({this.movie, this.session});

  bool get isWon => session?.status == GameStatus.won;
  bool get isLost => session?.status == GameStatus.lost;
  bool get isInProgress =>
      session != null && session!.status == GameStatus.playing;
}

// ---------------------------------------------------------------------------
// GenericStageDetailScreen
// ---------------------------------------------------------------------------

class GenericStageDetailScreen extends ConsumerWidget {
  final int stageId;
  final StageDetailConfig config;

  const GenericStageDetailScreen({
    super.key,
    required this.stageId,
    required this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = config.isPoster
        ? ref.watch(posterStageNotifierProvider)
        : ref.watch(stageNotifierProvider);

    return stagesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.gold300),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: Center(
          child: Text(
            context.l10n.genericLoadError,
            style: AppTypography.bodyMedium,
          ),
        ),
      ),
      data: (stages) {
        final stage = stages.firstWhere(
          (s) => s.id == stageId,
          orElse: () => stages.first,
        );

        // Deterministic shuffle: clue stages and poster stages get different
        // orderings so knowing one doesn't trivially reveal the other.
        final seedConstant = config.isPoster
            ? AppConstants.posterStageSeed
            : AppConstants.cluesStageSeed;
        final orderedIds = DailySelector.shuffleStage(
          stage.movieIds,
          stageId,
          seedConstant,
        );

        return Scaffold(
          backgroundColor: AppColors.obsidian950,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  context,
                  stage.name,
                  stage.completedCount,
                  stage.totalMovies,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: orderedIds.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final movieId = orderedIds[i];
                      return _FilmRow(
                        filmNumber: i + 1,
                        movieId: movieId,
                        stageId: stageId,
                        config: config,
                        stageMovieIds: orderedIds,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String name, int done, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.titleMedium),
                Text(
                  context.l10n.stageProgressLine(
                    done,
                    total,
                    config.doneLabel(context.l10n),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Film row widget
// ---------------------------------------------------------------------------

class _FilmRow extends ConsumerWidget {
  final int filmNumber;
  final int movieId;
  final int stageId;
  final StageDetailConfig config;
  final List<int> stageMovieIds;

  const _FilmRow({
    required this.filmNumber,
    required this.movieId,
    required this.stageId,
    required this.config,
    required this.stageMovieIds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotAsync = ref.watch(
      _slotProvider(_SlotArgs(config.mode, stageId, movieId)),
    );

    return slotAsync.when(
      loading: () => _skeletonRow(),
      error: (_, _) => const SizedBox.shrink(),
      data: (slot) => _buildRow(context, ref, slot),
    );
  }

  Widget _buildRow(BuildContext context, WidgetRef ref, _SlotData slot) {
    final tickets = ref.watch(ticketNotifierProvider);
    final hasTickets = tickets.hasTickets;

    final isWon = slot.isWon;
    final isLost = slot.isLost;
    final isInProgress = slot.isInProgress;
    final isKnown = isWon || isLost;

    Color borderColor;
    if (isWon) {
      borderColor = AppColors.success400.withValues(alpha: 0.4);
    } else if (isLost) {
      borderColor = AppColors.ruby300.withValues(alpha: 0.4);
    } else if (isInProgress) {
      borderColor = AppColors.gold300.withValues(alpha: 0.4);
    } else {
      borderColor = AppColors.obsidian600;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.obsidian800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left: poster thumbnail when known, number badge otherwise
          if (isKnown)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/posters/$movieId.webp',
                width: 40,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 40,
                  height: 56,
                  color: AppColors.obsidian700,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.movie_rounded,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 36,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.obsidian700,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$filmNumber',
                style: AppTypography.monoSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.obsidian200,
                ),
              ),
            ),
          const SizedBox(width: 12),

          // Film info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isKnown
                      ? (slot.movie?.title ??
                            '${config.itemLabel(context.l10n)} $filmNumber')
                      : '${config.itemLabel(context.l10n)} $filmNumber',
                  style: AppTypography.labelLarge.copyWith(
                    color: isWon
                        ? AppColors.obsidian0
                        : isLost
                        ? AppColors.obsidian200
                        : AppColors.obsidian300,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel(
                    context.l10n,
                    isWon,
                    isLost,
                    isInProgress,
                    slot.session?.score,
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: isWon
                        ? AppColors.success400
                        : isLost
                        ? AppColors.ruby300
                        : AppColors.obsidian400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action button
          if (isWon)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success400,
              size: 22,
            )
          else if (isLost)
            _retryButton(context, ref, hasTickets)
          else if (isInProgress)
            _continueButton(context, ref)
          else
            _playButton(context, ref, hasTickets),
        ],
      ),
    );
  }

  String _statusLabel(
    AppL10n l10n,
    bool won,
    bool lost,
    bool inProgress,
    int? score,
  ) {
    if (won) {
      return score != null ? l10n.slotPoints(score) : l10n.slotCompleted;
    }
    if (lost) return l10n.slotMissedRetry;
    if (inProgress) return l10n.slotInProgress;
    return l10n.slotNotStarted;
  }

  Widget _playButton(BuildContext context, WidgetRef ref, bool hasTickets) {
    return _SlotActionButton(
      label: hasTickets ? context.l10n.actionPlay : context.l10n.noTicketsShort,
      color: hasTickets ? AppColors.gold300 : AppColors.obsidian400,
      onTap: hasTickets
          ? () async {
              HapticFeedback.lightImpact();
              final started = await startFilmWithTicket(
                ref,
                () => ref
                    .read(config.gameProvider.notifier)
                    .loadStageFilm(movieId, stageId, stageMovieIds),
              );
              if (!started || !context.mounted) return;
              context.push(config.playRoute);
            }
          : null,
    );
  }

  Widget _continueButton(BuildContext context, WidgetRef ref) {
    return _SlotActionButton(
      label: context.l10n.actionContinue,
      color: AppColors.gold300,
      onTap: () async {
        HapticFeedback.lightImpact();
        await ref
            .read(config.gameProvider.notifier)
            .loadStageFilm(movieId, stageId, stageMovieIds);
        if (!context.mounted) return;
        context.push(config.playRoute);
      },
    );
  }

  Widget _retryButton(BuildContext context, WidgetRef ref, bool hasTickets) {
    return _SlotActionButton(
      label: hasTickets
          ? context.l10n.actionRetry
          : context.l10n.noTicketsShort,
      color: hasTickets ? AppColors.ruby300 : AppColors.obsidian400,
      onTap: hasTickets
          ? () async {
              HapticFeedback.lightImpact();
              final started = await startFilmWithTicket(
                ref,
                () => ref
                    .read(config.gameProvider.notifier)
                    .resetStageFilm(movieId, stageId, stageMovieIds),
              );
              if (!started || !context.mounted) return;
              context.push(config.playRoute);
            }
          : null,
    );
  }

  Widget _skeletonRow() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.obsidian800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.obsidian600),
      ),
    );
  }
}

class _SlotActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _SlotActionButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: color, fontSize: 12),
        ),
      ),
    );
  }
}
