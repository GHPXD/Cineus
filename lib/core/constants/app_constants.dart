abstract final class AppConstants {
  static const String dbName = 'cineus.db';

  /// Schema version. Bumping this runs `DatabaseHelper._onUpgrade`, which
  /// re-runs the idempotent `ensure*` migrations.
  static const int dbVersion = 1;

  /// Version of the bundled catalogue (movies + clues).
  ///
  /// BUMP THIS whenever `assets/cineus_v1_seed.json` changes. On the next
  /// launch the content tables are refreshed from the asset while player data
  /// (sessions, stage progress, tickets) is left untouched.
  ///
  /// Without this, the asset database was only ever copied when no local file
  /// existed, so an updated catalogue never reached anyone who already had the
  /// app installed.
  static const int contentVersion = 1;

  /// The first day of challenges (epoch).
  ///
  /// MUST be UTC: the whole app defines "day" in UTC so every player gets the
  /// same movie at the same instant. Using a local DateTime here silently
  /// shifted every challenge number by one in negative UTC offsets, because
  /// `difference` compares absolute instants, not calendar dates.
  static final DateTime challengeEpoch = DateTime.utc(2025, 1, 1);

  /// Total clues per movie.
  static const int totalClues = 10;

  /// Starting score (with 1 clue revealed).
  static const int maxScore = 10;

  /// Number of films per stage group.
  static const int stageSize = 10;

  /// Visual game total reveal levels.
  static const int visualLevels = 5;

  /// Max visual game score (guessing at blur level 1).
  static const int maxVisualScore = 5;

  /// A short branded handoff, not an artificial loading screen. Database
  /// bootstrap already owns real startup work and exposes its own progress UI.
  static const Duration splashDuration = Duration(milliseconds: 700);

  /// Search debounce duration.
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// Hash constants for deterministic daily selection.
  static const int dailyHashConstant = 2654435761;
  static const int posterHashConstant = 1640531527;

  /// Shuffle seed multiplier for clue (Dicas) stage lists.
  static const int cluesStageSeed = 1234567891;

  /// Shuffle seed multiplier for poster stage lists (different from clues).
  static const int posterStageSeed = 987654321;
}
