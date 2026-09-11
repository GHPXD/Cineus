import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/play_notifier.dart';
import 'generic_search_screen.dart';

class SearchScreen extends ConsumerWidget {
  final VoidCallback onBack;

  const SearchScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(clueGameProvider);
    final session = gameState.session;

    final prefix = session == null
        ? null
        : switch (session.kind) {
            SessionKind.daily =>
              context.l10n.searchChallenge('${gameState.challengeNumber}'),
            SessionKind.stage => context.l10n.searchStage(session.stageId),
            SessionKind.challenge => context.l10n.searchFriendChallenge,
          };

    return GenericSearchScreen(
      onBack: onBack,
      onSubmitGuess: (movie) async {
        await ref.read(clueGameProvider.notifier).submitGuess(movie.title);
      },
      contextWidget: session != null
          ? Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: prefix,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: context.l10n.searchPoints(session.potentialScore),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.scoreColor(session.potentialScore),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: context.l10n.searchAvailableSuffix,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ]),
            )
          : null,
      guesses: session?.guesses ?? const [],
    );
  }
}