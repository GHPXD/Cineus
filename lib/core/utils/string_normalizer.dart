/// Centralized string normalization for guess matching.
///
/// Handles accent removal, case folding, special character stripping,
/// and optional article removal for franchise matching.
abstract final class StringNormalizer {
  static const _articles = {'o', 'a', 'os', 'as', 'the', 'an', 'um', 'uma'};

  /// Normalizes a string for comparison: lowercase, accent-stripped,
  /// non-alphanumeric removed, whitespace collapsed.
  static String normalize(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[-‐‑‒–—]'), ' ')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Normalizes stripping leading articles (for franchise matching).
  static String normalizeStrippingArticles(String s) {
    final base = normalize(s);
    final words = base.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isNotEmpty && _articles.contains(words.first)) {
      words.removeAt(0);
    }
    return words.join(' ');
  }

  /// Returns true if [guess] matches any of [acceptedTitles] exactly
  /// (after normalization).
  ///
  /// This is the ONLY acceptance criterion in both game modes. Franchise
  /// proximity is a hint ([isSameFranchise]), never a win — [isFranchiseMatch]
  /// accepts any prefix and would award full marks for the wrong film in 205
  /// title combinations of the bundled catalogue.
  ///
  /// Deliberate consequence: the catalogue holds 5 pairs of films sharing a
  /// title (remake + original — O Rei Leão, A Bela e a Fera, Aladdin, Batman,
  /// Os Suspeitos), so naming one accepts the other. That is the fair call: the
  /// player produced the right name, and the clues do not reliably pin down
  /// which release is meant. The autocomplete shows the year inline when two
  /// results collide, so the choice is at least visible. Requiring the exact
  /// movie id instead would make those 10 films unguessable by name.
  static bool isExactMatch(String guess, List<String> acceptedTitles) {
    final normalizedGuess = normalize(guess);
    return acceptedTitles.any((t) => normalize(t) == normalizedGuess);
  }

  /// Returns true if [guess] is a franchise prefix match for any accepted title.
  /// E.g. "Harry Potter" matches "Harry Potter e a Pedra Filosofal".
  static bool isFranchiseMatch(String guess, List<String> acceptedTitles) {
    final normGuess = normalizeStrippingArticles(guess);
    if (normGuess.length < 4) return false;
    return acceptedTitles.any((t) {
      final normTitle = normalizeStrippingArticles(t);
      if (!normTitle.startsWith(normGuess)) return false;
      if (normTitle.length == normGuess.length) return true;
      return normTitle[normGuess.length] == ' ';
    });
  }

  /// Strips trailing sequence indicators (numbers / roman numerals / part phrases)
  /// so that "De Volta para o Futuro II" and "De Volta para o Futuro" both reduce
  /// to the same base, enabling the franchise-but-wrong-entry hint.
  static String _stripSequence(String normalized) {
    return normalized
        .replaceAll(
          RegExp(r'\s+(?:xiii|xii|xiv|xv|xi|viii|vii|vi|iv|iii|ii)\s*$'),
          '',
        )
        .replaceAll(RegExp(r'\s+\d{1,2}\s*$'), '')
        .replaceAll(
          RegExp(
            r'\s+-?\s*(?:parte?|part)\s+(?:\d+|um|dois|tres|one|two|three|four|five)\s*$',
          ),
          '',
        )
        .trim();
  }

  /// Returns true when [guess] is wrong overall but refers to the same franchise.
  /// E.g. user typed "De Volta para o Futuro" but correct is "De Volta para o Futuro II".
  static bool isSameFranchise(String guess, List<String> acceptedTitles) {
    final normGuess = _stripSequence(normalize(guess));
    if (normGuess.length < 4) return false;
    return acceptedTitles.any((t) {
      final normTitle = _stripSequence(normalize(t));
      return normGuess == normTitle && normTitle.isNotEmpty;
    });
  }
}
