import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/commercial_product.dart';
import '../../domain/entities/player_collection.dart';
import '../../l10n/app_l10n.dart';
import '../providers/commercial_provider.dart';
import '../providers/audience_provider.dart';
import '../providers/player_collection_provider.dart';
import '../providers/telemetry_provider.dart';
import '../../data/services/native_commercial_store.dart';
import '../../data/services/unavailable_commercial_store.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_clock.dart';
import '../providers/providers.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/release_legal_l10n.dart';
import '../providers/external_links.dart';
import 'commerce_placeholders.dart';
import 'cineus_icon.dart';
import '../visuals/cineus_assets.dart';

/// Loading and unavailable are different states: a network failure must never
/// disguise an already configured store as a feature that is coming soon.
class CommercialAvailabilityNotice extends ConsumerWidget {
  final bool checkEntitlements;
  const CommercialAvailabilityNotice({
    super.key,
    this.checkEntitlements = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final offers = ref.watch(commercialOffersProvider);
    final rights = checkEntitlements
        ? ref.watch(activeCommercialEntitlementsProvider)
        : const AsyncData<List<CommercialEntitlement>>([]);
    final failed = offers.hasError || rights.hasError;
    if (!failed && !offers.isLoading && !rights.isLoading) {
      return const SizedBox.shrink();
    }
    return Card(
      key: const ValueKey('commerce-availability-notice'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (failed)
                  const CineusIcon(CineusAssetId.information, size: 24)
                else
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    failed
                        ? rights.hasError
                              ? l.commerceCheckFailed
                              : l.commerceOffersFailed
                        : l.commerceLoading,
                  ),
                ),
              ],
            ),
            if (failed)
              TextButton(
                key: const ValueKey('commerce-retry'),
                onPressed: () {
                  ref.invalidate(commercialOffersProvider);
                  ref.invalidate(commercialEntitlementsProvider);
                },
                child: Text(l.retryAction),
              ),
          ],
        ),
      ),
    );
  }
}

class CommercialOffersPanel extends ConsumerStatefulWidget {
  final bool showPlaceholder;
  final Set<String>? productIds;
  const CommercialOffersPanel({
    super.key,
    this.showPlaceholder = false,
    this.productIds,
  });
  @override
  ConsumerState<CommercialOffersPanel> createState() =>
      _CommercialOffersPanelState();
}

