import 'game_session.dart';
import 'movie.dart';

/// One row of a breakdown: how the player performs on a slice of the catalogue.
class InsightBucket {
  final String label;
  final int played;
  final int won;

  /// Average score across the wins in this bucket; 0 when there are none.
  final double averageScore;

  const InsightBucket({
    required this.label,
    required this.played,
    required this.won,
    required this.averageScore,
  });

  double get winRate => played == 0 ? 0 : won / played;
}

/// Where the player is strong and where they are not (D8).
///
/// `genres` and `year` were in the catalogue from the start but only ever
/// decorated the poster card. Aggregating them turns finished games into
/// something the player can act on.
class PlayInsights {
  /// Buckets by genre, most played first.
  final List<InsightBucket> byGenre;

  /// Buckets by decade, newest first.
  final List<InsightBucket> byDecade;

  const PlayInsights({this.byGenre = const [], this.byDecade = const []});

  bool get isEmpty => byGenre.isEmpty && byDecade.isEmpty;

  /// Genre with the best win rate among those played at least [minPlayed] times.
  InsightBucket? bestGenre({int minPlayed = 3}) =>
      _extreme(minPlayed, best: true);

  /// Genre with the worst win rate among those played at least [minPlayed] times.
  InsightBucket? worstGenre({int minPlayed = 3}) =>
      _extreme(minPlayed, best: false);

  InsightBucket? _extreme(int minPlayed, {required bool best}) {
    final eligible = byGenre.where((b) => b.played >= minPlayed).toList();
    if (eligible.isEmpty) return null;
    eligible.sort(
      (a, b) => best
          ? b.winRate.compareTo(a.winRate)
          : a.winRate.compareTo(b.winRate),
    );
    return eligible.first;
  }

  /// Builds the breakdowns from finished sessions and the films they used.
  ///
  /// [moviesById] only needs to cover the sessions passed in; anything missing is
  /// skipped rather than guessed at.
  static PlayInsights from(
    List<GameSession> sessions,
    Map<int, Movie> moviesById,
  ) {
    final genreStats = <String, _Tally>{};
    final decadeStats = <int, _Tally>{};

    for (final session in sessions) {
      final movie = moviesById[session.movieId];
      if (movie == null) continue;

      final won = session.status == GameStatus.won;

      for (final raw in movie.genres) {
        final genre = raw.trim();
        if (genre.isEmpty) continue;
        (genreStats[genre] ??= _Tally()).add(won, session.score);
      }

      if (movie.year > 0) {
        final decade = (movie.year ~/ 10) * 10;
        (decadeStats[decade] ??= _Tally()).add(won, session.score);
      }
    }

    final genres =
        genreStats.entries.map((e) => e.value.toBucket(e.key)).toList()
          ..sort((a, b) {
            final byPlayed = b.played.compareTo(a.played);
            return byPlayed != 0 ? byPlayed : a.label.compareTo(b.label);
          });

    final decades =
        decadeStats.entries.map((e) => e.value.toBucket('${e.key}s')).toList()
          ..sort((a, b) => b.label.compareTo(a.label));

    return PlayInsights(byGenre: genres, byDecade: decades);
  }
}

class _Tally {
  int played = 0;
  int won = 0;
  int scoreSum = 0;

  void add(bool isWin, int score) {
    played++;
    if (isWin) {
      won++;
      scoreSum += score;
    }
  }

  InsightBucket toBucket(String label) => InsightBucket(
    label: label,
    played: played,
    won: won,
    averageScore: won == 0 ? 0 : scoreSum / won,
  );
}
