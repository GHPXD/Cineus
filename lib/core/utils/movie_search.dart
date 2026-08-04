import 'string_normalizer.dart';

/// One catalogue entry reduced to what ranking needs: an id and its titles,
/// already passed through [StringNormalizer.normalize].
class SearchCandidate {
  final int id;
  final String titleNorm;
  final String originalNorm;

  const SearchCandidate(this.id, this.titleNorm, this.originalNorm);

  /// Builds a candidate from raw (un-normalized) titles.
  factory SearchCandidate.fromTitles(
    int id,
    String title, [
    String? originalTitle,
  ]) {
    return SearchCandidate(
      id,
      StringNormalizer.normalize(title),
      StringNormalizer.normalize(originalTitle ?? ''),
    );
  }
}

/// Relevance scoring for the movie autocomplete.
///
/// Replaces `WHERE title LIKE '%q%' ORDER BY title ASC`, which had two defects:
///
/// 1. SQLite's `LIKE` is accent-sensitive and only case-insensitive for ASCII.
///    172 of the 500 bundled titles carry an accent, so "Guardioes" found
///    nothing and "CORAÇÃO" in caps found nothing either — while guess *matching*
///    was accent-insensitive all along.
/// 2. Alphabetical order is not relevance. Typing "star" returned
///    "A Culpa é das Estrelas" before "Guerra nas Estrelas".
///
/// Everything here operates on strings already passed through
/// [StringNormalizer.normalize], so comparisons are lowercase, accent-free and
/// stripped of punctuation.
abstract final class MovieSearch {
  /// Minimum query length before typo tolerance kicks in. Below this, edit
  /// distance produces mostly noise ("ba" is 2 edits from half the catalogue).
  static const int minLengthForFuzzy = 4;

  /// Largest edit distance still considered a match.
  static const int maxEditDistance = 2;

  /// Ids of [candidates] matching [rawQuery], most relevant first, capped at
  /// [limit].
  ///
  /// This is the whole selection step: the repository only supplies candidates
  /// and turns the returned ids back into `Movie`s.
  static List<int> rank(
    String rawQuery,
    List<SearchCandidate> candidates, {
    int limit = 10,
  }) {
    final query = StringNormalizer.normalize(rawQuery);
    if (query.isEmpty) return const [];

    final scored = <_Scored>[];
    for (final c in candidates) {
      final titleScore = score(query, c.titleNorm);
      final originalScore = score(query, c.originalNorm);
      if (titleScore <= 0 && originalScore <= 0) continue;

      final useTitle = titleScore >= originalScore;
      scored.add(_Scored(
        c.id,
        useTitle ? titleScore : originalScore,
        useTitle ? c.titleNorm : c.originalNorm,
      ));
    }

    scored.sort((a, b) =>
        compareCandidates(a.score, a.matchedTitle, b.score, b.matchedTitle));

    return [for (final s in scored.take(limit)) s.id];
  }

  /// Relevance of [normalizedTitle] for [normalizedQuery]; 0 means no match.
  ///
  /// Tiers are spaced far apart so a better kind of match always outranks a
  /// worse one regardless of length adjustments.
  static int score(String normalizedQuery, String normalizedTitle) {
    if (normalizedQuery.isEmpty || normalizedTitle.isEmpty) return 0;

    if (normalizedTitle == normalizedQuery) return 1000;
    if (normalizedTitle.startsWith(normalizedQuery)) return 900;

    final words = normalizedTitle.split(' ');
    for (final word in words) {
      if (word.startsWith(normalizedQuery)) return 800;
    }

    if (normalizedTitle.contains(normalizedQuery)) return 700;

    // Punctuation-insensitive: "spider man" should reach "Spider-Man", whose
    // normalized form is "spiderman" (normalize drops the hyphen without
    // inserting a space).
    final compactTitle = normalizedTitle.replaceAll(' ', '');
    final compactQuery = normalizedQuery.replaceAll(' ', '');
    if (compactQuery.isNotEmpty && compactTitle.contains(compactQuery)) {
      return 600;
    }

    if (normalizedQuery.length < minLengthForFuzzy) return 0;

    // Typo tolerance: against the whole title, then against each word, so
    // "guardioes" still reaches "guardioes da galaxia" with a slip.
    final whole = levenshtein(normalizedQuery, normalizedTitle, maxEditDistance);
    if (whole <= maxEditDistance) return 500 - whole * 50;

    var best = maxEditDistance + 1;
    for (final word in words) {
      if (word.length < minLengthForFuzzy) continue;
      final d = levenshtein(normalizedQuery, word, maxEditDistance);
      if (d < best) best = d;
    }
    if (best <= maxEditDistance) return 400 - best * 50;

    return 0;
  }

  /// Compares two candidates for the result list.
  ///
  /// Higher score wins; ties go to the shorter title (more specific), then
  /// alphabetically so the order is stable across runs.
  static int compareCandidates(
    int scoreA,
    String titleA,
    int scoreB,
    String titleB,
  ) {
    if (scoreA != scoreB) return scoreB.compareTo(scoreA);
    if (titleA.length != titleB.length) {
      return titleA.length.compareTo(titleB.length);
    }
    return titleA.compareTo(titleB);
  }

  /// Levenshtein distance, abandoned early once it exceeds [maxDistance].
  ///
  /// Returns `maxDistance + 1` when the real distance is larger, which is all
  /// the caller needs to reject a candidate.
  static int levenshtein(String a, String b, [int maxDistance = 1 << 30]) {
    if (a == b) return 0;
    if ((a.length - b.length).abs() > maxDistance) return maxDistance + 1;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previous = List<int>.generate(b.length + 1, (i) => i);
    var current = List<int>.filled(b.length + 1, 0);

    for (var i = 1; i <= a.length; i++) {
      current[0] = i;
      var rowMin = current[0];

      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        var value = previous[j - 1] + cost;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        if (deletion < value) value = deletion;
        if (insertion < value) value = insertion;
        current[j] = value;
        if (value < rowMin) rowMin = value;
      }

      // Every remaining row can only grow, so bail out.
      if (rowMin > maxDistance) return maxDistance + 1;

      final swap = previous;
      previous = current;
      current = swap;
    }

    final result = previous[b.length];
    return result > maxDistance ? maxDistance + 1 : result;
  }
}

class _Scored {
  final int id;
  final int score;
  final String matchedTitle;

  const _Scored(this.id, this.score, this.matchedTitle);
}
