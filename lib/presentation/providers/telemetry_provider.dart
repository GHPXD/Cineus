import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/population_telemetry.dart';
import '../../data/services/disabled_product_telemetry.dart';
import '../../domain/services/product_telemetry.dart';
import 'commercial_provider.dart';
import 'providers.dart';
import 'app_clock.dart';
import 'growth_provider.dart';
import 'audience_provider.dart';
export '../../domain/services/product_telemetry.dart';

/// Override this provider with the chosen analytics implementation only in a
/// release whose privacy disclosures have been updated accordingly.
final usageDataServiceProvider = Provider<PopulationTelemetry>(
  (ref) => PopulationTelemetry(
    ref.read(databaseProvider),
    ref.read(appClockProvider),
    () =>
        ref.read(playerAudienceProvider).valueOrNull?.canMeasureCommerce == true
        ? ref.read(growthGatewayProvider)
        : null,
    localEnabled:
        ref.watch(commercialConfigurationProvider).localMetrics &&
        ref.watch(playerAudienceProvider).valueOrNull?.canMeasureCommerce ==
            true,
  ),
);

final Provider<ProductTelemetry> productTelemetryProvider =
    Provider<ProductTelemetry>((ref) {
      if (ref.watch(playerAudienceProvider).valueOrNull?.canMeasureCommerce !=
          true) {
        return const DisabledProductTelemetry();
      }
      final local = ref.watch(commercialConfigurationProvider).localMetrics;
      if (!local && !ref.watch(commerceBackendConfigurationProvider).enabled) {
        return const DisabledProductTelemetry();
      }
      return ref.watch(usageDataServiceProvider);
    });
