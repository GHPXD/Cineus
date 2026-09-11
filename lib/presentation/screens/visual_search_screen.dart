import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/play_notifier.dart';
import 'generic_search_screen.dart';

class VisualSearchScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const VisualSearchScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(posterGameProvider);
    final session = gameState.session;
    final prefix = session == null
        ? ''
        : switch (session.kind) {
            SessionKind.daily =>
              context.l10n.searchChallenge('${gameState.challengeNumber}'),
            SessionKind.stage => context.l10n.searchStage(session.stageId),
            SessionKind.challenge => context.l10n.searchFriendChallenge,
          };

    return GenericSearchScreen(
      onBack: onBack,
      onSubmitGuess: (movie) async {
        await ref.read(posterGameProvider.notifier).submitGuess(movie.title);
      },
      contextWidget: Text.rich(
        TextSpan(children: [
          if (prefix.isNotEmpty)
            TextSpan(
              text: prefix,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
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
            text: context.l10n.searchPoints(gameState.currentScore),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.scoreColor(gameState.currentScore),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: context.l10n.searchAvailableSuffix),
        ]),
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      guesses: gameState.session?.guesses ?? const [],
    );
  }
}