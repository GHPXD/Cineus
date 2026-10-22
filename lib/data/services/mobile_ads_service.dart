import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../domain/entities/commercial_configuration.dart';
import '../../domain/entities/monetization.dart';
import '../../domain/services/monetization_service.dart';
import '../../domain/services/product_telemetry.dart';
import 'commerce_synchronizer.dart';
import '../../domain/entities/player_audience.dart';

class MobileAdsConfiguration {
  final String rewardedUnit, interstitialUnit, audience, bannerUnit, nativeUnit;
  final bool reviewed, nativeConfigured;
  const MobileAdsConfiguration({
    required this.rewardedUnit,
    required this.interstitialUnit,
    required this.audience,
    required this.reviewed,
    required this.nativeConfigured,
    this.bannerUnit = '',
    this.nativeUnit = '',
  });
  factory MobileAdsConfiguration.fromBuild() => MobileAdsConfiguration(
    nativeUnit: defaultTargetPlatform == TargetPlatform.iOS
        ? const String.fromEnvironment('CINEUS_ADMOB_IOS_NATIVE')
        : const String.fromEnvironment('CINEUS_ADMOB_ANDROID_NATIVE'),
    bannerUnit: defaultTargetPlatform == TargetPlatform.iOS
        ? const String.fromEnvironment('CINEUS_ADMOB_IOS_BANNER')
        : const String.fromEnvironment('CINEUS_ADMOB_ANDROID_BANNER'),
    rewardedUnit: defaultTargetPlatform == TargetPlatform.iOS
        ? const String.fromEnvironment('CINEUS_ADMOB_IOS_REWARDED')
        : const String.fromEnvironment('CINEUS_ADMOB_ANDROID_REWARDED'),
    interstitialUnit: defaultTargetPlatform == TargetPlatform.iOS
        ? const String.fromEnvironment('CINEUS_ADMOB_IOS_INTERSTITIAL')
        : const String.fromEnvironment('CINEUS_ADMOB_ANDROID_INTERSTITIAL'),
    audience: const String.fromEnvironment('CINEUS_ADS_AUDIENCE'),
    reviewed: const bool.fromEnvironment('CINEUS_ADS_REVIEWED'),
    nativeConfigured: const bool.fromEnvironment(
      'CINEUS_ADMOB_NATIVE_CONFIGURED',
    ),
  );
  MobileAdsConfiguration forAudience(PlayerAudience? player) =>
      MobileAdsConfiguration(
        rewardedUnit: rewardedUnit,
        interstitialUnit: interstitialUnit,
        bannerUnit: bannerUnit,
        nativeUnit: nativeUnit,
        audience: player == PlayerAudience.adult
            ? 'general'
            : player == PlayerAudience.teen ||
                  player == PlayerAudience.unrestricted
            ? 'teen'
            : '',
        reviewed: reviewed,
        nativeConfigured: nativeConfigured,
      );
  bool validUnit(String unit, CommercialEnvironment environment) =>
      RegExp(r'^ca-app-pub-[0-9]{16}/[0-9]{10}$').hasMatch(unit) &&
      (unit.startsWith('ca-app-pub-3940256099942544/') ==
          (environment != CommercialEnvironment.production));
  bool enabled(CommercialConfiguration c) =>
      !kIsWeb &&
      {
        TargetPlatform.android,
        TargetPlatform.iOS,
      }.contains(defaultTargetPlatform) &&
      reviewed &&
      nativeConfigured &&
      {'general', 'teen', 'child'}.contains(audience) &&
      ((c.rewarded && validUnit(rewardedUnit, c.environment)) ||
          (c.interstitials && validUnit(interstitialUnit, c.environment)) ||
          (c.banners && validUnit(bannerUnit, c.environment)) ||
          (c.nativeAds && validUnit(nativeUnit, c.environment)));
}

