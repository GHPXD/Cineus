import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/daily_selector.dart';
import '../../data/services/disabled_monetization_service.dart';
import '../../domain/entities/monetization.dart';
import '../../domain/repositories/app_meta_repository.dart';
import '../../domain/services/monetization_service.dart';
import '../../domain/services/product_telemetry.dart';
import 'providers.dart';
import 'telemetry_provider.dart';

class MonetizationState {
  final bool isLoading;
  final bool busy;
  final bool rewardedAvailable;
  final bool storeAvailable;
  final bool passActive;
  final String? passDisplayPrice;
  final int rewardedUsedToday;
  final bool hasError;

  const MonetizationState({
    this.isLoading = true,
    this.busy = false,
    this.rewardedAvailable = false,
    this.storeAvailable = false,
    this.passActive = false,
    this.passDisplayPrice,
    this.rewardedUsedToday = 0,
    this.hasError = false,
  });

  int get rewardedRemaining =>
      (MonetizationPolicy.rewardedDailyLimit - rewardedUsedToday)
          .clamp(0, MonetizationPolicy.rewardedDailyLimit)
          .toInt();

  bool get canWatchRewarded =>
      rewardedAvailable && !busy && rewardedRemaining > 0;

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
  Timer? _dailyResetTimer;

  MonetizationNotifier({
    required MonetizationService service,
    required AppMetaRepository meta,
    required Future<void> Function(int amount) creditTickets,
    required ProductTelemetry telemetry,
  })  : _service = service,
        _meta = meta,
        _creditTickets = creditTickets,
        _telemetry = telemetry,
        super(const MonetizationState()) {
    load();
  }

  Future<int> _loadRewardedCount() async {
    final today = DailySelector.todayKey();
    final storedDate = await _meta.read(_rewardedDateKey);
    if (storedDate != today) {
      await _meta.write(_rewardedDateKey, today);
      await _meta.write(_rewardedCountKey, '0');
      return 0;
    }
    return int.tryParse(await _meta.read(_rewardedCountKey) ?? '') ?? 0;
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      await _service.initialize();
      final rewarded = await _service.isRewardedAvailable();
      final pass = await _service.loadPassEntitlement();
      final used = await _loadRewardedCount();
      if (!mounted) return;
      state = MonetizationState(
        isLoading: false,
        rewardedAvailable: rewarded,
        storeAvailable: pass.storeAvailable,
        passActive: pass.active,
        passDisplayPrice: pass.displayPrice,
        rewardedUsedToday: used,
      );
      _scheduleDailyReset();
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, hasError: true);
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

  Future<bool> watchRewardedForTickets() async {
    if (!state.canWatchRewarded) return false;
    state = state.copyWith(busy: true, hasError: false);
    try {
      final rewarded = await _service.showRewarded();
      if (!rewarded) {
        if (mounted) state = state.copyWith(busy: false);
        return false;
      }

      await _creditTickets(MonetizationPolicy.rewardedTicketAmount);
      await _telemetry.track(
        'rewarded_completed',
        properties: {
          'reward': 'tickets',
          'amount': MonetizationPolicy.rewardedTicketAmount,
        },
      );
      final next = state.rewardedUsedToday + 1;
      await _meta.write(_rewardedDateKey, DailySelector.todayKey());
      await _meta.write(_rewardedCountKey, '$next');

      if (mounted) {
        state = state.copyWith(
          busy: false,
          rewardedUsedToday: next,
        );
      }
      return true;
    } catch (_) {
      if (mounted) {
        state = state.copyWith(busy: false, hasError: true);
      }
      return false;
    }
  }

  Future<void> purchasePass() async {
    if (!state.storeAvailable || state.busy) return;
    state = state.copyWith(busy: true, hasError: false);
    try {
      await _telemetry.track('pass_purchase_started');
      await _service.purchasePass();
      await _refreshPass();
      if (state.passActive) {
        await _telemetry.track('pass_entitlement_active');
      }
    } catch (_) {
      if (mounted) state = state.copyWith(busy: false, hasError: true);
    }
  }

  Future<void> restorePass() async {
    if (!state.storeAvailable || state.busy) return;
    state = state.copyWith(busy: true, hasError: false);
    try {
      await _telemetry.track('pass_restore_started');
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

final monetizationServiceProvider = Provider<MonetizationService>((_) {
  return const DisabledMonetizationService();
});

final monetizationNotifierProvider =
    StateNotifierProvider<MonetizationNotifier, MonetizationState>((ref) {
  return MonetizationNotifier(
    service: ref.read(monetizationServiceProvider),
    meta: ref.read(appMetaRepositoryProvider),
    creditTickets: (amount) =>
        ref.read(ticketNotifierProvider.notifier).addTickets(amount),
    telemetry: ref.read(productTelemetryProvider),
  );
});
