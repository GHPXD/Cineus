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
import '../l10n_mappers.dart';
import '../providers/game_actions.dart';
import '../providers/play_notifier.dart';
import '../providers/providers.dart';
import '../providers/growth_provider.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/tap_target.dart';
import '../widgets/ticket_details_sheet.dart';

class StageDetailConfig {
  final GameMode mode;
  final String playRoute;
  const StageDetailConfig({required this.mode, required this.playRoute});
  bool get isPoster => mode == GameMode.poster;
  String get stagesRoute => isPoster ? '/visual' : '/stages';
  StateNotifierProvider<PlayNotifier, PlayState> get gameProvider =>
      isPoster ? posterGameProvider : clueGameProvider;
}

class StageSlot {
  final int movieId;
  final GameSession? session;
  final Movie? movie;
  const StageSlot(this.movieId, this.session, this.movie);
}

final stageSlotsProvider = FutureProvider.autoDispose
    .family<List<StageSlot>, (GameMode, int)>((ref, args) async {
      final mode = args.$1;
      final stagesRepo = ref.read(stageRepositoryProvider);
      final games = ref.read(gameRepositoryProvider);
      final movies = ref.read(movieRepositoryProvider);
      final stages = await stagesRepo.getAllStages(mode: mode.name);
      final stage = stages.where((s) => s.id == args.$2).firstOrNull;
      if (stage == null || stage.isLocked) return [];
      final ids = DailySelector.shuffleStage(
        stage.movieIds,
        stage.id,
        mode == GameMode.clue
            ? AppConstants.cluesStageSeed
            : AppConstants.posterStageSeed,
      );
      return Future.wait(
        ids.map((id) async {
          final session = await games.getStageSession(mode, stage.id, id);
          final movie = session != null && session.status != GameStatus.playing
              ? await movies.getMovieById(id)
              : null;
          return StageSlot(id, session, movie);
        }),
      );
    });

class GenericStageDetailScreen extends ConsumerStatefulWidget {
  final int stageId;
  final StageDetailConfig config;
  const GenericStageDetailScreen({
    super.key,
    required this.stageId,
    required this.config,
  });
  @override
  ConsumerState<GenericStageDetailScreen> createState() => _StageDetailState();
}

