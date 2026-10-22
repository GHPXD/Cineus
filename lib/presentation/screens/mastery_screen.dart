import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/play_insights.dart';
import '../l10n_mappers.dart';
import '../providers/providers.dart';
import '../providers/progress_provider.dart';
import '../providers/play_notifier.dart';
import '../providers/growth_provider.dart';
import '../widgets/cinematic_app_bar.dart';
import '../widgets/cineus_icon.dart';
import '../visuals/cineus_assets.dart';

final masteryProvider = FutureProvider((ref) async {
  final progress = ref.read(progressRepositoryProvider);
  final movies = ref.read(movieRepositoryProvider);
  final stages = ref.read(stageRepositoryProvider);
  final economy = ref.read(economyRepositoryProvider);
  final sessions = [
    ...await progress.films(GameMode.clue, ActivityScope.all),
    ...await progress.films(GameMode.poster, ActivityScope.all),
  ];
  final distinct = <int, GameSession>{};
  for (final session in sessions) {
    final previous = distinct[session.movieId];
    if (previous == null || session.status == GameStatus.won) {
      distinct[session.movieId] = session;
    }
  }
  final catalog = await movies.getMoviesByIds(distinct.keys.toList());
  final published =
      jsonDecode(await rootBundle.loadString('assets/daily/themes_v1.json'))
          as Map<String, dynamic>;
  if (published['schema'] != 1) {
    throw const FormatException('Unsupported themes');
  }
  final themes = [
    for (final value in published['themes'] as List)
      (value['id'] as String, (value['movies'] as List).cast<int>()),
  ];
  if (themes.any(
    (t) =>
        t.$2.length != 10 ||
        t.$2.toSet().length != 10 ||
        t.$2.any((id) => id < 1 || id > 500),
  )) {
    throw const FormatException('Invalid theme');
  }
  final titles = <(String, int)>[];
  for (final mode in ['clue', 'poster']) {
    for (final stage in await stages.getAllStages(mode: mode)) {
      if (stage.isCompleted && await economy.bonus(mode, stage.id) == 4) {
        titles.add((mode, stage.id));
      }
    }
  }
  return (
    PlayInsights.from(distinct.values.toList(), {
      for (final m in catalog) m.id: m,
    }),
    sessions,
    titles,
    themes,
  );
});

class MasteryScreen extends ConsumerStatefulWidget {
  const MasteryScreen({super.key});
  @override
  ConsumerState<MasteryScreen> createState() => _MasteryState();
}

class _MasteryState extends ConsumerState<MasteryScreen> {
  bool _busy = false;
  Future<void> _practice(GameSession s) async {
    if (_busy) return;
    setState(() => _busy = true);
    final notifier = ref.read(
      (s.mode == GameMode.clue ? clueGameProvider : posterGameProvider)
          .notifier,
    );
    try {
      if (await notifier.loadPractice(s.movieId) && mounted) {
        await context.push(
          '${s.mode == GameMode.clue ? '/game' : '/visual/play'}?source=training',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _theme(List<int> ids, List<GameSession> sessions) async {
    final won = sessions
        .where((s) => s.status == GameStatus.won)
        .map((s) => s.movieId)
        .toSet();
    final id = ids.where((id) => !won.contains(id)).firstOrNull ?? ids.first;
    await _practice(
      GameSession(mode: GameMode.clue, kind: SessionKind.training, movieId: id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: CinematicAppBar(
        title: l.masteryTitle,
        asset: CineusAssetId.categoryGoal,
        textScaler: MediaQuery.textScalerOf(context),
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      ),
      body: ref
          .watch(masteryProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(masteryProvider),
                child: Text(l.retryAction),
              ),
            ),
            data: (data) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (data.$2.isEmpty) Text(l.masteryEmpty),
                for (final theme in data.$4)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(switch (theme.$1) {
                            'animation' => l.masteryAnimation,
                            'fantasy' => l.masteryFantasy,
                            _ => l.masteryClassics,
                          }, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 10),
                          Builder(
                            builder: (context) {
                              final won = data.$2
                                  .where(
                                    (s) =>
                                        s.status == GameStatus.won &&
                                        theme.$2.contains(s.movieId),
                                  )
                                  .map((s) => s.movieId)
                                  .toSet()
                                  .length;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LinearProgressIndicator(value: won / 10),
                                  const SizedBox(height: 8),
                                  Text('$won/10'),
                                  TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => _theme(theme.$2, data.$2),
                                    child: Text(l.practiceMode),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                if (data.$3.isNotEmpty) ...[
                  Text(
                    l.masteryTitles,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  for (final title in data.$3)
                    Card(
                      child: ListTile(
                        leading: const CineusIcon(CineusAssetId.badgeStages5),
                        title: Text(l.masteryStageTitle(title.$2)),
                        subtitle: Text(
                          title.$1 == 'clue' ? l.modeClues : l.modePoster,
                        ),
                      ),
                    ),
                ],
                for (final bucket in data.$1.byGenre)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bucket.label,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: (bucket.played / 10).clamp(0.0, 1.0),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${bucket.played.clamp(0, 10)}/10 · ${l.statWins}: ${bucket.won}',
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  l.practiceAgain,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final s
                    in data.$2
                        .where((s) => s.status == GameStatus.lost)
                        .take(8))
                  Card(
                    child: ListTile(
                      leading: CineusIcon(
                        s.mode == GameMode.clue
                            ? CineusAssetId.modeClues
                            : CineusAssetId.modePoster,
                      ),
                      title: Text(
                        '${s.mode == GameMode.clue ? l.modeClues : l.modePoster} · #${s.movieId}',
                      ),
                      trailing: const CineusIcon(CineusAssetId.chevron),
                      onTap: _busy ? null : () => _practice(s),
                    ),
                  ),
              ],
            ),
          ),
    );
  }
}
