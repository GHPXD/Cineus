import 'dart:async';
import 'audience_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/daily_selector.dart';
import '../../data/services/disabled_monetization_service.dart';
import '../../data/services/configured_monetization_service.dart';
import '../../domain/entities/monetization.dart';
import '../../domain/repositories/app_meta_repository.dart';
import '../../domain/services/monetization_service.dart';
import 'providers.dart';
import 'telemetry_provider.dart';
import 'commercial_provider.dart';
import '../../data/services/mobile_ads_service.dart';
import 'rewarded_help_provider.dart';

final mobileAdsConfigurationProvider = Provider<MobileAdsConfiguration>(
  (ref) => MobileAdsConfiguration.fromBuild().forAudience(
    ref.watch(playerAudienceProvider).valueOrNull,
  ),
);

final hideVideoOffersProvider = FutureProvider<bool>(
  (ref) async =>
      await ref
          .read(appMetaRepositoryProvider)
          .read('hide_optional_video_offers') ==
      '1',
);

final rewardedConfigurationReadyProvider = Provider<bool>((ref) {
  final configuration = ref.watch(commercialConfigurationProvider);
  return configuration.rewarded &&
      ref.watch(commerceSynchronizerProvider) != null &&
      ref.watch(mobileAdsConfigurationProvider).enabled(configuration);
});

class MonetizationState {
  final bool isLoading;
  final bool busy;
  final bool rewardedAvailable;
  final bool storeAvailable;
  final bool passActive;
  final String? passDisplayPrice;
  final int rewardedUsedToday;
  final bool hasError;
  final bool rewardPending;

  const MonetizationState({
    this.isLoading = true,
    this.busy = false,
    this.rewardedAvailable = false,
    this.storeAvailable = false,
    this.passActive = false,
    this.passDisplayPrice,
    this.rewardedUsedToday = 0,
    this.hasError = false,
    this.rewardPending = false,
  });

  int get rewardedRemaining =>
      (MonetizationPolicy.rewardedDailyLimit - rewardedUsedToday)
          .clamp(0, MonetizationPolicy.rewardedDailyLimit)
          .toInt();

  bool get canWatchRewarded =>
      rewardedAvailable &&
      !isLoading &&
      !busy &&
      !rewardPending &&
      rewardedRemaining > 0;

  MonetizationState copyWith({
    bool? isLoading,
    bool? busy,
    bool? rewardedAvailable,
    bool? storeAvailable,
    bool? passActive,
    String? passDisplayPrice,
    bool clearPassDisplayPrice = false,
    int? rewardedUsedToday,
    bool? hasError,
    bool? rewardPending,
  }) {
    return MonetizationState(
      isLoading: isLoading ?? this.isLoading,
      busy: busy ?? this.busy,
      rewardedAvailable: rewardedAvailable ?? this.rewardedAvailable,
      storeAvailable: storeAvailable ?? this.storeAvailable,
      passActive: passActive ?? this.passActive,
      passDisplayPrice: clearPassDisplayPrice
          ? null
          : (passDisplayPrice ?? this.passDisplayPrice),
      rewardedUsedToday: rewardedUsedToday ?? this.rewardedUsedToday,
      hasError: hasError ?? this.hasError,
      rewardPending: rewardPending ?? this.rewardPending,
    );
  }
}

class MonetizationNotifier extends StateNotifier<MonetizationState> {
  static const _rewardedDateKey = 'monetization_rewarded_date';
  static const _rewardedCountKey = 'monetization_rewarded_count';

  final MonetizationService _service;
  final AppMetaRepository _meta;
  final Future<void> Function(int amount) _creditTickets;
  final ProductTelemetry _telemetry;
  final Future<bool> Function()? _helpPending;
  Timer? _dailyResetTimer;
  Future<void>? _loading;
  bool _reloadRequested = false;

