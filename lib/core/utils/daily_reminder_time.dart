/// When the daily reminder fires (D4).
///
/// The challenge itself rolls over at midnight UTC, but a reminder at that
/// instant lands at 21:00 in Brasília and 03:00 in much of Europe. The reminder
/// is therefore anchored to the player's *local* morning, which is when a daily
/// game is actually opened.
///
/// Trade-off worth knowing: in zones far ahead of UTC (UTC+13, say) 09:00 local
/// falls late in the UTC day, so the announced challenge expires a few hours
/// later. Everywhere from UTC−11 to about UTC+9 the reminder points at a
/// challenge with most of its life ahead of it.
abstract final class DailyReminderTime {
  /// Local hour the reminder fires. Kept as a constant rather than inlined so the
  /// scheduling code and its tests cannot disagree.
  static const int hour = 9;
  static const int minute = 0;

  /// The next occurrence of [hour]:[minute] strictly after [from].
  ///
  /// Works in whatever zone [from] carries, so callers pass a local timestamp.
  static DateTime nextOccurrence(DateTime from) {
    var candidate = DateTime(from.year, from.month, from.day, hour, minute);
    if (!candidate.isAfter(from)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
