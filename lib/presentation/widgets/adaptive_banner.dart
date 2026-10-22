import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../data/services/mobile_ads_service.dart';
import '../providers/monetization_notifier.dart';
import '../providers/telemetry_provider.dart';

/// Load only while this placement is visible on the current route. No ad is
/// requested in a background tab, game round, or off-screen list cell.
class AdaptiveBanner extends ConsumerStatefulWidget {
  const AdaptiveBanner({super.key});
  @override
  ConsumerState<AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends ConsumerState<AdaptiveBanner>
    with WidgetsBindingObserver {
  BannerAd? _ad;
  bool _loaded = false, _loading = false;
  int _width = 0;
  ScrollPosition? _position;
  Timer? _retry;
  StreamSubscription<void>? _privacy;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _position) {
      _position?.removeListener(_visibility);
      _position = next;
      next?.addListener(_visibility);
    }
  }

  bool get _visible {
    if (!mounted ||
        !(ModalRoute.of(context)?.isCurrent ?? false) ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.inactive) {
      return false;
    }
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return false;
    final area = box.localToGlobal(Offset.zero) & box.size;
    return (Offset.zero & MediaQuery.sizeOf(context)).overlaps(area);
  }

  void _visibility() {
    if (!mounted) return;
    if (!_visible) {
      _clear();
      return;
    }
    if (!_loaded && !_loading && _ad == null && _retry == null) {
      unawaited(_load());
    }
  }

  void _clear({bool rebuild = true}) {
    _ad?.dispose();
    _ad = null;
    if (_loaded && mounted && rebuild) {
      setState(() => _loaded = false);
    } else {
      _loaded = false;
    }
  }

  Future<void> _load() async {
    final service = ref.read(monetizationServiceProvider);
    if (service is! VerifiedMobileAdsService || _width < 1) return;
    _loading = true;
    try {
      _privacy ??= service.privacyChanges.listen((_) {
        _clear();
        _visibility();
      });
      await service.initialize();
      if (!mounted ||
          !_visible ||
          !service.ready ||
          service.privacyUpdating ||
          !await ConsentInformation.instance.canRequestAds()) {
        return;
      }
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(_width);
      if (size == null || !mounted || !_visible) return;
      final telemetry = ref.read(productTelemetryProvider);
      telemetry.record('ad_load_started', properties: {'placement': 'banner'});
      late final BannerAd ad;
      ad = BannerAd(
        adUnitId: service.ads.bannerUnit,
        size: size,
        request: const AdRequest(nonPersonalizedAds: true),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (!mounted || !_visible) {
              ad.dispose();
              if (_ad == ad) _ad = null;
              return;
            }
            setState(() => _loaded = true);
          },
          onAdFailedToLoad: (failed, _) {
            telemetry.record(
              'ad_load_failed',
              properties: {'placement': 'banner'},
            );
            failed.dispose();
            if (_ad == failed) _ad = null;
            if (!mounted) return;
            _retry = Timer(const Duration(seconds: 60), () {
              _retry = null;
              _visibility();
            });
          },
          onAdImpression: (_) =>
              telemetry.record('ad_shown', properties: {'placement': 'banner'}),
          onPaidEvent: (_, micros, precision, currency) => telemetry.record(
            'ad_value',
            properties: {
              'placement': 'banner',
              'value_micros': micros.round(),
              'precision': precision.name,
              'currency': currency,
            },
          ),
        ),
      );
      _ad = ad;
      await ad.load();
    } catch (_) {
      _clear();
    } finally {
      _loading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visibility();
  }

  @override
  void dispose() {
    _privacy?.cancel();
    _retry?.cancel();
    _position?.removeListener(_visibility);
    WidgetsBinding.instance.removeObserver(this);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final width = c.maxWidth.floor();
      if (width != _width) {
        _width = width;
        _clear(rebuild: false);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _visibility();
      });
      final ad = _ad;
      return SizedBox(
        height: _loaded && ad != null ? ad.size.height.toDouble() : 60,
        child: _loaded && ad != null
            ? Center(
                child: SizedBox(
                  width: ad.size.width.toDouble(),
                  height: ad.size.height.toDouble(),
                  child: AdWidget(ad: ad),
                ),
              )
            : null,
      );
    },
  );
}
