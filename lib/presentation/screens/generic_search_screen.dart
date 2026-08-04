import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/movie.dart';
import '../l10n_mappers.dart';
import '../providers/search_notifier.dart';

/// Generic search screen used by both clue and poster game modes.
/// The [onSubmitGuess] callback handles game-mode-specific submission.
/// The [contextWidget] provides context info (challenge # or blur level).
/// The [guesses] list shows wrong guesses if provided.
///
/// Note: there is deliberately no "max guesses" counter. Neither mode caps the
/// number of guesses — a wrong guess burns the next clue/reveal level, and the
/// game is lost by running out of those. A previous `x / 5 máx.` label showed a
/// limit that nothing enforced.
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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

            // Context info (score / blur level)
            if (widget.contextWidget != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: widget.contextWidget,
              ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLength: _maxInputLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: context.l10n.movieNameHint,
                  counterText: '',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _controller.text.isNotEmpty
                        ? AppColors.gold300
                        : AppColors.obsidian400,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _controller.clear();
                            ref.read(searchNotifierProvider.notifier).clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: AppColors.textTertiary,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.gold300.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.gold300.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (query) {
                  ref.read(searchNotifierProvider.notifier).search(query);
                  setState(() {});
                },
              ),
            ),

            // Results or guess history
            Expanded(
              child: searchState.results.isNotEmpty
                  ? _buildResults(searchState.results)
                  : _buildGuessHistory(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(List<Movie> results) {
    // The catalogue holds 5 pairs of films sharing a title (remake + original:
    // O Rei Leão, A Bela e a Fera, Aladdin, Batman, Os Suspeitos). When both
    // land in the same result list, the year moves next to the title so the two
    // rows are not visually identical.
    final titleCounts = <String, int>{};
    for (final m in results) {
      final key = m.title.toLowerCase();
      titleCounts[key] = (titleCounts[key] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      decoration: BoxDecoration(
        color: AppColors.obsidian800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
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
                  color: AppColors.obsidian600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...guesses.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
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
      ),
    );
  }
}

class _AutocompleteItem extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  /// True when another result in the same list carries the identical title, so
  /// the year has to be shown inline to tell them apart.
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
      // Declared here too: `excludeSemantics` drops the InkWell's tap action.
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: const Text('🎬', style: TextStyle(fontSize: 16)),
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
                        fontWeight: isAmbiguous
                            ? FontWeight.w700
                            : FontWeight.w400,
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
