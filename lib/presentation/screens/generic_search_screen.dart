import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/movie.dart';
import '../l10n_mappers.dart';
import '../providers/search_notifier.dart';

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
  static const _maxInputLength = 200;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitGuess(Movie movie) async {
    HapticFeedback.selectionClick();
    await widget.onSubmitGuess(movie);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.obsidian900,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Text(
                          context.l10n.whichMovie,
                          style: AppTypography.headlineMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.contextWidget != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: widget.contextWidget,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLength: _maxInputLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    textInputAction: TextInputAction.search,
                    style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: context.l10n.movieNameHint,
                      counterText: '',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: _controller.text.isNotEmpty
                            ? AppColors.gold300
                            : AppColors.textTertiary,
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .deleteButtonTooltip,
                              onPressed: () {
                                _controller.clear();
                                ref.read(searchNotifierProvider.notifier).clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: AppColors.textTertiary,
                            )
                          : null,
                    ),
                    onChanged: (query) {
                      ref.read(searchNotifierProvider.notifier).search(query);
                      setState(() {});
                    },
                  ),
                ),
                Expanded(child: _buildBody(searchState)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    if (!state.isQueryValid) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        children: [
          Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.searchTypeHint,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (widget.guesses.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildGuessHistory(),
          ],
        ],
      );
    }

    if (state.isSearching) {
      return Center(
        child: Semantics(
          liveRegion: true,
          label: context.l10n.whichMovie,
          child: const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.gold300,
            ),
          ),
        ),
      );
    }

    if (state.hasError) {
      return _SearchMessage(
        icon: Icons.wifi_off_rounded,
        message: context.l10n.searchFailed,
        action: TextButton.icon(
          onPressed: () => ref.read(searchNotifierProvider.notifier).retry(),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(context.l10n.retryAction),
        ),
      );
    }

    if (state.results.isNotEmpty) return _buildResults(state.results);

    return _SearchMessage(
      icon: Icons.movie_filter_outlined,
      message: context.l10n.searchNoResults,
    );
  }

  Widget _buildResults(List<Movie> results) {
    final titleCounts = <String, int>{};
    for (final m in results) {
      final key = m.title.toLowerCase();
      titleCounts[key] = (titleCounts[key] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.obsidian800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: results.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
        itemBuilder: (context, index) {
          final movie = results[index];
          return _AutocompleteItem(
            movie: movie,
            isAmbiguous: (titleCounts[movie.title.toLowerCase()] ?? 0) > 1,
            onTap: () => _submitGuess(movie),
          );
        },
      ),
    );
  }

  Widget _buildGuessHistory() {
    final guesses = widget.guesses;
    if (guesses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.attemptsHeader,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            Text(
              context.l10n.errorCount(guesses.length),
              style: AppTypography.monoSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...guesses.asMap().entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Text('${e.key + 1}.', style: AppTypography.monoSmall),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.value,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Text('❌', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _SearchMessage({
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _AutocompleteItem extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;
  final bool isAmbiguous;

  const _AutocompleteItem({
    required this.movie,
    required this.onTap,
    this.isAmbiguous = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.semGuessThisMovie(movie.title),
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Image.asset(
                  'assets/posters/${movie.id}.jpg',
                  width: 38,
                  height: 57,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 38,
                    height: 57,
                    color: AppColors.obsidian700,
                    alignment: Alignment.center,
                    child: const Text('🎬', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAmbiguous
                          ? '${movie.title} (${movie.year})'
                          : movie.title,
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight:
                            isAmbiguous ? FontWeight.w700 : FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (movie.originalTitle != null &&
                        movie.originalTitle != movie.title)
                      Text(
                        movie.originalTitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${movie.year}',
                style: AppTypography.monoSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}