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
