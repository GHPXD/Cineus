import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../providers/play_notifier.dart';
import 'generic_search_screen.dart';

class VisualSearchScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const VisualSearchScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(posterGameProvider);

    return GenericSearchScreen(
      onBack: onBack,
      onSubmitGuess: (movie) async {
        await ref
            .read(posterGameProvider.notifier)
            .submitGuess(movie.title);
      },
      contextWidget: Text.rich(
        TextSpan(children: [
          TextSpan(text: context.l10n.blurLabel),
          TextSpan(
            text: gameState.blurLabel,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.gold300,
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: ' · '),
          TextSpan(
            text: '${gameState.currentScore} pts',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.scoreColor(gameState.currentScore),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: context.l10n.searchAvailableSuffix),
        ]),
        style: AppTypography.bodySmall,
      ),
      guesses: gameState.session?.guesses ?? const [],
    );
  }
}


