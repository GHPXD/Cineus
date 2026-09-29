/// Centralized string normalization for guess matching.
///
/// Handles accent removal, case folding, special character stripping,
/// and optional article removal for franchise matching.
abstract final class StringNormalizer {
  static const _articles = {
    'o',
    'a',
    'os',
    'as',
    'the',
    'an',
    'um',
    'uma',
    'el',
    'la',
    'los',
    'las',
    'un',
    'una',
  };

  /// Common Latin characters seen in international film titles.
  ///
  /// Keeping this table local avoids adding a runtime dependency only for
  /// diacritic folding while covering Portuguese, Spanish, French, German,
  /// Nordic and Central-European titles substantially better than the old
  /// PT-only replacement chain.
  static const _fold = <String, String>{
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
    'ă': 'a', 'ą': 'a', 'æ': 'ae',
    'ç': 'c', 'ć': 'c', 'č': 'c',
    'ď': 'd', 'đ': 'd',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ĕ': 'e', 'ė': 'e',
    'ę': 'e', 'ě': 'e',
    'ğ': 'g',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'į': 'i',
    'ł': 'l',
    'ñ': 'n', 'ń': 'n', 'ň': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o',
    'œ': 'oe',
    'ř': 'r',
    'ś': 's', 'š': 's', 'ş': 's', 'ß': 'ss',
    'ť': 't',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u', 'ű': 'u',
    'ý': 'y', 'ÿ': 'y',
    'ź': 'z', 'ż': 'z', 'ž': 'z',
  };

  /// Normalizes a string for comparison: lowercase, accent-folded,
  /// punctuation converted to spacing, and whitespace collapsed.
  ///
  /// Converting punctuation to spaces instead of deleting it keeps
  /// "Spider-Man" equivalent to "Spider Man".
  static String normalize(String s) {
    final lower = s.trim().toLowerCase();
    final buffer = StringBuffer();

    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_fold[char] ?? char);
    }

    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
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
  static bool isExactMatch(String guess, List<String> acceptedTitles) {
    final normalizedGuess = normalize(guess);
    return acceptedTitles.any((t) => normalize(t) == normalizedGuess);
  }

  /// Returns true if [guess] is a franchise prefix match for any accepted title.
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
  /// so that entries from the same numbered franchise reduce to the same base.
  static String _stripSequence(String normalized) {
    return normalized
        .replaceAll(
          RegExp(r'\s+(?:xiii|xii|xiv|xv|xi|viii|vii|vi|iv|iii|ii)\s*$'),
          '',
        )
        .replaceAll(RegExp(r'\s+\d{1,2}\s*$'), '')
        .replaceAll(
          RegExp(
            r'\s*(?:parte?|part)\s+(?:\d+|um|dois|tres|one|two|three|four|five)\s*$',
          ),
          '',
        )
        .trim();
  }

  /// Returns true when [guess] is wrong overall but refers to the same franchise.
  static bool isSameFranchise(String guess, List<String> acceptedTitles) {
    final normGuess = _stripSequence(normalize(guess));
    if (normGuess.length < 4) return false;
    return acceptedTitles.any((t) {
      final normTitle = _stripSequence(normalize(t));
      return normGuess == normTitle && normTitle.isNotEmpty;
    });
  }
}
