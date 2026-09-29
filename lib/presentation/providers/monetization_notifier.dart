import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/daily_selector.dart';
import '../../data/services/disabled_monetization_service.dart';
import '../../domain/entities/monetization.dart';
import '../../domain/repositories/app_meta_repository.dart';
import '../../domain/services/monetization_service.dart';
import 'providers.dart';

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
          .clamp(0, MonetizationPolicy.rewardedDailyLimit);

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

  MonetizationNotifier({
    required MonetizationService service,
    required AppMetaRepository meta,
    required Future<void> Function(int amount) creditTickets,
  })  : _service = service,
        _meta = meta,
        _creditTickets = creditTickets,
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
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, hasError: true);
    }
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
      await _service.purchasePass();
      await _refreshPass();
    } catch (_) {
      if (mounted) state = state.copyWith(busy: false, hasError: true);
    }
  }

  Future<void> restorePass() async {
    if (!state.storeAvailable || state.busy) return;
    state = state.copyWith(busy: true, hasError: false);
    try {
      await _service.restorePass();
      await _refreshPass();
    } catch (_) {
      if (mounted) state = state.copyWith(busy: false, hasError: true);
    }
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
  );
});
