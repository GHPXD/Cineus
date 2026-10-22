/// Bundled posters are 500x750 JPEGs. Encoding changes require a measured visual
/// comparison and a content version update, not a filename-only migration.
abstract final class PosterAssets {
  static const width = 500;
  static const height = 750;
  static String path(int movieId) => 'assets/posters/$movieId.jpg';

  /// Physical pixels, rounded up to shared cache buckets, never above source.
  static int decodeWidth(double logicalWidth, double pixelRatio) {
    if (!logicalWidth.isFinite ||
        logicalWidth <= 0 ||
        !pixelRatio.isFinite ||
        pixelRatio <= 0) {
      return width;
    }
    return ((logicalWidth * pixelRatio / 64).ceil() * 64).clamp(64, width);
  }
}
