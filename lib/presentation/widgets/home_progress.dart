import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/game_session.dart';
import '../l10n_mappers.dart';
import '../providers/progress_provider.dart';
import '../providers/journey_provider.dart';
import '../providers/play_notifier.dart';
import '../providers/color_providers.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';
import 'home_cinematic_deck.dart';

/// One useful action, not a second shop on the home screen.
class HomeProgress extends ConsumerWidget {
  const HomeProgress({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final continuing = ref.watch(continuingGameProvider).valueOrNull;
    final colors = ref
        .watch(colorSessionsProvider)
        .valueOrNull
        ?.where((s) => s.status == 'active')
        .firstOrNull;
    final missions = ref
        .watch(journeyProgressProvider)
        .valueOrNull
        ?.missions
        .where((m) => !m.claimed)
        .toList();
    missions?.sort(
      (a, b) => (b.current / b.target).compareTo(a.current / a.target),
    );
    final goal = missions?.firstOrNull;
    final presence = ref.watch(presenceProvider).valueOrNull;
    if (continuing == null &&
        colors == null &&
        goal == null &&
        presence == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: HomeChromePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CineusIcon(CineusAssetId.badgeFirstWin, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    continuing != null || colors != null
                        ? l.continueGame
                        : l.nextGoal,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (presence != null)
                  Tooltip(
                    message: l.presenceStreak,
                    child: Semantics(
                      label: l.presenceDays(presence.current),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CineusIcon(CineusAssetId.streak, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${presence.current}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (continuing == null && colors == null && goal != null) ...[
              Text(switch (goal.id) {
                'play' => l.missionPlayCount(goal.target),
                'modes' => l.missionModesCount(goal.target),
                _ => l.missionDaysCount(goal.target),
              }),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: goal.current / goal.target),
              const SizedBox(height: 6),
            ],
            TextButton.icon(
              key: const ValueKey('home-progress-action'),
              icon: const CineusIcon(CineusAssetId.chevron, size: 16),
              label: Text(
                continuing != null
                    ? (continuing.mode == GameMode.clue
                          ? l.modeClues
                          : l.modePoster)
                    : colors != null
                    ? l.colorModeTitle
                    : l.missionsTitle,
              ),
              onPressed: () async {
                if (continuing != null) {
                  final provider = continuing.mode == GameMode.clue
                      ? clueGameProvider
                      : posterGameProvider;
                  if (await ref.read(provider.notifier).resume(continuing) &&
                      context.mounted) {
                    await context.push(
                      '${continuing.mode == GameMode.clue ? '/game' : '/visual/play'}?source=${continuing.kind.name}',
                    );
                  }
                } else if (colors != null) {
                  await context.push(
                    '/colors/session/${Uri.encodeComponent(colors.id)}',
                  );
                } else {
                  await context.push('/journey');
                }
                if (!context.mounted) return;
                ref.invalidate(continuingGameProvider);
                ref.invalidate(journeyProgressProvider);
                ref.invalidate(presenceProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}
