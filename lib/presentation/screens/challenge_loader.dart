import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/play_notifier.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cineus_icon.dart';

class ChallengeLoader extends ConsumerStatefulWidget {
  final int? movieId;
  final GameMode mode;
  const ChallengeLoader({
    super.key,
    required this.movieId,
    this.mode = GameMode.clue,
  });
  @override
  ConsumerState<ChallengeLoader> createState() => _ChallengeLoaderState();
}

class _ChallengeLoaderState extends ConsumerState<ChallengeLoader> {
  bool _loading = false;
  PlayLoadError? _error;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (_loading || widget.movieId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final provider = widget.mode == GameMode.clue
        ? clueGameProvider
        : posterGameProvider;
    final loaded = await ref
        .read(provider.notifier)
        .loadChallenge(widget.movieId!);
    if (!mounted) return;
    if (!loaded) {
      setState(() {
        _loading = false;
        _error = ref.read(provider).error ?? PlayLoadError.loadFailed;
      });
      return;
    }
    final state = ref.read(provider);
    if (state.isFinished) {
      context.go(
        '${widget.mode == GameMode.poster ? '/visual' : ''}/${state.session!.status == GameStatus.won ? 'victory' : 'defeat'}',
      );
    } else {
      context.go(
        widget.mode == GameMode.poster
            ? '/visual/play?source=challenge'
            : '/game?source=challenge',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final invalid = widget.movieId == null;
    final failed = invalid || _error != null;
    final message = invalid
        ? context.l10n.challengeInvalid
        : _error == PlayLoadError.movieNotFound
        ? context.l10n.challengeFilmNotFound
        : context.l10n.challengeLoadFailed;
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CineusIcon(
                    failed ? CineusAssetId.error : CineusAssetId.friendInvite,
                    size: 64,
                    color: failed ? AppColors.ruby300 : AppColors.gold300,
                  ),
                  const SizedBox(height: 20),
                  if (failed) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!invalid && _error == PlayLoadError.loadFailed)
                      ElevatedButton(
                        onPressed: _load,
                        child: Text(context.l10n.retryAction),
                      ),
                    OutlinedButton(
                      onPressed: () => context.go('/challenge-entry'),
                      child: Text(context.l10n.editChallenge),
                    ),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: Text(context.l10n.backHome),
                    ),
                  ] else ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        context.l10n.loadingGame,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                    TextButton(
                      onPressed: () => context.go('/challenge-entry'),
                      child: Text(context.l10n.back),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