class _StageDetailState extends ConsumerState<GenericStageDetailScreen> {
  int? _opening;
  StageDetailConfig get config => widget.config;
  void _back() =>
      context.canPop() ? context.pop() : context.go(config.stagesRoute);
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stagesProvider = config.isPoster
        ? posterStageNotifierProvider
        : stageNotifierProvider;
    final stages = ref.watch(stagesProvider);
    final tickets = ref.watch(ticketNotifierProvider);
    final slotsProvider = stageSlotsProvider((config.mode, widget.stageId));
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  TapTarget(
                    label: l.semBack,
                    onTap: _back,
                    child: const CineusIcon(CineusAssetId.back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.stageNumber('${widget.stageId}'),
                      style: AppTypography.pageTitle,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: stages.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _problem(
                      l.gameLoadFailed,
                      () => ref.read(stagesProvider.notifier).load(),
                    ),
                    data: (all) {
                      final stage = all
                          .where((s) => s.id == widget.stageId)
                          .firstOrNull;
                      if (stage == null) {
                        return _problem(l.stageNotFound, _back, retry: false);
                      }
                      if (stage.isLocked) {
                        final index = all.indexOf(stage);
                        return _problem(
                          l.stageUnlockAfter(
                            l.stageNumber(
                              '${all[index > 0 ? index - 1 : 0].id}',
                            ),
                          ),
                          _back,
                          retry: false,
                          icon: CineusAssetId.lock,
                        );
                      }
                      return ref
                          .watch(slotsProvider)
                          .when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (_, __) => _problem(
                              l.gameLoadFailed,
                              () => ref.invalidate(slotsProvider),
                            ),
                            data: (slots) {
                              final playing = slots
                                  .where(
                                    (s) =>
                                        s.session?.status == GameStatus.playing,
                                  )
                                  .firstOrNull;
                              final next =
                                  playing ??
                                  slots
                                      .where((s) => s.session == null)
                                      .firstOrNull ??
                                  slots
                                      .where(
                                        (s) =>
                                            s.session?.status ==
                                            GameStatus.lost,
                                      )
                                      .firstOrNull;
                              return ListView(
                                key: const ValueKey('stage-detail-scroll'),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  32,
                                ),
                                children: [
                                  Text(
                                    l.stageProgressLine(
                                      stage.completedCount,
                                      stage.totalMovies,
                                      config.isPoster
                                          ? l.postersDone
                                          : l.filmsDone,
                                    ),
                                    style: AppTypography.bodyMedium,
                                  ),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: stage.progress,
                                    color: AppColors.gold300,
                                    backgroundColor: AppColors.obsidian600,
                                  ),
                                  ref
                                      .watch(
                                        stageEconomyProvider((
                                          config.mode.name,
                                          stage.id,
                                        )),
                                      )
                                      .when(
                                        loading: () => const SizedBox.shrink(),
                                        error: (_, __) =>
                                            const SizedBox.shrink(),
                                        data: (bonus) => Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: Text(
                                            bonus == 4
                                                ? l.stageBonusTitleOffer(bonus)
                                                : l.stageBonusOffer(bonus),
                                            style: AppTypography.bodySmall,
                                          ),
                                        ),
                                      ),
                                  if (!tickets.hasTickets) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.blue300.withValues(
                                          alpha: .08,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const Align(
                                            alignment: Alignment.centerLeft,
                                            child: CineusIcon(
                                              CineusAssetId.ticket,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            l.stageNoTicketsHelp,
                                            style: AppTypography.bodySmall,
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              TextButton(
                                                onPressed: () =>
                                                    showTicketDetails(context),
                                                child: Text(
                                                  l.ticketDetailsTitle,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    context.go('/home'),
                                                child: Text(l.stageDailyAction),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 18),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final large =
                                          MediaQuery.textScalerOf(
                                            context,
                                          ).scale(14) >
                                          17;
                                      final columns = large
                                          ? 1
                                          : constraints.maxWidth >= 680
                                          ? 4
                                          : constraints.maxWidth >= 480
                                          ? 3
                                          : 2;
                                      final side =
                                          (constraints.maxWidth -
                                              10 * (columns - 1)) /
                                          columns;
                                      final ordered = [
                                        if (next != null) next,
                                        ...slots.where((slot) => slot != next),
                                      ];
                                      return Wrap(
                                        key: const ValueKey('stage-slots-grid'),
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          for (final slot in ordered)
                                            SizedBox.square(
                                              dimension: side,
                                              child: _slot(
                                                slot,
                                                slots.indexOf(slot) + 1,
                                                slots,
                                                featured: slot == next,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
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
  }

  Widget _problem(
    String message,
    VoidCallback action, {
    bool retry = true,
    CineusAssetId icon = CineusAssetId.error,
  }) {
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CineusIcon(icon, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: action,
            child: Text(retry ? l.retryAction : l.backToStages),
          ),
          if (retry) TextButton(onPressed: _back, child: Text(l.backToStages)),
        ],
      ),
    );
  }

  Widget _slot(
    StageSlot slot,
    int number,
    List<StageSlot> all, {
    bool featured = false,
  }) {
    final l = context.l10n;
    final status = slot.session?.status;
    final won = status == GameStatus.won;
    final lost = status == GameStatus.lost;
    final playing = status == GameStatus.playing;
    final tickets = ref.watch(ticketNotifierProvider).hasTickets;
    final color = won
        ? AppColors.success400
        : lost
        ? AppColors.ruby300
        : featured
        ? AppColors.blue300
        : AppColors.gold300;
    final title = (won || lost) ? slot.movie?.title : null;
    final label =
        title ?? '${config.isPoster ? l.itemPoster : l.itemFilm} $number';
    final action = playing
        ? l.stageContinue
        : lost
        ? l.stageRetry
        : l.stagePlay;
    final detail = won
        ? l.slotPoints(slot.session!.score)
        : lost
        ? l.slotMissedRetry
        : playing
        ? l.slotInProgress
        : l.slotNotStarted;
    return Container(
      key: ValueKey('stage-slot-${slot.movieId}'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            config.isPoster
                ? 'assets/match_cards/poster_match.png'
                : 'assets/match_cards/clue_match.png',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.obsidian950.withValues(alpha: .50),
            BlendMode.srcATop,
          ),
        ),

        color: featured
            ? AppColors.blue300.withValues(alpha: .06)
            : AppColors.obsidian800,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CineusIcon(
                won
                    ? CineusAssetId.completed
                    : lost
                    ? CineusAssetId.loss
                    : playing
                    ? CineusAssetId.inProgress
                    : config.isPoster
                    ? CineusAssetId.modePoster
                    : CineusAssetId.modeClues,
                size: 22,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: color,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!won) ...[
            const Spacer(),
            const SizedBox(height: 6),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                textStyle: AppTypography.labelLarge.copyWith(
                  fontSize: 12,
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
              key: ValueKey('stage-action-${slot.movieId}'),
              onPressed: _opening != null
                  ? null
                  : (!playing && !tickets)
                  ? () => showTicketDetails(context)
                  : () => _open(slot, all.map((s) => s.movieId).toList()),
              child: Text(
                _opening == slot.movieId
                    ? l.stageLoadingAction
                    : (!playing && !tickets)
                    ? l.noTicketsShort
                    : action,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _open(StageSlot slot, List<int> ids) async {
    if (_opening != null) return;
    setState(() => _opening = slot.movieId);
    final game = ref.read(config.gameProvider.notifier);
    final route = config.playRoute;
    final stageId = widget.stageId;
    final args = (config.mode, stageId);
    final l = context.l10n;
    HapticFeedback.lightImpact();
    try {
      // Re-read persisted status before deciding whether to charge. This also
      // handles an active game resumed elsewhere while this screen was open.
      final session = await ref
          .read(gameRepositoryProvider)
          .getStageSession(config.mode, stageId, slot.movieId);
      if (!mounted) return;
      Future<bool> load() => session?.status == GameStatus.lost
          ? game.resetStageFilm(slot.movieId, stageId, ids)
          : game.loadStageFilm(slot.movieId, stageId, ids);
      if ((session == null || session.status == GameStatus.lost) &&
          !ref.read(ticketNotifierProvider).hasTickets) {
        await showTicketDetails(context);
        return;
      }
      final ok = session != null && session.status != GameStatus.lost
          ? await load()
          : await startFilmWithTicket(ref, load);
      if (!mounted) return;
      if (ok) {
        await context.push(route);
        if (mounted) ref.invalidate(stageSlotsProvider(args));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.gameLoadFailed)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.gameLoadFailed)));
      }
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }
}
