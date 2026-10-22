import '../../core/utils/daily_selector.dart';
import 'game_session.dart';

/// Published movie IDs, independent of catalogue size or active-row ordering.
class DailyCalendar {
  final Map<String, Map<GameMode, int>> days;
  final Map<String, List<String>> colors;
  const DailyCalendar(this.days, [this.colors = const {}]);
  factory DailyCalendar.fromJson(Map<String, dynamic> json) {
    if (json['schema'] != 1 || json['version'] != 'calendar-20261020-v1') {
      throw const FormatException('Unsupported daily calendar');
    }
    final days = <String, Map<GameMode, int>>{};
    final colors = <String, List<String>>{};
    for (final raw in (json['days'] as List)) {
      final date = raw['date'] as String;
      final parsed = DailySelector.dateFromKey(date);
      final clue = raw['clue'], poster = raw['poster'];
      if (parsed == null ||
          DailySelector.todayKey(parsed) != date ||
          days.containsKey(date) ||
          clue is! int ||
          poster is! int ||
          clue < 1 ||
          poster < 1 ||
          clue == poster) {
        throw const FormatException('Invalid daily calendar slot');
      }
      days[date] = {GameMode.clue: clue, GameMode.poster: poster};
      if (raw['colors'] != null) {
        final ids = (raw['colors'] as List).cast<String>();
        if (ids.length != 5 || ids.toSet().length != 5) {
          throw const FormatException('Invalid color calendar slot');
        }
        colors[date] = List.unmodifiable(ids);
      }
    }
    return DailyCalendar(Map.unmodifiable(days), Map.unmodifiable(colors));
  }
  int? movie(GameMode mode, String date) => days[date]?[mode];
}
