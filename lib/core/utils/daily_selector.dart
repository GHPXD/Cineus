import '../constants/app_constants.dart';

abstract final class DailySelector {
  /// Returns the challenge number for a given date (1-based).
  static int challengeNumber([DateTime? date]) {
    final d = (date ?? DateTime.now()).toUtc();
    final today = DateTime.utc(d.year, d.month, d.day);
    return today.difference(AppConstants.challengeEpoch).inDays + 1;
  }

  /// Deterministic zero-based catalogue position for the clue challenge.
  static int movieIndexForDate(int totalMovies, [DateTime? date]) {
    if (totalMovies <= 0) {
      throw ArgumentError.value(totalMovies, 'totalMovies', 'must be positive');
    }
    final day = challengeNumber(date);
    final offset = _balancedOffset(date);
    if (offset != null) return _balancedIndex(totalMovies, offset);
    final hash = (day * AppConstants.dailyHashConstant) & 0xFFFFFFFF;
    return hash % totalMovies;
  }

  /// Deterministic zero-based catalogue position for the poster challenge.
  static int posterMovieIndexForDate(int totalMovies, [DateTime? date]) {
    if (totalMovies <= 0) {
      throw ArgumentError.value(totalMovies, 'totalMovies', 'must be positive');
    }
    final day = challengeNumber(date);
    final offset = _balancedOffset(date);
    if (offset != null) {
      return _balancedIndex(
        totalMovies,
        offset + (totalMovies > 1 ? totalMovies ~/ 2 : 0),
      );
    }
    final hash = (day * AppConstants.posterHashConstant) & 0xFFFFFFFF;
    var index = hash % totalMovies;
    if (totalMovies > 1 && index == movieIndexForDate(totalMovies, date)) {
      index = (index + 1) % totalMovies;
    }
    return index;
  }

  /// Compatibility helper for callers/tests using a contiguous 1-based catalog.
  static int movieIdForDate(int totalMovies, [DateTime? date]) =>
      movieIndexForDate(totalMovies, date) + 1;

  /// Compatibility helper for callers/tests using a contiguous 1-based catalog.
  static int posterMovieIdForDate(int totalMovies, [DateTime? date]) =>
      posterMovieIndexForDate(totalMovies, date) + 1;

  static int? _balancedOffset(DateTime? date) {
    final day = dateFromKey(todayKey(date))!;
    final offset = day.difference(DateTime.utc(2026, 10, 20)).inDays;
    return offset >= 0 ? offset : null;
  }

  static final _orders = <int, List<int>>{};
  static int _balancedIndex(int total, int offset) {
    final order = _orders.putIfAbsent(
      total,
      () => shuffleStage(
        List.generate(total, (i) => i),
        20261020,
        AppConstants.posterStageSeed,
      ),
    );
    return order[offset % total];
  }

  /// Returns today's date string in YYYY-MM-DD format (UTC day).
  static String todayKey([DateTime? date]) {
    final d = (date ?? DateTime.now()).toUtc();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Parses a `YYYY-MM-DD` key produced by [todayKey] back into a UTC date.
  static DateTime? dateFromKey(String key) {
    if (!isDailyKey(key)) return null;
    return DateTime.utc(
      int.parse(key.substring(0, 4)),
      int.parse(key.substring(5, 7)),
      int.parse(key.substring(8, 10)),
    );
  }

  static bool isDailyKey(String key) => _dailyKeyPattern.hasMatch(key);

  static final RegExp _dailyKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Returns time remaining until midnight UTC.
  static Duration timeUntilNextChallenge([DateTime? now]) {
    final utcNow = (now ?? DateTime.now()).toUtc();
    final nextUtcMidnight = DateTime.utc(
      utcNow.year,
      utcNow.month,
      utcNow.day,
    ).add(const Duration(days: 1));
    return nextUtcMidnight.difference(utcNow);
  }

  /// Returns a deterministic shuffle of [ids] seeded by [stageId] and
  /// [seedConstant].
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
