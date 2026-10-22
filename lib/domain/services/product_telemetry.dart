/// Product analytics seam.
///
/// Cineus ships with a no-op implementation by default, so adding event calls
/// does not collect or transmit user data. A real analytics adapter must be
/// explicitly wired for a release and reflected in Privacy/Data Safety forms.
abstract class ProductTelemetry {
  Future<void> track(
    String event, {
    Map<String, Object?> properties = const {},
  });
}

/// Diagnostics must never change the outcome of a persisted gameplay action,
/// purchase, or reward. Also protects callers overriding the provider in tests.
extension BestEffortProductTelemetry on ProductTelemetry {
  Future<void> record(
    String event, {
    Map<String, Object?> properties = const {},
  }) async {
    try {
      await track(event, properties: properties);
    } catch (_) {
      // Revenue and rewards are verified through their own durable records.
    }
  }
}
