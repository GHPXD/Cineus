import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/disabled_product_telemetry.dart';
import '../../domain/services/product_telemetry.dart';

/// Override this provider with the chosen analytics implementation only in a
/// release whose privacy disclosures have been updated accordingly.
final productTelemetryProvider = Provider<ProductTelemetry>((_) {
  return const DisabledProductTelemetry();
});
