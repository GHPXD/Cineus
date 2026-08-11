/// Short shareable code identifying one film (D10).
///
/// Format: `CIN-XXXX`, where the four characters carry the film id plus a
/// checksum in a Crockford-style base-32 alphabet.
///
/// Two properties matter:
///
///  * **Typo-safe.** A mistyped character almost always fails the checksum
///    instead of silently opening a different film — which would be worse than
///    an error, because the friend would play the wrong movie and never know.
///  * **Not sequential.** The id is mixed before encoding, so `CIN-…` codes for
///    films 1 and 2 look unrelated. This is obfuscation, not security: anyone who
///    wants to enumerate the catalogue can, and nothing here needs protecting.
abstract final class ChallengeCode {
  static const String prefix = 'CIN';

  /// Crockford base-32: no I, L, O or U, so 1/I, 0/O and similar cannot be
  /// confused when read aloud or retyped.
  static const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Bits reserved for the film id. 15 bits covers 32.767 films — the catalogue
  /// has 500, leaving room to grow without changing the format.
  static const int _idBits = 15;
  static const int _idMask = (1 << _idBits) - 1;

  /// Odd multiplier, so it is invertible modulo 2^15 and spreads adjacent ids.
  ///
  /// [_mixInverse] is the modular inverse: `_mix * _mixInverse ≡ 1 (mod 2^15)`.
  /// The round-trip test covers every representable id, so a wrong constant here
  /// fails loudly rather than corrupting codes in the field.
  static const int _mix = 0x2A5B;
  static const int _mixInverse = 0x75D3;

  /// Encodes [movieId] into `CIN-XXXX`.
  ///
  /// Throws [ArgumentError] for an id outside the representable range.
  static String encode(int movieId) {
    if (movieId <= 0 || movieId > _idMask) {
      throw ArgumentError.value(
        movieId,
        'movieId',
        'fora da faixa codificável',
      );
    }

    final scrambled = (movieId * _mix) & _idMask;
    final payload = (scrambled << 5) | _checksum(scrambled);

    // 20 bits → exactly four base-32 characters.
    final chars = <String>[];
    for (var shift = 15; shift >= 0; shift -= 5) {
      chars.add(_alphabet[(payload >> shift) & 0x1F]);
    }
    return '$prefix-${chars.join()}';
  }

  /// Decodes a code back to a film id, or null when it is not a valid code.
  ///
  /// Tolerant about presentation — case, surrounding whitespace and a missing or
  /// differently-spaced separator all decode — but strict about the checksum.
  static int? decode(String raw) {
    final cleaned = raw.trim().toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '');
    if (!cleaned.startsWith(prefix)) return null;

    final body = cleaned.substring(prefix.length);
    if (body.length != 4) return null;

    var payload = 0;
    for (final char in body.split('')) {
      final value = _alphabet.indexOf(char);
      if (value < 0) return null;
      payload = (payload << 5) | value;
    }

    final scrambled = (payload >> 5) & _idMask;
    if (_checksum(scrambled) != (payload & 0x1F)) return null;

    final movieId = (scrambled * _mixInverse) & _idMask;
    return movieId == 0 ? null : movieId;
  }

  /// True when [raw] decodes to a film id.
  static bool isValid(String raw) => decode(raw) != null;

  /// Deep link the code travels in, e.g. `cineus://challenge/CIN-4F2A`.
  ///
  /// A custom scheme rather than an https link: a universal link needs a domain
  /// we control, and `cineus.app` is only a string in the share text today.
  static Uri linkFor(int movieId) =>
      Uri.parse('cineus://challenge/${encode(movieId)}');

  /// Extracts a code from an incoming deep link, or null when it is not one.
  static int? movieIdFromLink(Uri uri) {
    if (uri.scheme != 'cineus') return null;
    // Accepts cineus://challenge/CODE and cineus://challenge?code=CODE
    final fromPath = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    final fromQuery = uri.queryParameters['code'];
    for (final candidate in [fromQuery, fromPath]) {
      if (candidate == null || candidate.isEmpty) continue;
      final id = decode(candidate);
      if (id != null) return id;
    }
    return null;
  }

  /// Five-bit checksum. Weighted so transposing two characters changes it.
  static int _checksum(int value) {
    var sum = 0;
    var weight = 1;
    var remaining = value;
    while (remaining > 0) {
      sum += (remaining & 0x1F) * weight;
      remaining >>= 5;
      weight++;
    }
    return sum & 0x1F;
  }
}
