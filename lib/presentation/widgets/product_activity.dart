import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/telemetry_provider.dart';
import '../providers/commercial_provider.dart';
import '../../data/services/native_commercial_store.dart';
import 'result_break.dart';
import '../providers/commerce_content_provider.dart';
import '../providers/growth_provider.dart';
import '../providers/providers.dart';
import '../providers/app_clock.dart';
import '../../data/services/population_telemetry.dart';
import '../../data/services/friendly_challenges.dart';
import '../../data/repositories/editorial_feedback_repository.dart';
import '../providers/reward_recovery_provider.dart';

/// Foreground entries, not an estimate of unique players or paid acquisition.
class ProductActivity extends ConsumerStatefulWidget {
  final Widget child;
  const ProductActivity({super.key, required this.child});
  @override
  ConsumerState<ProductActivity> createState() => _ProductActivityState();
}

class _ProductActivityState extends ConsumerState<ProductActivity>
    with WidgetsBindingObserver {
  void _record() {
    unawaited(_growth());
    unawaited(_content());
    final policy = ref.read(interstitialPolicyProvider);
    if (policy != null) {
      unawaited(policy.foreground().catchError((Object _) {}));
    }
    unawaited(ref.read(productTelemetryProvider).record('app_active'));
    final sync = ref.read(commerceSynchronizerProvider);
    if (sync != null) {
      final store = ref.read(commercialStoreProvider);
      if (store is NativeCommercialStore) {
        unawaited(store.retryPending().catchError((Object _) {}));
      }
      unawaited(
        sync.synchronize().then<void>(
          (_) {},
          onError: (Object error, StackTrace stack) {},
        ),
      );
    }
  }

  Future<void> _growth() async {
    final bootstrap = ref.read(bootstrapGrowthProvider);
    final gateway = ref.read(growthGatewayProvider);
    final tickets = ref.read(ticketNotifierProvider.notifier);
    final telemetry = ref.read(productTelemetryProvider);
    final database = ref.read(databaseProvider);
    final clock = ref.read(appClockProvider);
    final recover = ref.read(recoverGameplayRewardsProvider);
    try {
      await bootstrap();
    } catch (_) {
      /* Keep offline earned rewards available. */
    }
    try {
      await tickets.refreshBalance();
      await recover();
      await tickets.refreshPaidBalance();
      if (telemetry is PopulationTelemetry) await telemetry.flush();
      if (gateway != null) {
        await EditorialFeedbackRepository(database, clock).flush(gateway);
        await FriendlyChallenges(database, gateway).flush();
      }
    } catch (_) {
      /* Optional online operations retry on the next foreground. */
    }
  }

  Future<void> _content() async {
    try {
      final service = await ref.read(commerceContentServiceProvider.future);
      if (service != null) {
        await service.update();
        if (mounted) ref.invalidate(commerceContentProvider);
      }
    } catch (_) {
      /* Keep the last complete release/bundled content. */
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _record();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _record();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
