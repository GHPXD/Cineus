/// Font family names, matching the `fonts:` declarations in `pubspec.yaml`.
///
/// These are bundled assets, not runtime downloads. Referencing a family by a
/// name that is not declared makes Flutter fall back to the platform font
/// silently, so always go through these constants rather than raw strings.
abstract final class AppFonts {
  /// Titles, branding, poster. Weights 700/800/900, normal + italic.
  static const playfair = 'Playfair Display';

  /// UI, body copy, clue texts. Weights 400/500/600/700/800, italic at 400.
  static const inter = 'Inter';

  /// Scores, counters, countdown. Weights 400/500 — heavier weights resolve to
  /// the nearest available (500), which is what the upstream family offers.
  static const mono = 'DM Mono';
}
