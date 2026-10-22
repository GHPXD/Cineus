import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/services/mobile_ads_service.dart';
import '../../domain/entities/commercial_product.dart';
import '../l10n_mappers.dart';
import '../providers/commercial_provider.dart';
import '../providers/growth_provider.dart';
import '../providers/monetization_notifier.dart';
import '../providers/telemetry_provider.dart';
import '../visuals/cineus_assets.dart';
import 'cineus_icon.dart';

/// Counts stage cards, independent of grid columns, locks and player progress.
abstract final class StageAdPolicy {
  static bool after(int count, {bool colors = false}) =>
      count > 0 && count % (colors ? 5 : 10) == 0;
}

class StageNativeAd extends ConsumerWidget {
  const StageNativeAd({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rights = ref.watch(activeCommercialEntitlementsProvider);
    if (rights.isLoading ||
        !rights.hasValue ||
        rights.hasError ||
        rights.requireValue.any(
          (e) => CommercialCatalog.byId(
            e.productId,
          )!.benefits.contains(CommercialBenefit.removeInterruptions),
        )) {
      return const SizedBox.shrink();
    }
    final config = ref.watch(commercialConfigurationProvider);
    final ads = ref.watch(mobileAdsConfigurationProvider);
    final growth = ref.watch(growthConfigurationProvider);
    if (config.nativeAds &&
        ads.enabled(config) &&
        ads.validUnit(ads.nativeUnit, config.environment)) {
      if (!growth.ready || growth.bannerHoldout) return const SizedBox.shrink();
      return const _NativePlacement();
    }
    return const _NativeReserved();
  }
}

/// Reserved inventory is explicit; never a fake advertiser or an impression.
class _NativeReserved extends StatelessWidget {
  const _NativeReserved();
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 128),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF08121E),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF23374C)),
    ),
    child: Row(
      children: [
        const CineusIcon(CineusAssetId.video, size: 32),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.adSpaceLabel,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.adSpaceReserved,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NativePlacement extends ConsumerStatefulWidget {
  const _NativePlacement();
  @override
  ConsumerState<_NativePlacement> createState() => _NativePlacementState();
}

class _NativePlacementState extends ConsumerState<_NativePlacement>
    with WidgetsBindingObserver {
  NativeAd? _ad;
  bool _loaded = false, _loading = false;
  int _generation = 0;
  double _width = 0;
  ScrollableState? _scrollable;
  StreamSubscription<void>? _privacy;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context);
    if (_scrollable != next) {
      _scrollable?.position.removeListener(_visibility);
      _scrollable = next;
      next?.position.addListener(_visibility);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _visibility();
    });
  }

  bool get _visible {
    if (!mounted ||
        !TickerMode.valuesOf(context).enabled ||
        !(ModalRoute.of(context)?.isCurrent ?? false) ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.hidden ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.detached) {
      return false;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;
    var viewport = Offset.zero & MediaQuery.sizeOf(context);
    final scrollBox = _scrollable?.context.findRenderObject();
    if (scrollBox is RenderBox && scrollBox.hasSize) {
      viewport = viewport.intersect(
        scrollBox.localToGlobal(Offset.zero) & scrollBox.size,
      );
    }
    return viewport.overlaps(box.localToGlobal(Offset.zero) & box.size);
  }

  void _clear({bool rebuild = true}) {
    _generation++;
    _loading = false;
    _retry?.cancel();
    _retry = null;
    final old = _ad;
    _ad = null;
    if (_loaded && mounted && rebuild) {
      setState(() => _loaded = false);
    } else {
      _loaded = false;
    }
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
  }

  void _visibility() {
    if (!mounted) return;
    if (!_visible) {
      if (_ad != null || _loading) _clear();
      return;
    }
    if (!_loaded &&
        !_loading &&
        _ad == null &&
        _retry == null &&
        _width >= 320) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final service = ref.read(monetizationServiceProvider);
    if (service is! VerifiedMobileAdsService) return;
    _loading = true;
    final generation = ++_generation;
    bool current() => mounted && generation == _generation && _visible;
    try {
      _privacy ??= service.privacyChanges.listen((_) {
        _clear();
        _visibility();
      });
      await service.initialize();
      if (!current() ||
          !service.ready ||
          service.privacyUpdating ||
          !await ConsentInformation.instance.canRequestAds()) {
        return;
      }
      if (!current()) return;
      final telemetry = ref.read(productTelemetryProvider);
      telemetry.record('ad_load_started', properties: {'placement': 'native'});
      late final NativeAd ad;
      ad = NativeAd(
        adUnitId: service.ads.nativeUnit,
        request: const AdRequest(nonPersonalizedAds: true),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.small,
          mainBackgroundColor: const Color(0xFF0B1826),
          cornerRadius: 12,
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFFFFF7E4),
            style: NativeTemplateFontStyle.bold,
            size: 16,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFFB4C3E3),
            size: 13,
          ),
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: const Color(0xFF04101B),
            backgroundColor: const Color(0xFFFFCC46),
            style: NativeTemplateFontStyle.bold,
            size: 14,
          ),
        ),
        listener: NativeAdListener(
          onAdLoaded: (_) {
            if (!current() || _ad != ad) return;
            setState(() => _loaded = true);
          },
          onAdFailedToLoad: (failed, _) {
            failed.dispose();
            if (!current() || _ad != failed) return;
            _ad = null;
            telemetry.record(
              'ad_load_failed',
              properties: {'placement': 'native'},
            );
            _retry = Timer(const Duration(seconds: 60), () {
              _retry = null;
              _visibility();
            });
          },
          onAdImpression: (_) {
            if (current() && _ad == ad) {
              telemetry.record('ad_shown', properties: {'placement': 'native'});
            }
          },
          onPaidEvent: (_, micros, precision, currency) {
            if (mounted && _ad == ad) {
              telemetry.record(
                'ad_value',
                properties: {
                  'placement': 'native',
                  'value_micros': micros.round(),
                  'precision': precision.name,
                  'currency': currency,
                },
              );
            }
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (_) {
      if (mounted && generation == _generation) _clear();
    } finally {
      if (mounted && generation == _generation) _loading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _visibility();

  @override
  void dispose() {
    _generation++;
    _privacy?.cancel();
    _retry?.cancel();
    _scrollable?.position.removeListener(_visibility);
    WidgetsBinding.instance.removeObserver(this);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      _width = constraints.maxWidth;
      if (_width < 320 && (_ad != null || _loading)) _clear(rebuild: false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _visibility();
      });
      final ad = _ad;
      if (!_loaded || ad == null) return const _NativeReserved();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.adSpaceLabel,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: _width.clamp(320, 400),
              height: MediaQuery.textScalerOf(context).scale(14) > 18
                  ? 200
                  : 160,
              child: AdWidget(ad: ad),
            ),
          ),
        ],
      );
    },
  );
}
