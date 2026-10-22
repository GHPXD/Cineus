import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/player_collection.dart';
import '../../l10n/app_l10n.dart';
import '../providers/journey_provider.dart';
export '../providers/journey_provider.dart';
import '../providers/color_providers.dart';
import '../providers/player_collection_provider.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cinematic_app_bar.dart';
import '../widgets/collection_artwork.dart';
import '../widgets/color_character_art.dart';
import '../widgets/character_preview.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});
  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  bool _claiming = false;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.invalidate(journeyProgressProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final progress = ref.watch(journeyProgressProvider);
    final catalog = ref.watch(colorCatalogProvider).asData?.value;
    return Scaffold(
      appBar: CinematicAppBar(
        title: l.missionsTitle,
        asset: CineusAssetId.badgeFirstWin,
        onBack: () => context.canPop() ? context.pop() : context.go('/home'),
        textScaler: MediaQuery.textScalerOf(context),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: progress.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(journeyProgressProvider),
                  child: Text(l.retryAction),
                ),
              ),
              data: (p) => ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const _JourneyShortcuts(),
                  const SizedBox(height: 16),
                  Text(
                    l.missionsWeekly,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  for (final mission in p.missions)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                SizedBox.square(
                                  dimension: 56,
                                  child: CollectionArtwork(
                                    PlayerCollectionCatalog.items.firstWhere(
                                      (i) => i.id == mission.item,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    switch (mission.id) {
                                      'play' => l.missionPlayCount(
                                        mission.target,
                                      ),
                                      'modes' => l.missionModesCount(
                                        mission.target,
                                      ),
                                      _ => l.missionDaysCount(mission.target),
                                    },
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: mission.current / mission.target,
                              semanticsLabel:
                                  '${mission.current}/${mission.target}',
                            ),
                            const SizedBox(height: 8),
                            Text('${mission.current}/${mission.target}'),
                            if (mission.duplicateTickets > 0 &&
                                !mission.claimed)
                              Text(
                                '${l.missionDuplicate} · +${mission.duplicateTickets} tickets',
                              ),
                            if (mission.current >= mission.target)
                              TextButton(
                                onPressed: mission.claimed || _claiming
                                    ? null
                                    : () async {
                                        setState(() => _claiming = true);
                                        try {
                                          await ref
                                              .read(journeyRepositoryProvider)
                                              .claim(mission.id);
                                          await ref
                                              .read(
                                                playerCollectionProvider
                                                    .notifier,
                                              )
                                              .load();
                                          ref.invalidate(
                                            journeyProgressProvider,
                                          );
                                          await ref.read(
                                            journeyProgressProvider.future,
                                          );
                                        } catch (_) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(l.retryAction),
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() => _claiming = false);
                                          }
                                        }
                                      },
                                child: Text(
                                  mission.claimed
                                      ? l.missionClaimed
                                      : l.missionClaim,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    l.discoveryTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (catalog != null)
                    LayoutBuilder(
                      builder: (context, c) {
                        final questions = {
                          for (final q in catalog.questions) q.characterId: q,
                        }.values.toList();
                        final columns = c.maxWidth < 480 ? 2 : 3;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                childAspectRatio: .78,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: questions.length,
                          itemBuilder: (context, index) {
                            final q = questions[index],
                                found = p.discovered.contains(
                                  questions[index].characterId,
                                );
                            final palette = {
                              for (final part in catalog.questions.where(
                                (p) => p.characterId == q.characterId,
                              ))
                                part.artPart!: part.target,
                            };
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: CharacterPreview(
                                        locked: !found,
                                        child: ColorCharacterArt(
                                          question: q,
                                          choice: q.target,
                                          palette: palette,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      found
                                          ? q.text(
                                              'character',
                                              Localizations.localeOf(
                                                context,
                                              ).languageCode,
                                            )
                                          : l.discoveryMystery,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyShortcuts extends StatelessWidget {
  const _JourneyShortcuts();

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final shortcuts = [
      (l.archiveMode, l.archiveMode, '/archive'),
      (l.journeyMasteryShortcut, l.masteryTitle, '/mastery'),
      (l.journeyFriendsShortcut, l.friendGames, '/friends'),
    ];
    final style = AppTypography.labelLarge;
    return LayoutBuilder(
      builder: (context, constraints) {
        var width = (constraints.maxWidth - 16) / 3;
        // Keep one row without shrinking accessibility text. Large text can
        // scroll horizontally to reach every action with its full label.
        for (final shortcut in shortcuts) {
          final text = TextPainter(
            text: TextSpan(text: shortcut.$1, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          final needed = text.width.ceilToDouble() + 24;
          if (needed > width) width = needed;
          text.dispose();
        }
        return SingleChildScrollView(
          key: const ValueKey('journey-shortcuts'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (index, shortcut) in shortcuts.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                SizedBox(
                  width: width,
                  child: Tooltip(
                    message: shortcut.$2,
                    excludeFromSemantics: true,
                    child: OutlinedButton(
                      key: ValueKey('journey-shortcut${shortcut.$3}'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 12,
                        ),
                        textStyle: style,
                      ),
                      onPressed: () => context.push(shortcut.$3),
                      child: Text(
                        shortcut.$1,
                        semanticsLabel: shortcut.$2,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
