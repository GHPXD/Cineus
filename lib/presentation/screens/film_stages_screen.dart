import '../widgets/category_backdrop.dart';
import '../widgets/stage_navigation_indicator.dart';
import '../widgets/gold_heading.dart';
import '../widgets/stage_native_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/stage.dart';
import '../l10n_mappers.dart';
import '../providers/providers.dart';
import '../providers/stage_notifier.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/cineus_state_art.dart';
import '../widgets/poster_stage_widgets.dart';

/// Cinematic presentation of the existing clue and poster stage progression.
class FilmStagesScreen extends ConsumerStatefulWidget {
  final bool isPoster;
  const FilmStagesScreen({super.key, this.isPoster = false});
  @override
  ConsumerState<FilmStagesScreen> createState() => _FilmStagesScreenState();
}

class _FilmStagesScreenState extends ConsumerState<FilmStagesScreen> {
  bool _opening = false;
  StateNotifierProvider<StageNotifier, AsyncValue<List<Stage>>> get _provider =>
      widget.isPoster ? posterStageNotifierProvider : stageNotifierProvider;

  Widget _stageRow({
    required Stage stage,
    Stage? previous,
    required bool large,
    required VoidCallback? onOpen,
  }) => widget.isPoster
      ? PosterStageRow(
          stage: stage,
          previous: previous,
          large: large,
          onOpen: onOpen,
        )
      : _FilmStageRow(
          stage: stage,
          previous: previous,
          large: large,
          onOpen: onOpen,
        );

