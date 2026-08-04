import '../constants/app_constants.dart';

abstract final class DailySelector {
  /// Returns the challenge number for a given date (1-based).
  static int challengeNumber([DateTime? date]) {
    final d = (date ?? DateTime.now()).toUtc();
    final today = DateTime.utc(d.year, d.month, d.day);
    return today.difference(AppConstants.challengeEpoch).inDays + 1;
  }

  /// Returns the movie ID for a given date deterministically.
  /// All users get the same movie for the same date.
  static int movieIdForDate(int totalMovies, [DateTime? date]) {
    final day = challengeNumber(date);
    final hash = (day * AppConstants.dailyHashConstant) & 0xFFFFFFFF;
    return (hash % totalMovies) + 1;
  }

  /// Returns the poster-mode movie ID for a given date.
  /// Uses a different hash constant than [movieIdForDate] so the two daily
  /// challenges always feature different movies.
  static int posterMovieIdForDate(int totalMovies, [DateTime? date]) {
    final day = challengeNumber(date);
    final hash = (day * AppConstants.posterHashConstant) & 0xFFFFFFFF;
    var id = (hash % totalMovies) + 1;
    // Guarantee it differs from the clue-game movie for the same day.
    if (id == movieIdForDate(totalMovies, date)) {
      id = (id % totalMovies) + 1;
    }
    return id;
  }

  /// Returns today's date string in YYYY-MM-DD format (UTC day).
  static String todayKey([DateTime? date]) {
    final d = (date ?? DateTime.now()).toUtc();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Parses a `YYYY-MM-DD` key produced by [todayKey] back into a UTC date.
  /// Returns null when [key] is not a plain daily key (e.g. `stage_1_5`).
  static DateTime? dateFromKey(String key) {
    if (!isDailyKey(key)) return null;
    return DateTime.utc(
      int.parse(key.substring(0, 4)),
      int.parse(key.substring(5, 7)),
      int.parse(key.substring(8, 10)),
    );
  }

  /// True when [key] is a plain daily-challenge key (`YYYY-MM-DD`) rather than
  /// one of the prefixed keys used by the other game modes.
  static bool isDailyKey(String key) => _dailyKeyPattern.hasMatch(key);

  static final RegExp _dailyKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Returns time remaining until the next challenge, i.e. until midnight UTC.
  ///
  /// Must stay in UTC to match [todayKey]: using local midnight made the
  /// countdown disagree with the actual rollover by the timezone offset.
  static Duration timeUntilNextChallenge([DateTime? now]) {
    final utcNow = (now ?? DateTime.now()).toUtc();
    final nextUtcMidnight = DateTime.utc(utcNow.year, utcNow.month, utcNow.day)
        .add(const Duration(days: 1));
    return nextUtcMidnight.difference(utcNow);
  }

  /// Returns a deterministic shuffle of [ids] seeded by [stageId] and [seedConstant].
  /// Uses a simple LCG so the order is stable and reproducible across launches,
  /// but differs between clue stages (use [AppConstants.cluesStageSeed]) and
  /// poster stages (use [AppConstants.posterStageSeed]).
  static List<int> shuffleStage(List<int> ids, int stageId, int seedConstant) {
    final list = List<int>.from(ids);
    var seed = ((stageId * seedConstant) ^ 0xDEADBEEF) & 0x7FFFFFFF;
    for (var i = list.length - 1; i > 0; i--) {
      seed = (seed * 1664525 + 1013904223) & 0x7FFFFFFF;
      final j = seed % (i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
    return list;
  }
}