  MonetizationNotifier({
    required MonetizationService service,
    required AppMetaRepository meta,
    required Future<void> Function(int amount) creditTickets,
    required ProductTelemetry telemetry,
    Future<bool> Function()? helpPending,
  }) : _service = service,
       _meta = meta,
       _creditTickets = creditTickets,
       _telemetry = telemetry,
       _helpPending = helpPending,
       super(const MonetizationState()) {
    load();
  }

  Future<int> _loadRewardedCount() async {
    if (_service is ServerCreditedRewards &&
        (_service as ServerCreditedRewards).creditsRewards) {
      return (_service as ServerCreditedRewards).confirmedUsedToday;
    }
    final today = DailySelector.todayKey();
    final storedDate = await _meta.read(_rewardedDateKey);
    if (storedDate != today) {
      await _meta.write(_rewardedDateKey, today);
      await _meta.write(_rewardedCountKey, '0');
      return 0;
    }
    return int.tryParse(await _meta.read(_rewardedCountKey) ?? '') ?? 0;
  }

  /// SDK availability may change while metadata is still loading. Coalesce
  /// calls, then read once more instead of losing that notification or letting
  /// an older response overwrite a newer one.
  Future<void> load() {
    if (!mounted) return Future<void>.value();
    _reloadRequested = true;
    if (_loading != null) return _loading!;
    final done = Completer<void>();
    _loading = done.future;
    unawaited(_drainLoads(done));
    return done.future;
  }

  Future<void> _drainLoads(Completer<void> done) async {
    try {
      while (mounted && _reloadRequested) {
        _reloadRequested = false;
        await _loadOnce();
      }
    } finally {
      _loading = null;
      done.complete();
    }
  }

