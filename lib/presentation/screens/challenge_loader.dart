import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../l10n_mappers.dart';
import '../providers/play_notifier.dart';

/// Entry point for a challenge a friend sent (D10).
class ChallengeLoader extends ConsumerStatefulWidget {
  final int? movieId;

  const ChallengeLoader({super.key, required this.movieId});

  @override
  ConsumerState<ChallengeLoader> createState() => _ChallengeLoaderState();
}

class _ChallengeLoaderState extends ConsumerState<ChallengeLoader> {
  @override
  void initState() {
    super.initState();
    final id = widget.movieId;
    if (id == null) return;

    Future.microtask(() async {
      await ref.read(clueGameProvider.notifier).loadChallenge(id);
      if (!mounted) return;
      if (ref.read(clueGameProvider).error != null) return;
      context.go('/game?source=challenge');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clueGameProvider);
    final failed = widget.movieId == null || state.error != null;

    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Center(
          child: failed
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎬', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.challengeFilmNotFound,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () => context.go('/home'),
                        child: Text(context.l10n.backHome),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(color: AppColors.gold300),
        ),
      ),
    );
  }
}