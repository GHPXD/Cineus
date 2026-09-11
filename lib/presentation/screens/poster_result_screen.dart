import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../providers/game_actions.dart';
import '../providers/play_notifier.dart';
import '../providers/providers.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/film_strip_widget.dart';
import '../widgets/poster_card_widget.dart';

class PosterResultScreen extends ConsumerWidget {
  final bool won;

  const PosterResultScreen({super.key, required this.won});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(posterGameProvider);
    final movie = state.movie;
    final session = state.session;

    if (movie == null || session == null) {
      return Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/home'),
            child: Text(context.l10n.backHome),
          ),
        ),
      );
    }

    final accent = won ? AppColors.success400 : AppColors.ruby300;
    final nextMovieId = _nextMovieInStage(state);
    final hasTickets = ref.watch(ticketNotifierProvider).hasTickets;

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                const FilmStrip(),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: accent.withValues(alpha: 0.32)),
                    ),
                    child: Text(
                      won ? context.l10n.resultWin : context.l10n.resultLose,
                      style: AppTypography.labelLarge.copyWith(
                        color: accent,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (won) ...[
                  Center(
                    child: Text(
                      '${session.score}',
                      style: AppTypography.scoreLarge.copyWith(
                        color: AppColors.gold300,
                        fontSize: 72,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      context.l10n.scorePoints,
                      style: AppTypography.overline.copyWith(
                        color: AppColors.gold300,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      context.l10n.gotItAtLevel(state.step),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ] else ...[
                  Center(
                    child: Text(
                      context.l10n.theMovieWas,
                      style: AppTypography.overline.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 250,
                    child: PosterCard(movie: movie),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  movie.title,
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineMedium,
                ),
                if (movie.originalTitle != null &&
                    movie.originalTitle != movie.title) ...[
                  const SizedBox(height: 4),
                  Text(
                    movie.originalTitle!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (session.isDaily) ...[
                  const CountdownTimer(),
                  const SizedBox(height: 20),
                ],
                if (nextMovieId != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: hasTickets
                          ? () async {
                              final started = await startFilmWithTicket(
                                ref,
                                () => ref
                                    .read(posterGameProvider.notifier)
                                    .loadStageFilm(
                                      nextMovieId,
                                      state.stageId!,
                                      state.stageMovieIds,
                                    ),
                              );
                              if (!started || !context.mounted) return;
                              context.go('/visual/play?source=stage');
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(
                        hasTickets
                            ? context.l10n.nextWithTicket
                            : context.l10n.noTicketsForNext,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (session.isStage)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.go('/visual/stage/${session.stageId}'),
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: Text(context.l10n.backToStages),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/stats'),
                          icon: const Icon(Icons.bar_chart_rounded, size: 18),
                          label: Text(context.l10n.statsTitle),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/home'),
                          icon: const Icon(Icons.home_rounded, size: 18),
                          label: Text(context.l10n.navHome),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int? _nextMovieInStage(PlayState state) {
    if (!state.isStage || state.movie == null || state.stageMovieIds.isEmpty) {
      return null;
    }
    final index = state.stageMovieIds.indexOf(state.movie!.id);
    if (index < 0 || index >= state.stageMovieIds.length - 1) return null;
    return state.stageMovieIds[index + 1];
  }
}
