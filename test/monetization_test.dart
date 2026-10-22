import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/domain/entities/monetization.dart';
import 'package:cineus/domain/repositories/app_meta_repository.dart';
import 'package:cineus/domain/services/monetization_service.dart';
import 'package:cineus/domain/services/product_telemetry.dart';
import 'package:cineus/presentation/providers/monetization_notifier.dart';

class _Meta implements AppMetaRepository {
  final values = <String, String>{};

  @override
  Future<bool> hasSeenOnboarding() async => false;

  @override
  Future<void> markOnboardingSeen() async {}

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class _Service implements MonetizationService {
  bool rewardedAvailable = true;
  bool rewardResult = true;
  bool passActive = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isRewardedAvailable() async => rewardedAvailable;

  @override
  Future<bool> showRewarded() async => rewardResult;

  @override
  Future<PassEntitlement> loadPassEntitlement() async => PassEntitlement(
    storeAvailable: true,
    active: passActive,
    displayPrice: r'R$ 9,90',
  );

  @override
  Future<void> purchasePass() async {
    passActive = true;
  }

  @override
  Future<void> restorePass() async {
    passActive = true;
  }
}

class _Telemetry implements ProductTelemetry {
  final events = <String>[];
  bool fail = false;

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {
    if (fail) throw StateError('Analytics offline');
    events.add(event);
  }
}

Future<void> _settle(MonetizationNotifier notifier) async {
  for (var i = 0; i < 20 && notifier.state.isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _VerifiedService extends _Service implements ServerCreditedRewards {
  int used = 0;
  @override
  bool get creditsRewards => true;
  @override
  int get confirmedUsedToday => used;
  @override
  Future<bool> showRewarded() async {
    used++;
    return true;
  }
}

class _AvailabilityRaceService extends _Service {
  final first = Completer<bool>();
  int reads = 0;
  @override
  Future<bool> isRewardedAvailable() async {
    reads++;
    return reads == 1 ? first.future : true;
  }
}

void main() {
  test(
    'availability update during load is queued instead of dropped or overwritten',
    () async {
      final service = _AvailabilityRaceService();
      final notifier = MonetizationNotifier(
        service: service,
        meta: _Meta(),
        creditTickets: (_) async {},
        telemetry: _Telemetry(),
      );
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);
      expect(service.reads, 1);
      final pending = notifier.load();
      service.first.complete(false);
      await pending;
      expect(service.reads, 2);
      expect(notifier.state.rewardedAvailable, isTrue);
      expect(notifier.state.canWatchRewarded, isTrue);
    },
  );
  test(
    'signed server reward is never credited a second time by the legacy notifier',
    () async {
      var localCredits = 0;
      final service = _VerifiedService();
      final notifier = MonetizationNotifier(
        service: service,
        meta: _Meta(),
        creditTickets: (_) async {
          localCredits++;
        },
        telemetry: _Telemetry(),
      );
      addTearDown(notifier.dispose);
      await _settle(notifier);
      expect(await notifier.watchRewardedForTickets(), isTrue);
      expect(localCredits, 0);
      expect(notifier.state.rewardedUsedToday, 1);
      service.used = 3;
      await notifier.load();
      expect(notifier.state.canWatchRewarded, isFalse);
    },
  );
  test(
    'analytics failure cannot invalidate a reward or prevent a purchase',
    () async {
      var credited = 0;
      final notifier = MonetizationNotifier(
        service: _Service(),
        meta: _Meta(),
        creditTickets: (amount) async => credited += amount,
        telemetry: _Telemetry()..fail = true,
      );
      addTearDown(notifier.dispose);
      await _settle(notifier);
      expect(await notifier.watchRewardedForTickets(), isTrue);
      expect(credited, 2);
      expect(notifier.state.rewardedUsedToday, 1);
      expect(notifier.state.hasError, isFalse);
      await notifier.purchasePass();
      expect(notifier.state.passActive, isTrue);
      expect(notifier.state.hasError, isFalse);
    },
  );

  test('core gameplay is explicitly free and rewarded ads are optional', () {
    expect(MonetizationPolicy.coreGameplayAlwaysFree, isTrue);
    expect(MonetizationPolicy.rewardedAdsAreOptional, isTrue);
    expect(
      MonetizationPolicy.shouldShowNonRewardedAds(passActive: true),
      isFalse,
    );
  });

  test('reward is credited only after the ad confirms completion', () async {
    final service = _Service()..rewardResult = false;
    final telemetry = _Telemetry();
    var credited = 0;
    final notifier = MonetizationNotifier(
      service: service,
      meta: _Meta(),
      creditTickets: (amount) async => credited += amount,
      telemetry: telemetry,
    );
    await _settle(notifier);

    expect(await notifier.watchRewardedForTickets(), isFalse);
    expect(credited, 0);
    expect(telemetry.events, isNot(contains('rewarded_completed')));

    service.rewardResult = true;
    expect(await notifier.watchRewardedForTickets(), isTrue);
    expect(credited, MonetizationPolicy.rewardedTicketAmount);
    expect(telemetry.events, contains('rewarded_completed'));
  });

  test('daily rewarded cap prevents unlimited ticket farming', () async {
    final notifier = MonetizationNotifier(
      service: _Service(),
      meta: _Meta(),
      creditTickets: (_) async {},
      telemetry: _Telemetry(),
    );
    await _settle(notifier);

    for (var i = 0; i < MonetizationPolicy.rewardedDailyLimit; i++) {
      expect(await notifier.watchRewardedForTickets(), isTrue);
    }

    expect(notifier.state.rewardedRemaining, 0);
    expect(notifier.state.canWatchRewarded, isFalse);
    expect(await notifier.watchRewardedForTickets(), isFalse);
  });

  test('Pass entitlement is refreshed after purchase and restore', () async {
    final service = _Service();
    final telemetry = _Telemetry();
    final notifier = MonetizationNotifier(
      service: service,
      meta: _Meta(),
      creditTickets: (_) async {},
      telemetry: telemetry,
    );
    await _settle(notifier);

    expect(notifier.state.storeAvailable, isTrue);
    expect(notifier.state.passActive, isFalse);

    await notifier.purchasePass();
    expect(notifier.state.passActive, isTrue);
    expect(telemetry.events, contains('pass_purchase_started'));
    expect(telemetry.events, contains('pass_entitlement_active'));

    service.passActive = false;
    await notifier.load();
    await notifier.restorePass();
    expect(notifier.state.passActive, isTrue);
    expect(telemetry.events, contains('pass_restore_started'));
  });
}
