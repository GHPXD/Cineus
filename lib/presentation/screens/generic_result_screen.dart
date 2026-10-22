import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/challenge_code.dart';
import '../../core/utils/string_normalizer.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/movie.dart';
import '../l10n_mappers.dart';
import '../providers/game_actions.dart';
import '../providers/play_notifier.dart';
import '../providers/providers.dart';
import '../providers/cinema_showcase_provider.dart';
import '../providers/result_share_service.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/cineus_poster.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/gameplay_widgets.dart';
import '../widgets/result_share_card.dart';
import '../widgets/reward_toast.dart';
import '../widgets/share_grid_widget.dart';
import '../widgets/personalized_share_panel.dart';
import '../widgets/result_break.dart';
import '../widgets/ticket_details_sheet.dart';
import '../widgets/editorial_feedback.dart';

class ResultConfig {
  final bool won;
  const ResultConfig({required this.won});
  static const victory = ResultConfig(won: true);
  static const defeat = ResultConfig(won: false);
}

class GenericResultScreen extends ConsumerStatefulWidget {
  final ResultConfig config;
  final GameMode mode;
  final VoidCallback onNavigateToStats, onNavigateHome;
  const GenericResultScreen({
    super.key,
    required this.config,
    required this.onNavigateToStats,
    required this.onNavigateHome,
    this.mode = GameMode.clue,
  });
  @override
  ConsumerState<GenericResultScreen> createState() =>
      _GenericResultScreenState();
}

