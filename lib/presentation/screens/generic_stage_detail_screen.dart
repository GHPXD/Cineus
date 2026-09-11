import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class StageDetailConfig {
  final GameMode mode;
  final String playRoute;

  const StageDetailConfig({
    required this.mode,
    required this.playRoute,
  });

  bool get isPoster => mode == GameMode.poster;
  String get stagesRoute => isPoster ? '/visual' : '/stages';
  String itemLabel(AppL10n l10n) => isPoster ? l10n.itemPoster : l10n.itemFilm;
  String doneLabel(AppL10n l10n) => isPoster ? l10n.postersDone : l10n.filmsDone;

  StateNotifierProvider<PlayNotifier, PlayState> get gameProvider =>
      isPoster ? posterGameProvider : clueGameProvider;
}

final _slotProvider = FutureProvider.autoDispose.family<_SlotData, _SlotArgs>(
  (ref, args) async {
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
  },
);

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
  bool get isInProgress => session?.status == GameStatus.playing;
}

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
      error: (_, __) => _StageProblemView(
        message: context.l10n.gameLoadFailed,
        primaryLabel: context.l10n.retryAction,
        onPrimary: () {
          if (config.isPoster) {
            ref.invalidate(posterStageNotifierProvider);
          } else {
            ref.invalidate(stageNotifierProvider);
          }
        },
        secondaryLabel: context.l10n.backToStages,
        onSecondary: () => context.go(config.stagesRoute),
      ),
      data: (stages) {
        final matches = stages.where((s) => s.id == stageId);
        if (matches.isEmpty) {
          return _StageProblemView(
            message: context.l10n.stageNotFound,
            primaryLabel: context.l10n.backToStages,
            onPrimary: () => context.go(config.stagesRoute),
          );
        }

        final stage = matches.first;
        final seedConstant = config.isPoster
            ? AppConstants.posterStageSeed
            : AppConstants.cluesStageSeed;
        final orderedIds =
            DailySelector.shuffleStage(stage.movieIds, stageId, seedConstant);

        return Scaffold(
          backgroundColor: AppColors.obsidian950,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  context,
                  stage.id,
                  stage.completedCount,
                  stage.totalMovies,
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        itemCount: orderedIds.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int id,
    int done,
    int total,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 20, 0),
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
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.stageNumber('$id'),
                  style: AppTypography.titleMedium,
                ),
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

  _SlotArgs get args => _SlotArgs(config.mode, stageId, movieId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotAsync = ref.watch(_slotProvider(args));
    return slotAsync.when(
      loading: _skeletonRow,
      error: (_, __) => _slotErrorRow(context, ref),
      data: (slot) => _buildRow(context, ref, slot),
    );
  }

  Widget _slotErrorRow(BuildContext context, WidgetRef ref) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ruby900.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.ruby300.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.ruby300),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.gameLoadFailed,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(_slotProvider(args)),
            child: Text(context.l10n.retryAction),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, WidgetRef ref, _SlotData slot) {
    final hasTickets = ref.watch(ticketNotifierProvider).hasTickets;
    final isWon = slot.isWon;
    final isLost = slot.isLost;
    final isInProgress = slot.isInProgress;
    final isKnown = isWon || isLost;

    final borderColor = isWon
        ? AppColors.success400.withValues(alpha: 0.4)
        : isLost
            ? AppColors.ruby300.withValues(alpha: 0.4)
            : isInProgress
                ? AppColors.gold300.withValues(alpha: 0.4)
                : AppColors.obsidian600;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.obsidian800,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (isKnown)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/posters/$movieId.jpg',
                width: 40,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
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
              width: 40,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.obsidian700,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                '$filmNumber',
                style: AppTypography.monoSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(width: 12),
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
                        : AppColors.textSecondary,
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
                    fontSize: 12,
                    color: isWon
                        ? AppColors.success400
                        : isLost
                            ? AppColors.ruby300
                            : isInProgress
                                ? AppColors.gold300
                                : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isWon)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success400,
              size: 24,
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
    if (won) return score != null ? l10n.slotPoints(score) : l10n.slotCompleted;
    if (lost) return l10n.slotMissedRetry;
    if (inProgress) return l10n.slotInProgress;
    return l10n.slotNotStarted;
  }

  Widget _playButton(BuildContext context, WidgetRef ref, bool hasTickets) {
    return _SlotActionButton(
      label: hasTickets ? context.l10n.actionPlay : context.l10n.noTicketsShort,
      color: hasTickets ? AppColors.gold300 : AppColors.textTertiary,
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
        final loaded = await ref
            .read(config.gameProvider.notifier)
            .loadStageFilm(movieId, stageId, stageMovieIds);
        if (!loaded || !context.mounted) return;
        context.push(config.playRoute);
      },
    );
  }

  Widget _retryButton(BuildContext context, WidgetRef ref, bool hasTickets) {
    return _SlotActionButton(
      label: hasTickets ? context.l10n.actionRetry : context.l10n.noTicketsShort,
      color: hasTickets ? AppColors.ruby300 : AppColors.textTertiary,
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
      height: 72,
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
    return TapTarget(
      label: label,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap == null ? 0.05 : 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: onTap == null ? 0.18 : 0.5),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StageProblemView extends StatelessWidget {
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _StageProblemView({
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
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
                    size: 52,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onPrimary,
                      child: Text(primaryLabel),
                    ),
                  ),
                  if (secondaryLabel != null && onSecondary != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: onSecondary,
                        child: Text(secondaryLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}