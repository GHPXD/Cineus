import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/cinema_showcase.dart';
import '../../domain/entities/game_session.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_l10n.dart';
import '../providers/cinema_showcase_provider.dart';
import '../providers/play_notifier.dart';
import '../widgets/cinematic_app_bar.dart';
import '../widgets/cineus_icon.dart';
import '../visuals/cineus_assets.dart';

String showcaseName(AppL10n l, String id) => switch (id) {
  'animation' => l.showcaseAnimation,
  'fantasy' => l.showcaseFantasy,
  _ => l.showcaseClassics,
};

class CinemaShowcaseScreen extends ConsumerStatefulWidget {
  final String id;
  const CinemaShowcaseScreen({super.key, required this.id});
  @override
  ConsumerState<CinemaShowcaseScreen> createState() => _ShowcaseState();
}

class _ShowcaseState extends ConsumerState<CinemaShowcaseScreen> {
  GameMode _mode = GameMode.clue;
  bool _busy = false, _failed = false;
  Future<List<GameSession>>? _records;
  void _reload(CinemaShowcase showcase) {
    _records = ref
        .read(cinemaShowcaseRepositoryProvider)
        .sessions(showcase, _mode);
  }

  Future<void> _open(CinemaShowcase showcase, int movie) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final mode = _mode;
      final game = ref.read(
        (mode == GameMode.clue ? clueGameProvider : posterGameProvider)
            .notifier,
      );
      final record = await ref
          .read(cinemaShowcaseRepositoryProvider)
          .open(showcase, mode, movie);
      if (!await game.resume(record)) throw StateError('Unavailable film');
      if (!mounted) return;
      final prefix = mode == GameMode.clue ? '' : '/visual';
      final route = record.status == GameStatus.playing
          ? (mode == GameMode.clue ? '/game' : '/visual/play')
          : '$prefix/${record.status == GameStatus.won ? 'victory' : 'defeat'}';
      await context.push('$route?source=training');
      if (mounted) setState(() => _reload(showcase));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Scaffold(
      appBar: CinematicAppBar(
        title: l.seasonTitle,
        asset: CineusAssetId.modeClues,
        textScaler: MediaQuery.textScalerOf(context),
        onBack: () => context.canPop() ? context.pop() : context.go('/seasons'),
      ),
      body: SafeArea(
        child: ref
            .watch(cinemaShowcasesProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(child: Text(l.gameLoadFailed)),
              data: (all) {
                final showcase = all
                    .where((s) => s.id == widget.id)
                    .firstOrNull;
                if (showcase == null) {
                  return Center(child: Text(l.gameLoadFailed));
                }
                _records ??= ref
                    .read(cinemaShowcaseRepositoryProvider)
                    .sessions(showcase, _mode);
                return FutureBuilder<List<GameSession>>(
                  future: _records,
                  builder: (context, snapshot) {
                    final records = snapshot.data ?? [];
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Text(
                          showcaseName(l, showcase.id),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(l.showcasePractice),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          children: [
                            for (final mode in GameMode.values)
                              ChoiceChip(
                                label: Text(
                                  mode == GameMode.clue
                                      ? l.modeClues
                                      : l.modePoster,
                                ),
                                selected: _mode == mode,
                                onSelected: _busy
                                    ? null
                                    : (_) => setState(() {
                                        _mode = mode;
                                        _reload(showcase);
                                      }),
                              ),
                          ],
                        ),
                        if (snapshot.hasError || _failed)
                          Text(l.gameLoadFailed),
                        const SizedBox(height: 12),
                        for (final (index, movie) in showcase.movies.indexed)
                          Card(
                            child: ListTile(
                              leading: Text('${index + 1}'.padLeft(2, '0')),
                              title: Text(
                                l.showcaseFilm(index + 1),
                                style: AppTypography.titleMedium,
                              ),
                              trailing: CineusIcon(
                                snapshot.connectionState ==
                                            ConnectionState.done &&
                                        records.any(
                                          (s) =>
                                              s.movieId == movie &&
                                              s.isFinished,
                                        )
                                    ? CineusAssetId.completed
                                    : CineusAssetId.chevron,
                              ),
                              onTap:
                                  _busy ||
                                      !snapshot.hasData ||
                                      snapshot.connectionState !=
                                          ConnectionState.done
                                  ? null
                                  : () => _open(showcase, movie),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
      ),
    );
  }
}
