import '../../domain/services/product_telemetry.dart';

class DisabledProductTelemetry implements ProductTelemetry {
  const DisabledProductTelemetry();

  @override
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {}
}
