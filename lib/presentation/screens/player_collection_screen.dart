import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/player_collection.dart';
import '../../l10n/app_l10n.dart';
import '../providers/player_collection_provider.dart';
import '../providers/telemetry_provider.dart';
import '../visuals/cineus_assets.dart';
import '../widgets/cinematic_app_bar.dart';
import '../widgets/cineus_icon.dart';
import '../widgets/collection_artwork.dart';
import '../widgets/commercial_offers_panel.dart';
import '../widgets/ticket_details_sheet.dart';

class PlayerCollectionScreen extends ConsumerStatefulWidget {
  final Widget Function(CollectionLook look)? previewBuilder;
  const PlayerCollectionScreen({super.key, this.previewBuilder});
  @override
  ConsumerState<PlayerCollectionScreen> createState() =>
      _PlayerCollectionScreenState();
}

class _PlayerCollectionScreenState
    extends ConsumerState<PlayerCollectionScreen> {
  CollectionItemKind _kind = CollectionItemKind.avatar;
  String? _candidateId;
  bool _premiere = false;
  bool _onlyOwned = false;
  @override
  void initState() {
    super.initState();
    ref.read(productTelemetryProvider).record('collection_opened');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final state = ref.watch(playerCollectionProvider);
    final catalog = ref.watch(collectionCatalogProvider);
    final profile = state.profile;
    final candidate = catalog.where((i) => i.id == _candidateId).firstOrNull;
    final preview = _premiere
        ? PlayerCollectionCatalog.premierePreview
        : <CollectionItemKind, String>{};
    final inUse =
        candidate == null || profile?.equipped[candidate.kind] == candidate.id;
    final owned =
        candidate != null && (profile?.owned.contains(candidate.id) ?? false);
    final visible =
        catalog
            .where(
              (item) =>
                  item.kind == _kind &&
                  (!_onlyOwned || (profile?.owned.contains(item.id) ?? false)),
            )
            .toList()
          ..sort((a, b) {
            int rank(CollectionItem item) =>
                profile?.equipped[item.kind] == item.id
                ? 0
                : (profile?.owned.contains(item.id) ?? false)
                ? 1
                : 2;
            final byAccess = rank(a).compareTo(rank(b));
            return byAccess != 0
                ? byAccess
                : catalog.indexOf(a).compareTo(catalog.indexOf(b));
          });
    void retry() => ref.read(playerCollectionProvider.notifier).load();
    return Scaffold(
      backgroundColor: AppColors.obsidian950,
      appBar: CinematicAppBar(
        title: l.collectionTitle,
        asset: CineusAssetId.premium,
        textScaler: MediaQuery.textScalerOf(context),
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/settings'),
      ),
      bottomNavigationBar: profile == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: FilledButton(
                  key: const ValueKey('collection-apply'),
                  onPressed: state.saving || state.loading || _premiere || inUse
                      ? null
                      : !owned
                      ? () => _howToGet(candidate)
                      : () async {
                          final notifier = ref.read(
                            playerCollectionProvider.notifier,
                          );
                          final telemetry = ref.read(productTelemetryProvider);
                          final ok = await notifier.equip(candidate.id);
                          if (ok) {
                            telemetry.record(
                              'collection_item_equipped',
                              properties: {'item_id': candidate.id},
                            );
                          }
                        },
                  child: Text(
                    _premiere
                        ? l.commerceComingSoon
                        : state.saving
                        ? l.collectionSave
                        : inUse
                        ? l.collectionEquipped
                        : !owned
                        ? l.collectionHowToGet
                        : l.collectionApply,
                  ),
                ),
              ),
            ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 660),
            child: state.loading && profile == null
                ? const Center(child: CircularProgressIndicator())
                : profile == null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        l.collectionLoadFailed,
                        style: AppTypography.bodyLarge,
                      ),
                      TextButton(onPressed: retry, child: Text(l.retryAction)),
                    ],
                  )
                : ListView(
                    key: const ValueKey('collection-scroll'),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName.isEmpty
                                ? l.collectionProfile
                                : profile.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleLarge,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const ValueKey('collection-edit-profile'),
                              onPressed: state.saving
                                  ? null
                                  : () => _edit(profile),
                              child: Text(l.collectionEditProfile),
                            ),
                          ),
                        ],
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            l.collectionSaveFailed,
                            key: const ValueKey('collection-error'),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.ruby200,
                            ),
                          ),
                        ),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 340),
                          child:
                              widget.previewBuilder?.call(
                                CollectionLook.resolve(
                                  profile,
                                  catalog,
                                  preview: {
                                    ...preview,
                                    if (candidate != null)
                                      candidate.kind: candidate.id,
                                  },
                                ),
                              ) ??
                              CollectionPreview(
                                profile: profile,
                                catalog: catalog,
                                candidate: candidate,
                                preview: preview,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        key: const ValueKey('collection-preview-premiere'),
                        onPressed: () => setState(() {
                          _premiere = !_premiere;
                          _candidateId = null;
                          if (_premiere) {
                            ref
                                .read(productTelemetryProvider)
                                .record(
                                  'item_previewed',
                                  properties: {
                                    'product_id':
                                        'cineus.collection.premiere.v1',
                                  },
                                );
                          }
                        }),
                        child: Text(
                          _premiere
                              ? l.collectionPremierePreview
                              : l.collectionTryPremiere,
                        ),
                      ),
                      if (_premiere || (candidate != null && !owned))
                        Text(
                          l.collectionPreviewNotice,
                          style: AppTypography.bodySmall,
                        ),
                      const SizedBox(height: 22),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final kind in CollectionItemKind.values)
                            ChoiceChip(
                              key: ValueKey('collection-tab-${kind.name}'),
                              selected: _kind == kind,
                              showCheckmark: false,
                              label: Text(switch (kind) {
                                CollectionItemKind.avatar =>
                                  l.collectionAvatars,
                                CollectionItemKind.frame => l.collectionFrames,
                                CollectionItemKind.appearance =>
                                  l.collectionAppearances,
                              }),
                              onSelected: (_) => setState(() {
                                _kind = kind;
                                _candidateId = null;
                                _premiere = false;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final ownedOnly in [false, true])
                            ChoiceChip(
                              key: ValueKey('collection-filter-$ownedOnly'),
                              selected: _onlyOwned == ownedOnly,
                              showCheckmark: false,
                              label: Text(
                                ownedOnly
                                    ? l.collectionOnlyOwned
                                    : l.collectionAllItems,
                              ),
                              onSelected: (_) => setState(() {
                                _onlyOwned = ownedOnly;
                                _candidateId = null;
                                _premiere = false;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (visible.isEmpty)
                        Text(
                          l.collectionEmpty,
                          style: AppTypography.bodyMedium,
                        ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final large =
                              MediaQuery.textScalerOf(context).scale(14) > 21;
                          final columns = large && constraints.maxWidth < 400
                              ? 1
                              : 2;
                          final width =
                              (constraints.maxWidth - 12 * (columns - 1)) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final item in visible)
                                SizedBox(
                                  width: width,
                                  child: _itemTile(item, profile, candidate),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const CommercialOffersPanel(showPlaceholder: true),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _itemTile(
    CollectionItem item,
    PlayerCollection profile,
    CollectionItem? candidate,
  ) {
    final l = AppL10n.of(context);
    final selected = (candidate?.id ?? profile.equipped[_kind]) == item.id;
    final equipped = profile.equipped[item.kind] == item.id;
    final label = collectionItemName(l, item);
    return Semantics(
      button: true,
      selected: selected,
      label: equipped ? '$label, ${l.collectionEquipped}' : label,
      child: Material(
        color: AppColors.obsidian900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? AppColors.gold300 : AppColors.obsidian600,
          ),
        ),
        child: InkWell(
          key: ValueKey('collection-item-${item.id}'),
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            setState(() {
              _candidateId = item.id;
              _premiere = false;
            });
            ref
                .read(productTelemetryProvider)
                .record('item_previewed', properties: {'item_id': item.id});
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                SizedBox(
                  height: 112,
                  child: Stack(
                    children: [
                      Positioned.fill(child: CollectionArtwork(item)),
                      if (equipped)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CineusIcon(CineusAssetId.completed, size: 22),
                        ),
                      if (!profile.owned.contains(item.id))
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: CineusIcon(CineusAssetId.lock, size: 22),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  equipped
                      ? l.collectionEquipped
                      : profile.owned.contains(item.id)
                      ? l.collectionUnlocked
                      : _source(l, item),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _source(AppL10n l, CollectionItem item) => switch (item.collectionId) {
    'weekly_v2' || 'night_v1' || 'city_v1' || 'premiere_v1' => l.missionsTitle,
    'weekly_v1' => l.missionsTitle,
    'event_aurora_v1' => l.seasonEventTitle,
    'plus_v1' => l.commercePlus,
    _ => l.collectionFree,
  };

  Future<void> _howToGet(CollectionItem item) async {
    final l = AppL10n.of(context);
    final (copy, route, action) = switch (item.collectionId) {
      'weekly_v1' ||
      'weekly_v2' ||
      'night_v1' ||
      'city_v1' ||
      'premiere_v1' => (l.collectionUnlockMission, '/journey', l.missionsTitle),
      'event_aurora_v1' => (l.collectionUnlockEvent, '/seasons', l.seasonTitle),
      'plus_v1' => (l.commercePlusTerms, 'tickets', l.commercePlus),
      _ => (l.collectionUnlockSoon, '', l.commerceComingSoon),
    };
    final router = GoRouter.of(context);
    final target = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 120, child: CollectionArtwork(item)),
              const SizedBox(height: 16),
              Text(
                collectionItemName(l, item),
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                copy,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('collection-unlock-action'),
                onPressed: route.isEmpty
                    ? null
                    : () => Navigator.pop(sheetContext, route),
                child: Text(action),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(
                  MaterialLocalizations.of(sheetContext).closeButtonLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || target == null) return;
    if (target == 'tickets') {
      await showTicketDetails(context);
    } else {
      await router.push(target);
    }
  }

  Future<void> _edit(PlayerCollection profile) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ProfileEditor(profile: profile),
    );
  }
}

class _ProfileEditor extends ConsumerStatefulWidget {
  final PlayerCollection profile;
  const _ProfileEditor({required this.profile});
  @override
  ConsumerState<_ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends ConsumerState<_ProfileEditor> {
  late final TextEditingController _name = TextEditingController(
    text: widget.profile.displayName,
  );
  late bool _show = widget.profile.showIdentity;
  bool _failed = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context), state = ref.watch(playerCollectionProvider);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.collectionEditProfile, style: AppTypography.headlineMedium),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('collection-display-name'),
              controller: _name,
              enabled: !state.saving,
              textCapitalization: TextCapitalization.words,
              maxLines: 1,
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (old, next) =>
                      next.text.runes.length > 24 ||
                          RegExp(r'[\x00-\x1f\x7f-\x9f]').hasMatch(next.text)
                      ? old
                      : next,
                ),
              ],
              decoration: InputDecoration(
                labelText: l.collectionDisplayName,
                hintText: l.collectionNameHint,
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              key: const ValueKey('collection-show-identity'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                l.collectionShowIdentity,
                style: AppTypography.bodyMedium,
              ),
              value: _show,
              onChanged: state.saving
                  ? null
                  : (value) => setState(() => _show = value),
            ),
            if (_failed)
              Text(
                l.collectionSaveFailed,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.ruby200,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('collection-save-profile'),
              onPressed: state.saving
                  ? null
                  : () async {
                      final ok = await ref
                          .read(playerCollectionProvider.notifier)
                          .saveIdentity(_name.text, _show);
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                      } else {
                        setState(() => _failed = true);
                      }
                    },
              child: Text(l.collectionSave),
            ),
          ],
        ),
      ),
    );
  }
}
