import 'dart:convert';
import 'dart:io';

import 'package:cineus/core/utils/daily_selector.dart';

/// Read-only reproduction using the production selector, not a copied formula.
void main() {
  final end = DateTime.utc(2026, 10, 19);
  const catalogue = 500;
  final results = <Map<String, Object>>[];
  for (final days in [30, 90, 365]) {
    final clues = <int>{};
    final posters = <int>{};
    final lastPoster = <int, int>{};
    int? shortestGap;
    for (var offset = 0; offset < days; offset++) {
      final date = end.subtract(Duration(days: offset));
      clues.add(DailySelector.movieIndexForDate(catalogue, date));
      final poster = DailySelector.posterMovieIndexForDate(catalogue, date);
      posters.add(poster);
      final previous = lastPoster[poster];
      if (previous != null) {
        final gap = offset - previous;
        if (shortestGap == null || gap < shortestGap) shortestGap = gap;
      }
      lastPoster[poster] = offset;
    }
    results.add({
      'window_days': days,
      'clue_unique': clues.length,
      'poster_unique': posters.length,
      'poster_repeat_positions': days - posters.length,
      if (shortestGap != null) 'shortest_repeat_gap': shortestGap,
    });
  }
  stdout.writeln(const JsonEncoder.withIndent('  ').convert(results));
}