class _CommercialOffersPanelState extends ConsumerState<CommercialOffersPanel> {
  bool _busy = false;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ref.read(commercialOperationProvider.notifier).state = 'failed';
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final store = ref.read(commercialStoreProvider);
    final now = ref.read(appClockProvider);
    ref.read(commercialOperationProvider.notifier).state = 'restoring';
    final rights = await store.restore();
    if (!mounted) return;
    ref.invalidate(commercialEntitlementsProvider);
    ref
        .read(commercialOperationProvider.notifier)
        .state = store is NativeCommercialStore && store.verificationPending
        ? 'pending'
        : rights.any((right) => right.activeAt(now()))
        ? 'restored'
        : 'restoreEmpty';
  }

  Future<void> _recovery({required bool restore}) async {
    final sync = ref.read(commerceSynchronizerProvider);
    if (sync == null) return;
    if (!restore) await sync.synchronize();
    if (!mounted) return;
    final l = AppL10n.of(context);
    final controller = TextEditingController();
    try {
      final code = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(restore ? l.commerceRecovery : l.commerceRecoveryKey),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.commerceRecoveryInfo),
                const SizedBox(height: 12),
                if (restore)
                  TextField(
                    controller: controller,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    maxLength: 80,
                    decoration: InputDecoration(
                      labelText: l.commerceRecoveryKey,
                    ),
                  )
                else
                  SelectableText(
                    '${sync.identity!.owner}.${sync.identity!.recovery}',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
            if (restore)
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: Text(l.commerceRecoverAction),
              ),
          ],
        ),
      );
      if (code != null) {
        await sync.recoverIdentity(code);
        if (mounted) await _restore();
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final available = ref.watch(commercialOffersProvider);
    final canPurchase =
        ref.watch(playerAudienceProvider).valueOrNull?.canPurchase == true;
    final offers = (available.asData?.value ?? [])
        .where(
          (offer) =>
              widget.productIds == null ||
              widget.productIds!.contains(offer.productId),
        )
        .toList();
    if (!available.isLoading &&
        !available.hasError &&
        offers.isEmpty &&
        ref.watch(commercialStoreProvider) is UnavailableCommercialStore) {
      return widget.showPlaceholder
          ? const OptionalStorePlaceholder()
          : const SizedBox.shrink();
    }
    final profile = ref.watch(playerCollectionProvider).profile;
    final status = ref.watch(commercialOperationProvider);
    final access = ref.watch(activeCommercialEntitlementsProvider);
    final rights = access.asData?.value;
    bool owned(String id) {
      if (CommercialCatalog.byId(id)?.kind ==
          CommercialProductKind.consumableTickets) {
        return false;
      }
      if (rights?.any((e) => e.productId == id) ?? false) return true;
      final product = CommercialCatalog.byId(id);
      // A Club cycle can leave its cosmetics permanently owned without a
      // separate one-off purchase. Do not sell the same complete set again.
      if (product?.kind != CommercialProductKind.permanentCollection) {
        return false;
      }
      final items = PlayerCollectionCatalog.items.where(
        (item) => item.collectionId == product!.collectionId,
      );
      return items.isNotEmpty &&
          items.every((item) => profile?.owned.contains(item.id) ?? false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (access.isLoading ||
            access.hasError ||
            available.isLoading ||
            available.hasError)
          const CommercialAvailabilityNotice(checkEntitlements: true),
        if (offers.isEmpty && !available.isLoading && !available.hasError)
          Text(canPurchase ? l.commerceNoOffers : l.audiencePurchases),
        for (final offer in offers)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(switch (offer.productId) {
                    'cineus.collection.premiere.v1' => l.collectionPremiere,
                    'cineus.plus.permanent.v1' => l.commercePlus,
                    'cineus.collection.night.v1' => l.collectionNight,
                    'cineus.collection.city.v1' => l.collectionCity,
                    'cineus.tickets.20.v1' => l.ticketPackAmount(20),
                    'cineus.tickets.60.v1' => l.ticketPackAmount(60),
                    _ => l.commerceClub,
                  }, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    CommercialCatalog.byId(offer.productId)!.kind ==
                            CommercialProductKind.consumableTickets
                        ? l.ticketPackTerms
                        : offer.productId == CommercialCatalog.club.id
                        ? l.commerceClubTerms
                        : offer.productId == CommercialCatalog.plus.id
                        ? l.commercePlusTerms
                        : l.commerceCollectionTerms,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed:
                        _busy ||
                            status == 'pending' ||
                            status == 'restoring' ||
                            access.isLoading ||
                            access.hasError ||
                            rights == null ||
                            owned(offer.productId) ||
                            !canPurchase
                        ? null
                        : () => _run(() async {
                            final store = ref.read(commercialStoreProvider);
                            final tickets = ref.read(
                              ticketNotifierProvider.notifier,
                            );
                            final telemetry = ref.read(
                              productTelemetryProvider,
                            );
                            await telemetry.record(
                              'purchase_started',
                              properties: {'product_id': offer.productId},
                            );
                            final result = await store.purchase(
                              offer.productId,
                            );
                            await tickets.refreshPaidBalance();
                            if (!mounted) return;
                            ref
                                    .read(commercialOperationProvider.notifier)
                                    .state =
                                result.status.name;
                            ref.invalidate(commercialEntitlementsProvider);
                          }),
                    child: Text(
                      owned(offer.productId)
                          ? offer.productId == CommercialCatalog.club.id
                                ? l.commerceSubscriptionActive
                                : l.collectionOwned
                          : l.commerceBuy(offer.localizedPrice),
                    ),
                  ),
                  if (CommercialCatalog.byId(offer.productId)?.collectionId
                      case final String collection)
                    if (PlayerCollectionCatalog.items
                            .where((i) => i.collectionId == collection)
                            .isNotEmpty &&
                        PlayerCollectionCatalog.items
                            .where((i) => i.collectionId == collection)
                            .every(
                              (i) => profile?.owned.contains(i.id) ?? false,
                            ))
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                final collectionNotifier = ref.read(
                                  playerCollectionProvider.notifier,
                                );
                                for (final kind in CollectionItemKind.values) {
                                  final item = PlayerCollectionCatalog.items
                                      .where(
                                        (i) =>
                                            i.collectionId == collection &&
                                            i.kind == kind,
                                      )
                                      .firstOrNull;
                                  if (item != null) {
                                    await collectionNotifier.equip(item.id);
                                  }
                                }
                              }),
                        child: Text(l.commerceUse),
                      ),
                ],
              ),
            ),
          ),
        if (status != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                switch (status) {
                  'verified' => l.commerceVerified,
                  'pending' => l.commercePending,
                  'cancelled' => l.commerceCancelled,
                  'restoring' => l.commerceRestoring,
                  'restored' => l.commerceRestoreDone,
                  'restoreEmpty' => l.commerceRestoreEmpty,
                  _ => l.commerceFailed,
                },
                semanticsLabel: switch (status) {
                  'verified' => l.commerceVerified,
                  _ => null,
                },
              ),
            ),
          ),
        TextButton(
          key: const ValueKey('commerce-restore'),
          onPressed: _busy ? null : () => _run(_restore),
          child: Text(l.commerceRestore),
        ),
        if (rights?.any((e) => e.productId == CommercialCatalog.club.id) ??
            false)
          TextButton(
            onPressed: () => _run(() async {
              final uri = PlatformExternalLinks.subscriptionSettings(
                apple: defaultTargetPlatform == TargetPlatform.iOS,
              );
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                throw StateError('Subscription settings unavailable');
              }
            }),
            child: Text(l.commerceManage),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.push('/terms'),
              child: Text(ReleaseLegalL10n.of(context).termsLabel),
            ),
            TextButton(
              onPressed: () => context.push('/privacy'),
              child: Text(ReleaseLegalL10n.of(context).privacyLabel),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => _recovery(restore: false)),
              child: Text(l.commerceRecoveryKey),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => _recovery(restore: true)),
              child: Text(l.commerceRecovery),
            ),
          ],
        ),
      ],
    );
  }
}