/// A native reward event is only a hint to poll. The signed server receipt is
/// applied by CommerceSynchronizer; this service never changes a ticket balance.
class VerifiedMobileAdsService
    implements MonetizationService, ServerCreditedRewards, TrackedRewardedAds {
  final MobileAdsConfiguration ads;
  final CommercialConfiguration configuration;
  final CommerceSynchronizer synchronizer;
  final ProductTelemetry telemetry;
  final void Function() availabilityChanged;
  final _privacyChanges = StreamController<void>.broadcast();
  Stream<void> get privacyChanges => _privacyChanges.stream;
  bool privacyUpdating = false;
  RewardedAd? _rewarded;
  bool _rewardPending = false;
  String? _pendingAttempt;
  @override
  bool get rewardPending => _rewardPending;
  InterstitialAd? _interstitial;
  DateTime? _rewardedLoadedAt, _interstitialLoadedAt;
  Future<void>? _initializing;
  bool ready = false,
      _loadingRewarded = false,
      _loadingInterstitial = false,
      _showing = false,
      _disposed = false;
  VerifiedMobileAdsService(
    this.ads,
    this.configuration,
    this.synchronizer,
    this.telemetry, {
    required this.availabilityChanged,
  });
  @override
  bool get creditsRewards => true;
  @override
  int get confirmedUsedToday {
    final current = synchronizer.current;
    if (current == null) return 0;
    final issued = DateTime.fromMillisecondsSinceEpoch(
      current.issuedAt * 1000,
      isUtc: true,
    );
    final now = DateTime.now().toUtc();
    return issued.year == now.year &&
            issued.month == now.month &&
            issued.day == now.day
        ? current.rewardedUsedToday
        : 0;
  }

  @override
  Future<void> initialize() =>
      _initializing ??= _initialize().whenComplete(() => _initializing = null);
  Future<void> _initialize() async {
    if (_disposed || !ads.enabled(configuration)) return;
    if (!ready) {
      final consent = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(
          tagForUnderAgeOfConsent: ads.audience != 'general',
        ),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {
            if (!consent.isCompleted) consent.complete();
          });
        },
        (_) {
          if (!consent.isCompleted) consent.complete();
        },
      );
      await consent.future.timeout(const Duration(seconds: 30));
      if (!await ConsentInformation.instance.canRequestAds() || _disposed) {
        return;
      }
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.g,
          ageRestrictedTreatment: ads.audience == 'child'
              ? AgeRestrictedTreatment.child
              : ads.audience == 'teen'
              ? AgeRestrictedTreatment.teen
              : AgeRestrictedTreatment.unspecified,
        ),
      );
      await MobileAds.instance.initialize();
      ready = true;
    }
    await synchronizer.synchronize();
    if (_pendingAttempt != null &&
        synchronizer.identity != null &&
        await synchronizer.cache.isRewardCredited(
          synchronizer.identity!,
          _pendingAttempt!,
        )) {
      _rewardPending = false;
      _pendingAttempt = null;
    }
    _preloadRewarded();
    _preloadInterstitial();
  }

  void _preloadRewarded() {
    _expire();
    if (!ready ||
        _disposed ||
        _rewarded != null ||
        _loadingRewarded ||
        !configuration.rewarded ||
        !ads.validUnit(ads.rewardedUnit, configuration.environment) ||
        confirmedUsedToday >= 3) {
      return;
    }
    _loadingRewarded = true;
    telemetry.record('ad_load_started', properties: {'placement': 'rewarded'});
    RewardedAd.load(
      adUnitId: ads.rewardedUnit,
      request: const AdRequest(nonPersonalizedAds: true),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingRewarded = false;
          if (_disposed) {
            ad.dispose();
            return;
          }
          _rewarded = ad;
          _rewardedLoadedAt = DateTime.now();
          _trackValue(ad, 'rewarded');
          availabilityChanged();
          telemetry.record(
            'ad_available',
            properties: {'placement': 'rewarded'},
          );
        },
        onAdFailedToLoad: (_) {
          _loadingRewarded = false;
          telemetry.record(
            'ad_load_failed',
            properties: {'placement': 'rewarded'},
          );
        },
      ),
    );
  }

  void _preloadInterstitial() {
    _expire();
    if (!ready ||
        _disposed ||
        _interstitial != null ||
        _loadingInterstitial ||
        !configuration.interstitials ||
        !const bool.fromEnvironment('CINEUS_INTERSTITIAL_APPROVED') ||
        !ads.validUnit(ads.interstitialUnit, configuration.environment)) {
      return;
    }
    _loadingInterstitial = true;
    telemetry.record(
      'ad_load_started',
      properties: {'placement': 'interstitial'},
    );
    InterstitialAd.load(
      adUnitId: ads.interstitialUnit,
      request: const AdRequest(nonPersonalizedAds: true),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loadingInterstitial = false;
          if (_disposed) {
            ad.dispose();
            return;
          }
          _interstitial = ad;
          _interstitialLoadedAt = DateTime.now();
          _trackValue(ad, 'interstitial');
        },
        onAdFailedToLoad: (_) {
          _loadingInterstitial = false;
          telemetry.record(
            'ad_load_failed',
            properties: {'placement': 'interstitial'},
          );
        },
      ),
    );
  }

  void _trackValue(AdWithoutView ad, String placement) {
    var recorded = false;
    ad.onPaidEvent = (_, micros, precision, currency) {
      if (recorded || !micros.isFinite || micros < 0) return;
      recorded = true;
      telemetry.record(
        'ad_value',
        properties: {
          'placement': placement,
          'value_micros': micros.round(),
          'precision': precision.name,
          'currency': currency,
        },
      );
    };
  }

  void _expire() {
    final now = DateTime.now();
    if (_rewardedLoadedAt != null &&
        now.difference(_rewardedLoadedAt!) >= const Duration(minutes: 50)) {
      _rewarded?.dispose();
      _rewarded = null;
      _rewardedLoadedAt = null;
    }
    if (_interstitialLoadedAt != null &&
        now.difference(_interstitialLoadedAt!) >= const Duration(minutes: 50)) {
      _interstitial?.dispose();
      _interstitial = null;
      _interstitialLoadedAt = null;
    }
  }

  @override
  Future<bool> isRewardedAvailable() async {
    if (ready && !await ConsentInformation.instance.canRequestAds()) {
      return false;
    }
    _preloadRewarded();
    return ready && _rewarded != null && !_showing && confirmedUsedToday < 3;
  }

  @override
  Future<bool> showRewarded() => _showRewarded();

  @override
  Future<bool> showRewardedTracked(Future<void> Function(String) started) =>
      _showRewarded(started: started);

  Future<bool> _showRewarded({Future<void> Function(String)? started}) async {
    _rewardPending = false;
    if (!await isRewardedAvailable()) return false;
    _showing = true;
    RewardedAd? ad;
    try {
      await synchronizer.synchronize();
      final identity = synchronizer.identity!;
      final attempt = await synchronizer.gateway.startReward(identity);
      await started?.call(attempt['attempt_id'] as String);
      ad = _rewarded;
      if (ad == null) return false;
      _rewarded = null;
      await ad.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: identity.owner,
          customData: attempt['attempt_id'] as String,
        ),
      );
      var earned = false;
      final closed = Completer<void>();
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (_) {
          if (!closed.isCompleted) closed.complete();
        },
        onAdFailedToShowFullScreenContent: (_, __) {
          if (!closed.isCompleted) closed.complete();
        },
      );
      await telemetry.record('ad_shown', properties: {'placement': 'rewarded'});
      await ad.show(
        onUserEarnedReward: (_, __) {
          telemetry.record('video_completed');
          earned = true;
          _rewardPending = true;
          _pendingAttempt = attempt['attempt_id'] as String;
        },
      );
      await closed.future;
      if (!earned) return false;
      for (var i = 0; i < 5; i++) {
        if (i > 0) await Future<void>.delayed(Duration(seconds: i * 2));
        await synchronizer.synchronize();
        if (synchronizer.current!.rewards.any(
          (r) => r.attempt == attempt['attempt_id'],
        )) {
          _rewardPending = false;
          await telemetry.record(
            'reward_credit_delivered',
            properties: {'amount': 2},
          );
          return true;
        }
      }
      telemetry.record('reward_verification_pending');
      return false; // Later SSV still recovers through foreground synchronization.
    } finally {
      await ad?.dispose();
      _showing = false;
      _preloadRewarded();
    }
  }

  bool get interstitialReady {
    _expire();
    return ready && !_showing && _interstitial != null;
  }

  Future<bool> showInterstitial({Future<void> Function()? onShown}) async {
    if (!interstitialReady ||
        !await ConsentInformation.instance.canRequestAds()) {
      return false;
    }
    final ad = _interstitial!;
    _interstitial = null;
    _showing = true;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        if (onShown != null) unawaited(onShown().catchError((Object _) {}));
        telemetry.record('ad_shown', properties: {'placement': 'interstitial'});
      },
      onAdDismissedFullScreenContent: (_) {
        if (!done.isCompleted) done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (_, __) {
        if (!done.isCompleted) done.complete(false);
      },
    );
    try {
      await ad.show();
      return await done.future;
    } finally {
      await ad.dispose();
      _showing = false;
      _preloadInterstitial();
    }
  }

  Future<bool> privacyOptionsRequired() async =>
      ready &&
      await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
  Future<void> showPrivacyOptions() async {
    if (_disposed) return;
    privacyUpdating = true;
    _privacyChanges.add(null);
    final closed = Completer<void>();
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {
        if (!closed.isCompleted) closed.complete();
      });
      await closed.future;
      await _rewarded?.dispose();
      _rewarded = null;
      await _interstitial?.dispose();
      _interstitial = null;
      if (await ConsentInformation.instance.canRequestAds()) {
        _preloadRewarded();
        _preloadInterstitial();
      }
    } finally {
      privacyUpdating = false;
      if (!_disposed) _privacyChanges.add(null);
    }
  }

  @override
  Future<PassEntitlement> loadPassEntitlement() async =>
      const PassEntitlement();
  @override
  Future<void> purchasePass() async {}
  @override
  Future<void> restorePass() async {}
  void dispose() {
    _disposed = true;
    _rewarded?.dispose();
    _interstitial?.dispose();
    _privacyChanges.close();
  }
}
