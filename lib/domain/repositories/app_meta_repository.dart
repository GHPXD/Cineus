/// Small persisted key/value store for app-level flags and preferences.
///
/// Backed by the `app_meta` table that already carried the catalogue version.
abstract class AppMetaRepository {
  /// Whether the player has already been through the how-to-play screen.
  Future<bool> hasSeenOnboarding();
  Future<void> markOnboardingSeen();

  Future<String?> read(String key);
  Future<void> write(String key, String value);
}
