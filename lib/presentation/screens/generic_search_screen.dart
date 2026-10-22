import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/movie.dart';
import '../l10n_mappers.dart';
import '../providers/search_notifier.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/cineus_state_art.dart';
import '../widgets/cineus_poster.dart';
import '../widgets/gameplay_widgets.dart';

class GenericSearchScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final Future<void> Function(Movie movie) onSubmitGuess;
  final Widget? contextWidget;
  final List<String> guesses;
  const GenericSearchScreen({
    super.key,
    required this.onBack,
    required this.onSubmitGuess,
    this.contextWidget,
    this.guesses = const [],
  });
  @override
  ConsumerState<GenericSearchScreen> createState() =>
      _GenericSearchScreenState();
}

class _GenericSearchScreenState extends ConsumerState<GenericSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Movie? _selected;
  bool _submitting = false;
  String? _saveError;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _select(Movie movie) {
    if (_submitting) return;
    _focusNode.unfocus();
    setState(() {
      _selected = movie;
      _saveError = null;
    });
  }

  Future<void> _confirm() async {
    final movie = _selected;
    if (movie == null || _submitting) return;
    setState(() {
      _submitting = true;
      _saveError = null;
    });
    try {
      HapticFeedback.selectionClick();
      await widget.onSubmitGuess(movie);
      if (mounted) widget.onBack();
    } catch (_) {
      if (mounted) setState(() => _saveError = context.l10n.guessSaveFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _query(String query) {
    ref.read(searchNotifierProvider.notifier).search(query);
    setState(() {
      _selected = null;
      _saveError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);
    final l = context.l10n;
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        backgroundColor: AppColors.obsidian950,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: LayoutBuilder(
                builder: (context, constraints) => Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('movie-search-scroll'),
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  tooltip: l.semBack,
                                  onPressed: _submitting ? null : widget.onBack,
                                  icon: const CineusIcon(CineusAssetId.back),
                                ),
                                Expanded(
                                  child: Text(
                                    l.whichMovie,
                                    style: AppTypography.headlineMedium,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.contextWidget != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: widget.contextWidget,
                              ),
                            TextField(
                              key: const ValueKey('movie-search-input'),
                              controller: _controller,
                              focusNode: _focusNode,
                              enabled: !_submitting,
                              maxLength: 200,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                              textInputAction: TextInputAction.search,
                              style: AppTypography.bodyLarge,
                              decoration: InputDecoration(
                                labelText: l.movieNameHint,
                                counterText: '',
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CineusIcon(CineusAssetId.search),
                                ),
                                suffixIcon: _controller.text.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: MaterialLocalizations.of(
                                          context,
                                        ).deleteButtonTooltip,
                                        onPressed: _submitting
                                            ? null
                                            : () {
                                                _controller.clear();
                                                _query('');
                                              },
                                        icon: const CineusIcon(
                                          CineusAssetId.close,
                                        ),
                                      ),
                              ),
                              onChanged: _query,
                            ),

                            const SizedBox(height: 16),
                            _results(state),
                            if (widget.guesses.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Text(
                                l.attemptsHeader,
                                style: AppTypography.labelSmall,
                              ),
                              const SizedBox(height: 8),
                              for (final guess in widget.guesses)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: GameNotice(
                                    message: guess,
                                    asset: CineusAssetId.loss,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_selected != null)
                      _confirmation(constraints.maxHeight * .48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _results(SearchState state) {
    final l = context.l10n;
    if (!state.isQueryValid) {
      return Text(l.searchTypeHint, style: AppTypography.bodySmall);
    }
    if (state.isSearching) {
      return Semantics(
        liveRegion: true,
        label: l.loadingGame,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (state.hasError) {
      return Column(
        children: [
          const CineusStateArt(CineusStateKind.error),
          GameNotice(message: l.searchFailed, asset: CineusAssetId.error),
          TextButton(
            onPressed: _submitting
                ? null
                : () => ref.read(searchNotifierProvider.notifier).retry(),
            child: Text(l.retryAction),
          ),
        ],
      );
    }
    if (state.results.isEmpty) {
      return Column(
        children: [
          const CineusStateArt(
            CineusStateKind.empty,
            symbol: CineusAssetId.search,
          ),
          GameNotice(
            message: '${l.searchNoResults}\n${l.searchEmptyHelp}',
            asset: CineusAssetId.search,
            color: AppColors.textSecondary,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            l.searchResultCount(state.results.length),
            style: AppTypography.labelSmall,
          ),
        ),
        const SizedBox(height: 10),
        for (final movie in state.results)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MovieOption(
              movie: movie,
              selected: _selected?.id == movie.id,
              onTap: _submitting ? null : () => _select(movie),
            ),
          ),
      ],
    );
  }

  Widget _confirmation(double maxHeight) {
    final l = context.l10n;
    final movie = _selected!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.obsidian800,
        border: Border(top: BorderSide(color: AppColors.gold700)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (maxHeight - 96).clamp(40.0, 280.0),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l.selectedMovieLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.gold300,
                      ),
                    ),
                  ),
                  Text(
                    '${movie.title} (${movie.year})',
                    key: const ValueKey('selected-movie'),
                    style: AppTypography.titleMedium,
                  ),
                  if (_saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GameNotice(
                        message: _saveError!,
                        asset: CineusAssetId.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            key: const ValueKey('confirm-guess'),
            onPressed: _submitting ? null : _confirm,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
            child: _submitting
                ? Semantics(
                    liveRegion: true,
                    label: l.savingGuess,
                    child: const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Text(l.confirmGuess),
          ),
        ],
      ),
    );
  }
}

class _MovieOption extends StatelessWidget {
  final Movie movie;
  final bool selected;
  final VoidCallback? onTap;
  const _MovieOption({
    required this.movie,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.selectMovieSemantics(movie.title, movie.year),
    button: true,
    selected: selected,
    enabled: onTap != null,
    onTap: onTap,
    excludeSemantics: true,
    child: Material(
      color: selected ? AppColors.blue900 : AppColors.obsidian800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.blue300 : AppColors.obsidian700,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('movie-option-${movie.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CineusPoster(movieId: movie.id, width: 38, height: 57),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(movie.title, style: AppTypography.bodyLarge),
                    Text('${movie.year}', style: AppTypography.monoSmall),
                    if (movie.originalTitle != null &&
                        movie.originalTitle != movie.title)
                      Text(
                        movie.originalTitle!,
                        style: AppTypography.bodySmall,
                      ),
                  ],
                ),
              ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: CineusIcon(
                    CineusAssetId.win,
                    color: AppColors.blue300,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
