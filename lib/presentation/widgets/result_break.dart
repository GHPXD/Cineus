import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/interstitial_repository.dart';
import '../../data/services/mobile_ads_service.dart';
import '../../data/services/native_commercial_store.dart';
import '../../domain/entities/commercial_product.dart';
import '../providers/providers.dart';
import '../providers/app_clock.dart';
import '../providers/commercial_provider.dart';
import '../providers/monetization_notifier.dart';

final interstitialPolicyProvider = Provider<InterstitialRepository?>((ref) {
  final c = ref.watch(commercialConfigurationProvider);
  if (!c.interstitials ||
      !const bool.fromEnvironment('CINEUS_INTERSTITIAL_APPROVED')) {
    return null;
  }
  return InterstitialRepository(
    ref.read(databaseProvider),
    ref.read(appClockProvider),
  );
});

/// No timer. Reading a result never triggers an ad.
class ResultBreak extends StatelessWidget {
  final String? gameKey;
  final Widget child;
  const ResultBreak({super.key, required this.gameKey, required this.child});
  @override
  Widget build(BuildContext context) => child;
}

Future<void> maybeShowResultBreak(
  WidgetRef ref,
  String? key, {
  required bool Function() isCurrent,
}) async {
  if (key == null) return;
  final policy = ref.read(interstitialPolicyProvider);
  if (policy == null) return;
  final service = ref.read(monetizationServiceProvider);
  if (service is! VerifiedMobileAdsService || !service.interstitialReady) {
    return;
  }
  final store = ref.read(commercialStoreProvider);
  final sync = ref.read(commerceSynchronizerProvider);
  final clock = ref.read(appClockProvider);
  bool usable() =>
      isCurrent() &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
      !(store is NativeCommercialStore && store.verificationPending);
  if (sync == null || !usable()) return;
  var reserved = false;
  try {
    final fresh = await sync.synchronize();
    if (fresh == null || !sync.lastRefreshSucceeded || !usable()) return;
    bool paid() =>
        sync.current?.grants.any(
          (g) =>
              g.activeAt(clock().toUtc().millisecondsSinceEpoch ~/ 1000) &&
              (CommercialCatalog.byId(
                    g.product,
                  )?.benefits.contains(CommercialBenefit.removeInterruptions) ??
                  false),
        ) ??
        true;
    if (paid()) return;
    reserved = await policy.reserve(
      key,
      rightsKnown: true,
      paid: false,
      ready: service.interstitialReady,
    );
    if (!reserved || !usable() || paid()) return;
    await service.showInterstitial(onShown: () => policy.shown(key));
  } catch (_) {
    // An unavailable ad never blocks navigation.
  } finally {
    if (reserved) await policy.cancel(key);
  }
}