  Future<void> _loadOnce() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      await _service.initialize();
      final rewarded = await _service.isRewardedAvailable();
      final pass = await _service.loadPassEntitlement();
      final used = await _loadRewardedCount();
      final pending =
          (await _helpPending?.call() ?? false) ||
          (_service is TrackedRewardedAds &&
              (_service as TrackedRewardedAds).rewardPending);
      if (!mounted) return;
      state = MonetizationState(
        busy: state.busy,
        isLoading: false,
        rewardedAvailable: rewarded,
        storeAvailable: pass.storeAvailable,
        passActive: pass.active,
        passDisplayPrice: pass.displayPrice,
        rewardedUsedToday: used,
        rewardPending: pending,
      );
      _scheduleDailyReset();
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        rewardedAvailable: false,
      );
    }
  }

  void _scheduleDailyReset() {
    _dailyResetTimer?.cancel();
    final untilReset =
        DailySelector.timeUntilNextChallenge() + const Duration(seconds: 1);
    _dailyResetTimer = Timer(untilReset, () {
      if (mounted) unawaited(load());
    });
  }

  bool get canWatchRewarded => state.canWatchRewarded;

  Future<bool> watchRewardedForTickets() async =>
      await _watchRewarded() == RewardedVideoResult.rewarded;

  Future<RewardedVideoResult> watchRewardedForHelp({
    required Future<void> Function(String) onAttempt,
  }) => _watchRewarded(onAttempt: onAttempt);

  Future<RewardedVideoResult> _watchRewarded({
    Future<void> Function(String)? onAttempt,
  }) async {
    if (!state.canWatchRewarded) return RewardedVideoResult.unavailable;
    state = state.copyWith(busy: true, hasError: false);
    try {
      await _telemetry.record('rewarded_requested');
      final rewarded = onAttempt != null && _service is TrackedRewardedAds
          ? await (_service as TrackedRewardedAds).showRewardedTracked(
              onAttempt,
            )
          : await _service.showRewarded();
      if (!rewarded) {
        if (mounted) {
          state = state.copyWith(
            busy: false,
            rewardPending:
                _service is TrackedRewardedAds &&
                (_service as TrackedRewardedAds).rewardPending,
          );
        }
        return _service is TrackedRewardedAds &&
                (_service as TrackedRewardedAds).rewardPending
            ? RewardedVideoResult.pending
            : RewardedVideoResult.cancelled;
      }

      if (_service is! ServerCreditedRewards ||
          !(_service as ServerCreditedRewards).creditsRewards) {
        await _creditTickets(MonetizationPolicy.rewardedTicketAmount);
      }
      await _telemetry.record(
        'rewarded_completed',
        properties: {
          'reward': 'tickets',
          'amount': MonetizationPolicy.rewardedTicketAmount,
        },
      );
      final next =
          _service is ServerCreditedRewards &&
              (_service as ServerCreditedRewards).creditsRewards
          ? (_service as ServerCreditedRewards).confirmedUsedToday
          : state.rewardedUsedToday + 1;
      await _meta.write(_rewardedDateKey, DailySelector.todayKey());
      await _meta.write(_rewardedCountKey, '$next');

      if (mounted) {
        state = state.copyWith(
          busy: false,
          rewardedUsedToday: next,
          rewardPending: false,
        );
      }
      return RewardedVideoResult.rewarded;
    } catch (_) {
      if (mounted) {
        state = state.copyWith(
          busy: false,
          hasError: true,
          rewardPending:
              _service is TrackedRewardedAds &&
              (_service as TrackedRewardedAds).rewardPending,
        );
      }
      return _service is TrackedRewardedAds &&
              (_service as TrackedRewardedAds).rewardPending
          ? RewardedVideoResult.pending
          : RewardedVideoResult.failed;
    }
  }

  Future<void> purchasePass() async {
    if (!state.storeAvailable || state.busy) return;
    state = state.copyWith(busy: true, hasError: false);
    try {
      await _telemetry.record('pass_purchase_started');
      await _service.purchasePass();
      await _refreshPass();
      if (state.passActive) {
        await _telemetry.record('pass_entitlement_active');
      }
    } catch (_) {
      if (mounted) state = state.copyWith(busy: false, hasError: true);
    }
  }

  Future<void> restorePass() async {
    if (!state.storeAvailable || state.busy) return;
    state = state.copyWith(busy: true, hasError: false);
    try {
      await _telemetry.record('pass_restore_started');
      await _service.restorePass();
      await _refreshPass();
    } catch (_) {
      if (mounted) state = state.copyWith(busy: false, hasError: true);
    }
  }

  @override
  void dispose() {
    _dailyResetTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshPass() async {
    final pass = await _service.loadPassEntitlement();
    if (!mounted) return;
    state = state.copyWith(
      busy: false,
      storeAvailable: pass.storeAvailable,
      passActive: pass.active,
      passDisplayPrice: pass.displayPrice,
      clearPassDisplayPrice: pass.displayPrice == null,
    );
  }
}

final Provider<MonetizationService> monetizationServiceProvider =
    Provider<MonetizationService>((ref) {
      final configuration = ref.watch(commercialConfigurationProvider);
      final sync = ref.watch(commerceSynchronizerProvider);
      final ads = ref.watch(mobileAdsConfigurationProvider);
      if (sync != null && ads.enabled(configuration)) {
        final service = VerifiedMobileAdsService(
          ads,
          configuration,
          sync,
          ref.read(productTelemetryProvider),
          availabilityChanged: () {
            if (ref.exists(monetizationNotifierProvider)) {
              unawaited(ref.read(monetizationNotifierProvider.notifier).load());
            }
          },
        );
        ref.onDispose(service.dispose);
        return service;
      }
      return ConfiguredMonetizationService(
        configuration,
        const DisabledMonetizationService(),
      );
    });

final StateNotifierProvider<MonetizationNotifier, MonetizationState>
monetizationNotifierProvider =
    StateNotifierProvider<MonetizationNotifier, MonetizationState>((ref) {
      return MonetizationNotifier(
        service: ref.read(monetizationServiceProvider),
        meta: ref.read(appMetaRepositoryProvider),
        creditTickets: (amount) =>
            ref.read(ticketNotifierProvider.notifier).addTickets(amount),
        telemetry: ref.read(productTelemetryProvider),
        helpPending: ref.read(rewardedHelpRepositoryProvider).hasPending,
      );
    });