  Future<void> _open(Stage stage) async {
    if (_opening || stage.isLocked) return;
    setState(() => _opening = true);
    try {
      // Looking at a stage never starts a game or charges a ticket.
      await context.push(
        widget.isPoster ? '/visual/stage/${stage.id}' : '/stages/${stage.id}',
      );
    } finally {
      if (mounted) {
        setState(() => _opening = false);
        await ref.read(_provider.notifier).load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: CategoryBackdrop.surface,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: CategoryBackdrop(
              child: ref
                  .watch(_provider)
                  .when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _FilmNotice(
                      error: true,
                      onRetry: () => ref.read(_provider.notifier).load(),
                    ),
                    data: (stages) => LayoutBuilder(
                      builder: (context, constraints) {
                        final large =
                            MediaQuery.textScalerOf(context).scale(14) > 18;
                        final columns = constraints.maxWidth >= 620 && !large
                            ? 2
                            : 1;
                        return CustomScrollView(
                          key: ValueKey(
                            widget.isPoster ? 'posters-scroll' : 'films-scroll',
                          ),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                14,
                                14,
                                10,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        CineusIcon(
                                          widget.isPoster
                                              ? CineusAssetId.modePoster
                                              : CineusAssetId.modeClues,
                                          size: 40,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: GoldHeading(
                                            widget.isPoster
                                                ? l.navPosters
                                                : l.navFilms,
                                            size: 37,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      widget.isPoster
                                          ? l.stagesSubtitlePosters
                                          : l.stagesSubtitleClues,
                                      style: _body(12),
                                    ),
                                    const SizedBox(height: 12),
                                    if (stages.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          if (widget.isPoster) ...[
                                            const CineusIcon(
                                              CineusAssetId.stagesGrid,
                                              size: 32,
                                            ),
                                            const SizedBox(width: 10),
                                          ],
                                          Flexible(
                                            flex: 4,
                                            child: widget.isPoster
                                                ? Text(
                                                    l.filmsAllStages,
                                                    style: AppTypography
                                                        .displaySmall
                                                        .copyWith(
                                                          fontSize: 24,
                                                          height: 1.15,
                                                        ),
                                                  )
                                                : GoldHeading(
                                                    l.filmsAllStages,
                                                    size: 24,
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          if (!widget.isPoster)
                                            const Expanded(
                                              child: Divider(
                                                color: Color(0xFF896818),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (stages.isEmpty)
                              SliverToBoxAdapter(
                                child: _FilmNotice(
                                  error: false,
                                  onRetry: () =>
                                      ref.read(_provider.notifier).load(),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  0,
                                  14,
                                  24,
                                ),
                                sliver: SliverList.builder(
                                  itemCount: (stages.length / columns).ceil(),
                                  itemBuilder: (context, row) {
                                    final last = ((row + 1) * columns).clamp(
                                      0,
                                      stages.length,
                                    );
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              for (
                                                var column = 0;
                                                column < columns;
                                                column++
                                              ) ...[
                                                if (column > 0)
                                                  const SizedBox(width: 12),
                                                Expanded(
                                                  child:
                                                      row * columns + column <
                                                          stages.length
                                                      ? _stageRow(
                                                          stage:
                                                              stages[row *
                                                                      columns +
                                                                  column],
                                                          previous:
                                                              row * columns +
                                                                      column ==
                                                                  0
                                                              ? null
                                                              : stages[row *
                                                                        columns +
                                                                    column -
                                                                    1],
                                                          large: large,
                                                          onOpen: _opening
                                                              ? null
                                                              : () => _open(
                                                                  stages[row *
                                                                          columns +
                                                                      column],
                                                                ),
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (StageAdPolicy.after(last)) ...[
                                            const SizedBox(height: 14),
                                            StageNativeAd(
                                              key: ValueKey(
                                                'stage-native-${widget.isPoster ? 'poster' : 'clue'}-$last',
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _body(double size) => AppTypography.bodySmall.copyWith(
  fontSize: size,
  height: 1.35,
  color: const Color(0xFFB4C3E3),
);

/// One segment per film, using the repository's completed count.
class FilmStageProgress extends StatelessWidget {
  final Stage stage;
  const FilmStageProgress({super.key, required this.stage});
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.stageSemanticsProgress(
      context.l10n.stageNumber('${stage.id}'),
      stage.completedCount,
      stage.totalMovies,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            for (var i = 0; i < stage.totalMovies; i++) ...[
              if (i > 0) const SizedBox(width: 1),
              Expanded(
                child: ColoredBox(
                  color: i < stage.completedCount
                      ? AppColors.gold300
                      : const Color(0xFF343B4B),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _FilmStageRow extends StatelessWidget {
  final Stage stage;
  final Stage? previous;
  final bool large;
  final VoidCallback? onOpen;
  const _FilmStageRow({
    required this.stage,
    required this.previous,
    required this.large,
    required this.onOpen,
  });
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = l.stageNumber('${stage.id}');
    final description = stage.isLocked
        ? l.filmsUnlockAfter(l.stageNumber('${previous?.id ?? stage.id}'))
        : l.stageProgressLine(
            stage.completedCount,
            stage.totalMovies,
            l.filmsDone,
          );
    final color = stage.isLocked ? const Color(0xFFAFBBD4) : AppColors.gold300;
    final art = [
      'projector',
      'clapper',
      'popcorn',
      'director',
    ][(stage.orderIndex - 1).clamp(0, 999999) % 4];
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: AppTypography.displaySmall.copyWith(
            fontSize: 20,
            height: 1.15,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(description, style: _body(11)),
        if (!stage.isLocked) ...[
          const SizedBox(height: 6),
          FilmStageProgress(stage: stage),
        ],
      ],
    );
    return Semantics(
      label:
          '$name. $description${stage.isCompleted ? '. ${l.stageCompleteLabel}' : ''}',
      button: !stage.isLocked,
      enabled: !stage.isLocked && onOpen != null,
      onTap: stage.isLocked ? null : onOpen,
      excludeSemantics: true,
      child: Material(
        color: const Color(0xFF050D18),
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('stage-${stage.id}'),
          onTap: stage.isLocked ? null : onOpen,
          child: Container(
            constraints: const BoxConstraints(minHeight: 70),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: stage.isLocked
                    ? const Color(0xFF25354A)
                    : AppColors.gold300,
                width: stage.isLocked ? 1 : 1.1,
              ),
            ),
            child: Stack(
              children: [
                if (stage.isLocked)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: large ? 200 : 175,
                    child: _FilmArt(art),
                  ),
                if (stage.isLocked)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF050D18),
                            Color(0xD5050D18),
                            Color(0x65050D18),
                          ],
                          stops: [0, .4, 1],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      if (!large) ...[
                        if (stage.isLocked)
                          Container(
                            width: 42,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF141C2B),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(child: _FilmLock(size: 23)),
                          )
                        else
                          SizedBox(
                            width: 80,
                            height: 52,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: _FilmArt(art),
                            ),
                          ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(child: copy),
                      const SizedBox(width: 10),
                      StageNavigationIndicator(
                        locked: stage.isLocked,
                        completed: stage.isCompleted,
                      ),
                    ],
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

class _FilmArt extends StatelessWidget {
  final String name;
  const _FilmArt(this.name);
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      'assets/films/$name.png',
      fit: BoxFit.cover,
      cacheWidth: name == 'projector' || name == 'showcase' ? 1000 : 500,
    ),
  );
}

class _FilmLock extends StatelessWidget {
  final double size;
  const _FilmLock({required this.size});
  @override
  Widget build(BuildContext context) => ColorFiltered(
    colorFilter: const ColorFilter.mode(Color(0xFFAFBBD4), BlendMode.srcIn),
    child: CineusIcon(CineusAssetId.lock, size: size),
  );
}

class _FilmNotice extends StatelessWidget {
  final bool error;
  final VoidCallback onRetry;
  const _FilmNotice({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        CineusStateArt(error ? CineusStateKind.error : CineusStateKind.empty),
        const SizedBox(height: 16),
        Text(
          error ? context.l10n.gameLoadFailed : context.l10n.filmsEmpty,
          style: AppTypography.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(context.l10n.retryAction),
        ),
      ],
    ),
  );
}