class _GenericResultScreenState extends ConsumerState<GenericResultScreen> {
  bool _busy = false;
  bool _modalOpen = false;
  String? _error;
  StateNotifierProvider<PlayNotifier, PlayState> get _provider =>
      widget.mode == GameMode.clue ? clueGameProvider : posterGameProvider;
  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Rect _origin(BuildContext anchor) {
    final box = anchor.findRenderObject() as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _copy(String text) async {
    if (!mounted || _busy) return;
    setState(() => _busy = true);
    final service = ref.read(resultShareServiceProvider);
    try {
      await service.copy(text);
      if (mounted) _message(context.l10n.resultCopied);
    } catch (_) {
      if (mounted) _message(context.l10n.copyFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(String text, BuildContext anchor) async {
    if (!mounted || _busy) return;
    final service = ref.read(resultShareServiceProvider);
    final origin = _origin(anchor);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final status = await service.share(text, origin);
      if (!mounted) return;
      if (status == ShareResultStatus.success) {
        _message(context.l10n.resultShared);
      }
      if (status == ShareResultStatus.unavailable) {
        setState(() => _error = context.l10n.shareFailed);
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.shareFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview(ResultShareData data) async {
    if (!mounted || _busy || _modalOpen) return;
    _modalOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => PersonalizedSharePanel(
          text: data.text(context.l10n),
          movieId: data.movieId,
          neutralData: data,
          cardBuilder: (look) => ResultShareCard(data: data, look: look),
        ),
      );
    } finally {
      if (mounted) setState(() => _modalOpen = false);
    }
  }

  Future<void> _invite(PlayState state) async {
    if (!mounted || _busy || _modalOpen) return;
    _modalOpen = true;
    final l = context.l10n;
    final code = ChallengeCode.encode(state.movie!.id, mode: widget.mode);
    final link = ChallengeCode.linkFor(
      state.movie!.id,
      mode: widget.mode,
    ).toString();
    final text =
        '${l.challengeShareText(code, link)}\n${widget.mode == GameMode.clue ? l.modeClues : l.modePoster}';
    try {
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheet).height * .9,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: CineusIcon(CineusAssetId.friendInvite, size: 64),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.challengeSectionTitle,
                    style: AppTypography.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(l.challengeInviteHelp, style: AppTypography.bodyMedium),
                  Text(
                    widget.mode == GameMode.clue ? l.modeClues : l.modePoster,
                    style: AppTypography.labelLarge,
                  ),
                  const SizedBox(height: 16),
                  SelectableText(
                    code,
                    key: const ValueKey('invite-code'),
                    style: AppTypography.headlineMedium,
                  ),
                  SelectableText(link, style: AppTypography.bodySmall),
                  if (state.isDaily)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        l.dailyInviteWarning,
                        style: AppTypography.bodySmall,
                      ),
                    ),
                  StatefulBuilder(
                    builder: (anchor, update) => Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _busy
                              ? null
                              : () async {
                                  final pending = _share(text, anchor);
                                  update(() {});
                                  await pending;
                                  if (anchor.mounted) update(() {});
                                },
                          icon: const CineusIcon(CineusAssetId.share),
                          label: Text(l.share),
                        ),
                        if (_error != null)
                          GameNotice(
                            message: _error!,
                            asset: CineusAssetId.error,
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _copy(text),
                    icon: const CineusIcon(CineusAssetId.copy),
                    label: Text(l.shareChallengeCopy),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(sheet),
                    child: Text(l.back),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _modalOpen = false);
    }
  }

  Future<void> _next(PlayState state, int id) async {
    if (!mounted || _busy) return;
    final notifier = ref.read(_provider.notifier);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await maybeShowResultBreak(
        ref,
        'film:${state.session?.id}',
        isCurrent: () => mounted && ModalRoute.of(context)?.isCurrent == true,
      );
      if (!mounted) return;
      final started = await startFilmWithTicket(
        ref,
        () => notifier.loadStageFilm(id, state.stageId!, state.stageMovieIds),
      );
      if (!mounted) return;
      if (started) {
        context.go(
          widget.mode == GameMode.clue
              ? '/game?source=stage'
              : '/visual/play?source=stage',
        );
      } else {
        setState(() => _error = context.l10n.gameLoadFailed);
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.gameActionFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _nextShowcase(GameSession session) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final showcases = await ref.read(cinemaShowcasesProvider.future);
      final showcase = showcases
          .where((s) => s.sessionKey == session.date)
          .firstOrNull;
      if (showcase == null) throw StateError('Showcase unavailable');
      final index = showcase.movies.indexOf(session.movieId);
      if (index < 0) throw StateError('Movie outside showcase');
      if (!mounted) return;
      if (index == showcase.movies.length - 1) {
        context.go('/showcase/${showcase.id}');
        return;
      }
      final game = ref.read(_provider.notifier);
      final next = await ref
          .read(cinemaShowcaseRepositoryProvider)
          .open(showcase, widget.mode, showcase.movies[index + 1]);
      if (!await game.resume(next)) throw StateError('Movie unavailable');
      if (mounted) {
        final prefix = widget.mode == GameMode.clue ? '' : '/visual';
        final route = next.isFinished
            ? '$prefix/${next.status == GameStatus.won ? 'victory' : 'defeat'}'
            : widget.mode == GameMode.clue
            ? '/game'
            : '/visual/play';
        context.go('$route?source=training');
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.gameLoadFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _otherMode() async {
    if (!mounted || _busy) return;
    final provider = widget.mode == GameMode.clue
        ? posterGameProvider
        : clueGameProvider;
    setState(() => _busy = true);
    final loaded = await ref.read(provider.notifier).loadDaily();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!loaded) {
      setState(() => _error = context.l10n.gameLoadFailed);
      return;
    }
    final state = ref.read(provider);
    final prefix = widget.mode == GameMode.clue ? '/visual' : '';
    context.go(
      state.isFinished
          ? '$prefix/${state.session!.status == GameStatus.won ? 'victory' : 'defeat'}'
          : widget.mode == GameMode.clue
          ? '/visual/play?source=daily'
          : '/game?source=daily',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);
    final session = state.session;
    final movie = state.movie;
    final l = context.l10n;
    if (session == null ||
        movie == null ||
        !session.isFinished ||
        session.mode != widget.mode ||
        movie.id != session.movieId) {
      return Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CineusIcon(
                    CineusAssetId.error,
                    size: 64,
                    color: AppColors.ruby300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.resultUnavailable,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  if (session != null && movie != null && !session.isFinished)
                    ElevatedButton(
                      onPressed: () => context.go(
                        '${widget.mode == GameMode.clue ? '/game' : '/visual/play'}?source=${session.kind.name}',
                      ),
                      child: Text(l.returnToGame),
                    ),
                  OutlinedButton(
                    onPressed: widget.onNavigateHome,
                    child: Text(l.backHome),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final won = session.status == GameStatus.won;
    final showcase =
        session.kind == SessionKind.training &&
        session.date.startsWith('showcase:');
    final data = ResultShareData.fromSession(session, state.challengeNumber);
    final color = won ? AppColors.success400 : AppColors.ruby300;
    final index = state.stageMovieIds.indexOf(movie.id);
    final next =
        state.isStage && index >= 0 && index < state.stageMovieIds.length - 1
        ? state.stageMovieIds[index + 1]
        : null;
    final balance = ref.watch(ticketBalanceStatusProvider);
    final hasTickets =
        ref.watch(ticketNotifierProvider).hasTickets &&
        !balance.isLoading &&
        !balance.hasError;
    return RewardToast(
      child: ResultBreak(
        gameKey: session.isStage ? 'film:${session.id}' : null,
        child: Scaffold(
          backgroundColor: AppColors.obsidian950,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: l.backHome,
                          onPressed: widget.onNavigateHome,
                          icon: const CineusIcon(CineusAssetId.home),
                        ),
                        Expanded(
                          child: Text(
                            '${data.modeLabel(context.l10n)} · ${data.contextLabel(context.l10n)}',
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    Center(
                      child: CineusIcon(
                        won
                            ? CineusAssetId.resultVictory
                            : CineusAssetId.resultDefeat,
                        size: 72,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      won ? l.resultVictoryLabel : l.resultDefeatLabel,
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.resultScore(session.score),
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge,
                    ),
                    Text(
                      l.resultProgress(
                        session.revealedClues,
                        state.rules.totalSteps,
                      ),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    MovieAnswerBlock(movie: movie),
                    const SizedBox(height: 20),
                    ShareGrid(
                      revealedClues: data.steps,
                      won: won,
                      totalSteps: data.total,
                      score: data.score,
                    ),
                    const SizedBox(height: 12),
                    if (session.isStage && next != null) ...[
                      Tooltip(
                        message: hasTickets ? '' : l.noTicketsForNext,
                        child: ElevatedButton.icon(
                          key: const ValueKey('next-stage-film'),
                          onPressed: _busy || balance.isLoading
                              ? null
                              : !hasTickets
                              ? () => showTicketDetails(context)
                              : () => _next(state, next),
                          icon: const CineusIcon(CineusAssetId.chevron),
                          label: Text(l.resultNext),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (session.isDaily) ...[
                      ElevatedButton.icon(
                        key: const ValueKey('next-daily-mode'),
                        onPressed: _busy ? null : _otherMode,
                        icon: const CineusIcon(CineusAssetId.chevron),
                        label: Text(l.resultNext),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (showcase) ...[
                      ElevatedButton.icon(
                        key: const ValueKey('next-showcase-film'),
                        onPressed: _busy ? null : () => _nextShowcase(session),
                        icon: const CineusIcon(CineusAssetId.chevron),
                        label: Text(l.resultNext),
                      ),
                      const SizedBox(height: 8),
                    ],
                    OutlinedButton.icon(
                      key: const ValueKey('preview-result-card'),
                      onPressed: _busy ? null : () => _preview(data),
                      icon: const CineusIcon(CineusAssetId.modePoster),
                      label: Text(l.sharePreviewAction),
                    ),
                    if (!showcase &&
                        (!widget.config.won ||
                            session.kind == SessionKind.training ||
                            session.kind == SessionKind.archive))
                      TextButton(
                        key: const ValueKey('practice-result'),
                        onPressed: _busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                final loaded = await ref
                                    .read(_provider.notifier)
                                    .loadPractice(movie.id);
                                if (!context.mounted) return;
                                if (loaded) {
                                  context.go(
                                    '${widget.mode == GameMode.clue ? '/game' : '/visual/play'}?source=training',
                                  );
                                } else {
                                  setState(() => _busy = false);
                                }
                              },
                        child: Text(l.practiceAgain),
                      ),
                    if (_busy) const LinearProgressIndicator(),
                    if (_error != null && !_modalOpen)
                      GameNotice(message: _error!, asset: CineusAssetId.error),
                    if (session.isDaily) ...[
                      const SizedBox(height: 12),
                      const CountdownTimer(),
                    ],
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const ValueKey('invite-friend'),
                      onPressed: _busy ? null : () => _invite(state),
                      icon: const CineusIcon(CineusAssetId.friendInvite),
                      label: Text(l.challengeShareButton),
                    ),
                    TextButton(
                      onPressed: widget.onNavigateHome,
                      child: Text(l.backHome),
                    ),
                    EditorialFeedbackButton(
                      mode: widget.mode.name,
                      movieId: movie.id,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MovieAnswerBlock extends StatelessWidget {
  final Movie movie;
  const MovieAnswerBlock({super.key, required this.movie});
  @override
  Widget build(BuildContext context) {
    final original = movie.originalTitle;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          key: const ValueKey('answer-title'),
          style: AppTypography.headlineMedium,
        ),
        if (original != null &&
            StringNormalizer.normalize(original) !=
                StringNormalizer.normalize(movie.title))
          Text(original, style: AppTypography.bodySmall),
        const SizedBox(height: 8),
        Text(
          '${movie.year} · ${movie.genres.join(', ')}',
          style: AppTypography.bodySmall,
        ),
        if (movie.director.isNotEmpty)
          Text(movie.director, style: AppTypography.bodySmall),
      ],
    );
    final poster = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CineusPoster(movieId: movie.id, width: 120, height: 180),
    );
    return LayoutBuilder(
      builder: (context, c) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.obsidian800,
          borderRadius: BorderRadius.circular(20),
        ),
        child:
            c.maxWidth < 360 || MediaQuery.textScalerOf(context).scale(16) > 22
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: poster),
                  const SizedBox(height: 16),
                  details,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  poster,
                  const SizedBox(width: 16),
                  Expanded(child: details),
                ],
              ),
      ),
    );
  }
}
