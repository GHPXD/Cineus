import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/commerce_content.dart';
import '../../domain/entities/player_collection.dart';
import '../../data/repositories/sponsored_event_repository.dart';
import '../../l10n/app_l10n.dart';
import '../providers/commerce_content_provider.dart';
import '../providers/commercial_provider.dart';
import '../providers/providers.dart';
import '../providers/app_clock.dart';
import 'cinema_showcase_screen.dart';
import '../providers/player_collection_provider.dart';
import '../widgets/collection_artwork.dart';
import '../widgets/cinematic_app_bar.dart';
import '../widgets/cineus_brand.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/commercial_offers_panel.dart';
import '../visuals/cineus_assets.dart';

final sponsoredEventRepositoryProvider = Provider<SponsoredEventRepository>(
  (ref) => SponsoredEventRepository(
    ref.read(databaseProvider),
    ref.read(appClockProvider),
  ),
);
final eventProgressProvider =
    FutureProvider.family<EventProgress, ContentEvent>(
      (ref, event) =>
          ref.watch(sponsoredEventRepositoryProvider).progress(event),
    );

class SeasonsScreen extends ConsumerStatefulWidget {
  const SeasonsScreen({super.key});
  @override
  ConsumerState<SeasonsScreen> createState() => _SeasonsScreenState();
}

