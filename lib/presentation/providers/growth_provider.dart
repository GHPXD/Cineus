import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/growth_gateway.dart';
import 'commercial_provider.dart';
import 'app_clock.dart';
import '../../data/services/paid_ticket_wallet.dart';
import 'providers.dart';
import 'audience_provider.dart';
import '../../data/repositories/economy_repository.dart';
import '../../core/utils/daily_selector.dart';

final trustedTimeProvider = appTrustedTimeProvider;
final growthGatewayProvider = Provider<GrowthGateway?>((ref) {
  final sync = ref.watch(commerceSynchronizerProvider);
  return sync == null ? null : GrowthGateway(sync);
});
final paidTicketWalletProvider = Provider<PaidTicketWallet?>((ref) {
  final gateway = ref.watch(growthGatewayProvider);
  return gateway == null
      ? null
      : PaidTicketWallet(ref.read(databaseProvider), gateway);
});
final economyRepositoryProvider = Provider(
  (ref) => EconomyRepository(ref.read(databaseProvider)),
);
final stageEconomyProvider = FutureProvider.family<int, (String, int)>((
  ref,
  args,
) {
  final economy = ref.read(economyRepositoryProvider),
      config = ref.read(growthConfigurationProvider);
  return economy.pin(args.$1, args.$2, config.stageBonus);
});

class GrowthConfiguration {
  final String variant;
  final int stageBonus;
  final bool bannerHoldout;
  final bool ready;
  const GrowthConfiguration({
    this.variant = 'control',
    this.stageBonus = 10,
    this.bannerHoldout = false,
    this.ready = false,
  });
  factory GrowthConfiguration.parse(Map<String, dynamic> j) {
    if (!{'control', 'economy_v2'}.contains(j['variant']) ||
        j['config_version'] != 1 ||
        j['daily_tickets'] != 10 ||
        j['banner_holdout'] is! bool ||
        j['stage_bonus'] != (j['variant'] == 'economy_v2' ? 4 : 10)) {
      throw const FormatException('Unsafe economy configuration');
    }
    return GrowthConfiguration(
      ready: true,
      variant: j['variant'],
      stageBonus: j['stage_bonus'] as int,
      bannerHoldout: j['banner_holdout'] as bool,
    );
  }
}

final growthConfigurationProvider = StateProvider(
  (_) => const GrowthConfiguration(),
);

final bootstrapGrowthProvider = Provider<Future<void> Function()>((ref) {
  final gateway = ref.watch(growthGatewayProvider),
      clock = ref.read(trustedTimeProvider);
  var active = true;
  ref.onDispose(() => active = false);
  return () async {
    if (ref.read(playerAudienceProvider).valueOrNull?.canMeasureCommerce !=
        true) {
      return;
    }
    if (gateway == null) return;
    final value = await gateway.command('bootstrap');
    clock.accept(value['_server_time'] as int);
    final config = GrowthConfiguration.parse(value);
    if (active) {
      ref.read(growthConfigurationProvider.notifier).state = config;
      ref.read(dailyDateProvider.notifier).state = DailySelector.todayKey(
        clock.now(),
      );
    }
  };
});