class _SeasonsScreenState extends ConsumerState<SeasonsScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
    Future.microtask(_refresh);
  }

  void _refresh() {
    if (!mounted) return;
    ref.invalidate(eventProgressProvider);
    unawaited(ref.read(playerCollectionProvider.notifier).load());
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final content = ref.watch(commerceContentProvider);
    final now = ref.read(appClockProvider)();
    final profile = ref.watch(playerCollectionProvider).profile;
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      appBar: CinematicAppBar(
        title: l.seasonTitle,
        asset: CineusAssetId.premium,
        textScaler: MediaQuery.textScalerOf(context),
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/settings'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: content.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.seasonUpdateFailed, textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => ref.invalidate(commerceContentProvider),
                      child: Text(l.retryAction),
                    ),
                  ],
                ),
              ),
              data: (catalog) {
                final current = catalog.collections
                    .where((c) => c.visible(now))
                    .toList();
                final future =
                    catalog.collections
                        .where((c) => now.isBefore(c.from))
                        .toList()
                      ..sort((a, b) => a.from.compareTo(b.from));
                final past = catalog.collections
                    .where(
                      (c) =>
                          !now.isBefore(c.until) &&
                          c.items.any(
                            (id) => profile?.owned.contains(id) ?? false,
                          ),
                    )
                    .toList();
                final events = catalog.events
                    .where((e) => !now.isBefore(e.from))
                    .toList();
                return ListView(
                  key: const ValueKey('seasons-scroll'),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    Text(l.seasonIntro, style: AppTypography.bodyMedium),
                    const SizedBox(height: 22),
                    for (final theme in ['animation', 'fantasy', 'classics'])
                      Card(
                        child: ListTile(
                          title: Text(
                            showcaseName(l, theme),
                            style: AppTypography.titleMedium,
                          ),
                          subtitle: Text(l.showcasePlay),
                          trailing: const CineusIcon(CineusAssetId.chevron),
                          onTap: () => context.push('/showcase/$theme'),
                        ),
                      ),
                    const SizedBox(height: 22),
                    if (current.isNotEmpty) ...[
                      Text(l.seasonCurrent, style: AppTypography.titleLarge),
                      const SizedBox(height: 12),
                      for (final collection in current) ...[
                        _SeasonCard(
                          collection: collection,
                          now: now,
                          profile: profile,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                    if (current.isEmpty && future.isEmpty && past.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(l.seasonEmpty),
                      ),
                    if (future.isNotEmpty) ...[
                      Text(l.seasonNext, style: AppTypography.titleLarge),
                      const SizedBox(height: 12),
                      for (final collection in future) ...[
                        _SeasonCard(
                          collection: collection,
                          now: now,
                          profile: profile,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                    if (past.isNotEmpty) ...[
                      Text(l.seasonArchive, style: AppTypography.titleLarge),
                      const SizedBox(height: 12),
                      for (final collection in past) ...[
                        _SeasonCard(
                          collection: collection,
                          now: now,
                          profile: profile,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                    for (final event in events) ...[
                      _EventCard(event, key: ValueKey(event.id)),
                      const SizedBox(height: 16),
                    ],
                    if (ref
                            .watch(commerceContentServiceProvider)
                            .asData
                            ?.value !=
                        null)
                      TextButton(
                        onPressed: () async {
                          try {
                            await (await ref.read(
                              commerceContentServiceProvider.future,
                            ))?.update();
                            ref.invalidate(commerceContentProvider);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.seasonUpdateFailed)),
                              );
                            }
                          }
                        },
                        child: Text(l.seasonRefresh),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final ContentCollection collection;
  final DateTime now;
  final PlayerCollection? profile;
  const _SeasonCard({
    required this.collection,
    required this.now,
    this.profile,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = collection;
    final language = Localizations.localeOf(context).languageCode;
    final items = PlayerCollectionCatalog.items
        .where((i) => c.items.contains(i.id))
        .toList();
    final background = items
        .where((i) => i.kind == CollectionItemKind.appearance)
        .firstOrNull;
    final avatars = items
        .where((i) => i.kind == CollectionItemKind.avatar)
        .toList();
    final upcoming = now.isBefore(c.from);
    final archived = !now.isBefore(c.until);
    final count = c.items
        .where((id) => profile?.owned.contains(id) ?? false)
        .length;
    final date = DateFormat.MMMd(language).format(
      (upcoming ? c.from : c.until.subtract(const Duration(microseconds: 1)))
          .toUtc(),
    );
    return Container(
      key: ValueKey('season-card-${c.id}'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1C30),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: upcoming || archived
              ? const Color(0xFF29435B)
              : AppColors.gold300.withValues(alpha: .7),
        ),
      ),
      child: Stack(
        children: [
          if (background != null)
            Positioned.fill(
              child: CollectionArtwork(background, fit: BoxFit.cover),
            ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF0081322),
                    Color(0xCC081322),
                    Color(0x77081322),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  archived
                      ? l.seasonFinished
                      : upcoming
                      ? l.seasonAvailableOn(date)
                      : l.seasonUntil(date),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.gold300,
                  ),
                ),
                const SizedBox(height: 10),
                Text(c.title(language), style: AppTypography.headlineMedium),
                const SizedBox(height: 6),
                Text(l.seasonItems, style: AppTypography.bodySmall),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final avatar in avatars)
                      SizedBox.square(
                        dimension: 68,
                        child: CollectionArtwork(avatar),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (profile != null) ...[
                  Text(
                    l.seasonOwnedCount(count, c.items.length),
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton(
                  key: ValueKey('season-explore-${c.id}'),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    backgroundColor: AppColors.obsidian950,
                    builder: (_) => SeasonPreviewSheet(collection: c, now: now),
                  ),
                  child: Text(l.seasonTry),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Selection changes the preview only; purchases/equipping use existing services.
class SeasonPreviewSheet extends ConsumerStatefulWidget {
  final ContentCollection collection;
  final DateTime now;
  const SeasonPreviewSheet({
    super.key,
    required this.collection,
    required this.now,
  });
  @override
  ConsumerState<SeasonPreviewSheet> createState() => _SeasonPreviewSheetState();
}

class _SeasonPreviewSheetState extends ConsumerState<SeasonPreviewSheet>
    with WidgetsBindingObserver {
  final Map<CollectionItemKind, String> _selected = {};
  CollectionItemKind _kind = CollectionItemKind.avatar;
  late DateTime _now = widget.now;
  Timer? _clock;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
    for (final kind in CollectionItemKind.values) {
      final item = PlayerCollectionCatalog.items
          .where(
            (i) => widget.collection.items.contains(i.id) && i.kind == kind,
          )
          .firstOrNull;
      if (item != null) _selected[kind] = item.id;
    }
  }

  void _refresh() {
    if (!mounted) return;
    final now = ref.read(appClockProvider)();
    if (widget.collection.visible(_now) != widget.collection.visible(now)) {
      ref.invalidate(commercialOffersProvider);
    }
    setState(() => _now = now);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = widget.collection;
    final catalog = PlayerCollectionCatalog.items;
    final look = CollectionLook.resolve(null, catalog, preview: _selected);
    final profile = ref.watch(playerCollectionProvider).profile;
    final owned = c.items.every((id) => profile?.owned.contains(id) ?? false);
    final available = ref.watch(commercialOffersProvider);
    final offers = available.asData?.value ?? [];
    final purchasable =
        offers.any((o) => o.productId == c.product) && c.visible(_now);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              key: const ValueKey('season-preview-scroll'),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.seasonPreviewTitle,
                        style: AppTypography.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      icon: const CineusIcon(CineusAssetId.close),
                    ),
                  ],
                ),
                Text(
                  c.title(Localizations.localeOf(context).languageCode),
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 16),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: CollectionCardSurface(
                      look: look,
                      children: [
                        const Center(
                          child: CineusWordmark(
                            fontSize: 24,
                            showSymbol: true,
                            symbolSize: 27,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (look.avatar != null)
                          SizedBox(
                            height: 100,
                            child: CollectionArtwork(look.avatar!),
                          ),
                        const SizedBox(height: 14),
                        Text(
                          l.collectionPreview,
                          textAlign: TextAlign.center,
                          style: AppTypography.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.collectionPreviewNotice,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final kind in CollectionItemKind.values)
                      ChoiceChip(
                        key: ValueKey('season-kind-${kind.name}'),
                        selected: _kind == kind,
                        showCheckmark: false,
                        label: Text(switch (kind) {
                          CollectionItemKind.avatar => l.collectionAvatars,
                          CollectionItemKind.frame => l.collectionFrames,
                          CollectionItemKind.appearance =>
                            l.collectionAppearances,
                        }),
                        onSelected: (_) => setState(() => _kind = kind),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                        constraints.maxWidth < 300 ||
                            MediaQuery.textScalerOf(context).scale(14) > 21
                        ? 1
                        : 2;
                    final width =
                        (constraints.maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final item in catalog.where(
                          (i) => c.items.contains(i.id) && i.kind == _kind,
                        ))
                          SizedBox(
                            width: width,
                            child: Semantics(
                              selected: _selected[_kind] == item.id,
                              child: Material(
                                color: const Color(0xFF0B1929),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: _selected[_kind] == item.id
                                        ? AppColors.gold300
                                        : const Color(0xFF29435B),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  key: ValueKey('season-item-${item.id}'),
                                  onTap: () => setState(
                                    () => _selected[_kind] = item.id,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: 100,
                                          child: CollectionArtwork(item),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          collectionItemName(l, item),
                                          textAlign: TextAlign.center,
                                          style: AppTypography.bodySmall,
                                        ),
                                        if (profile?.owned.contains(item.id) ==
                                            true)
                                          Text(
                                            l.collectionOwned,
                                            style: AppTypography.labelSmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (owned)
                  FilledButton(
                    onPressed: () {
                      final router = GoRouter.of(context);
                      Navigator.pop(context);
                      router.push('/collection');
                    },
                    child: Text(l.collectionTitle),
                  ),
                if (!owned &&
                    c.visible(_now) &&
                    (available.isLoading || available.hasError))
                  const CommercialAvailabilityNotice(),
                if (!owned &&
                    !purchasable &&
                    (!c.visible(_now) ||
                        (!available.isLoading && !available.hasError))) ...[
                  Text(
                    l.showcaseRewards,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () {
                      final router = GoRouter.of(context);
                      Navigator.pop(context);
                      router.push('/journey');
                    },
                    child: Text(l.missionsTitle),
                  ),
                ],
                if (purchasable) CommercialOffersPanel(productIds: {c.product}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends ConsumerStatefulWidget {
  final ContentEvent event;
  const _EventCard(this.event, {super.key});
  @override
  ConsumerState<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<_EventCard> {
  bool busy = false;
  Future<void> _act(EventProgress p) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final repo = ref.read(sponsoredEventRepositoryProvider);
      if (!p.joined) {
        await repo.join(widget.event);
      } else {
        await repo.claim(widget.event);
        await ref.read(playerCollectionProvider.notifier).load();
      }
      ref.invalidate(eventProgressProvider(widget.event));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.of(context).retryAction)),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context), e = widget.event;
    final progress = ref.watch(eventProgressProvider(e));
    final active = e.active(ref.read(appClockProvider)());
    final reward = PlayerCollectionCatalog.items
        .where((i) => i.id == e.reward)
        .firstOrNull;
    return Container(
      key: ValueKey('season-event-${e.id}'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1929),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF29435B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CineusIcon(CineusAssetId.challenge, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.seasonEventTitle,
                  style: AppTypography.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            e.demo ? l.seasonEventDemo : l.sponsorDisclosure,
            style: AppTypography.bodySmall,
          ),
          if (!e.demo)
            Text(
              e.sponsor[Localizations.localeOf(context).languageCode] ??
                  e.sponsor['en']!,
            ),
          if (reward != null) ...[
            const SizedBox(height: 12),
            SizedBox(height: 130, child: CollectionArtwork(reward)),
            Text(
              collectionItemName(l, reward),
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall,
            ),
          ],
          const SizedBox(height: 14),
          Text(l.sponsorGoalCount(e.target), style: AppTypography.bodySmall),
          const SizedBox(height: 10),
          if (!active) Text(l.sponsorEnded, style: AppTypography.bodySmall),
          progress.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => TextButton(
              onPressed: () => ref.invalidate(eventProgressProvider(e)),
              child: Text(l.retryAction),
            ),
            data: (p) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(
                  value: p.completed / e.target,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 6),
                Text(
                  '${p.completed}/${e.target}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed:
                      busy ||
                          p.claimed ||
                          (p.joined && p.completed < e.target) ||
                          (!p.joined && !active)
                      ? null
                      : () => _act(p),
                  child: Text(
                    p.claimed
                        ? l.missionClaimed
                        : !active && !p.joined
                        ? l.sponsorEnded
                        : !p.joined
                        ? l.sponsorJoin
                        : p.completed >= e.target
                        ? l.missionClaim
                        : l.sponsorGoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
