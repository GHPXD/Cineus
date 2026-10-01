/// Short shareable code identifying one film.
///
/// Format: `CIN-XXXX`, where the four characters carry the film id plus a
/// checksum in a Crockford-style base-32 alphabet.
///
/// Codes are typo-resistant and intentionally non-sequential. This is
/// obfuscation, not security.
abstract final class ChallengeCode {
  static const String prefix = 'CIN';

  /// Crockford base-32: no I, L, O or U, reducing transcription ambiguity.
  static const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// 15 bits covers ids 1..32767.
  static const int _idBits = 15;
  static const int _idMask = (1 << _idBits) - 1;

  /// Invertible multiplier modulo 2^15.
  static const int _mix = 0x2A5B;
  static const int _mixInverse = 0x75D3;

  /// Optional verified public origin for shareable HTTPS links.
  ///
  /// Keep this unset until the domain is configured for Android App Links and
  /// iOS Universal Links.
  static const String _publicBaseUrl = String.fromEnvironment(
    'CINEUS_PUBLIC_BASE_URL',
    defaultValue: '',
  );

  static Uri? get configuredPublicBase {
    return _validatedPublicBase(Uri.tryParse(_publicBaseUrl.trim()));
  }

  static Uri? _validatedPublicBase(Uri? uri) {
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri;
  }

  /// Encodes [movieId] into `CIN-XXXX`.
  static String encode(int movieId) {
    if (movieId <= 0 || movieId > _idMask) {
      throw ArgumentError.value(movieId, 'movieId', 'fora da faixa codificável');
    }

    final scrambled = (movieId * _mix) & _idMask;
    final payload = (scrambled << 5) | _checksum(scrambled);

    final chars = <String>[];
    for (var shift = 15; shift >= 0; shift -= 5) {
      chars.add(_alphabet[(payload >> shift) & 0x1F]);
    }
    return '$prefix-${chars.join()}';
  }

  /// Decodes a code back to a film id, or null when invalid.
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

  static bool isValid(String raw) => decode(raw) != null;

  /// Generates an HTTPS challenge URL when a verified base is configured;
  /// otherwise preserves the existing custom-scheme behavior.
  static Uri linkFor(int movieId, {Uri? publicBase}) {
    final code = encode(movieId);
    final base = _validatedPublicBase(publicBase) ?? configuredPublicBase;

    if (base == null) {
      return Uri.parse('cineus://challenge/$code');
    }

    final prefixPath = base.pathSegments.where((s) => s.isNotEmpty).toList();
    return base.replace(
      pathSegments: [...prefixPath, 'challenge', code],
      query: null,
      fragment: null,
    );
  }

  /// Extracts a film id from a Cineus custom-scheme or verified HTTPS link.
  ///
  /// HTTPS is accepted only for the configured/explicit origin.
  static int? movieIdFromLink(Uri uri, {Uri? publicBase}) {
    final customScheme =
        uri.scheme.toLowerCase() == 'cineus' && uri.host == 'challenge';

    final base = _validatedPublicBase(publicBase) ?? configuredPublicBase;
    final verifiedHttps = base != null &&
        uri.scheme.toLowerCase() == 'https' &&
        uri.host.toLowerCase() == base.host.toLowerCase() &&
        uri.port == base.port;

    if (!customScheme && !verifiedHttps) return null;

    final fromQuery = uri.queryParameters['code'];
    String? fromPath;

    if (uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.last;
      if (customScheme) {
        fromPath = last;
      } else {
        final segments = uri.pathSegments;
        if (segments.length >= 2 &&
            segments[segments.length - 2] == 'challenge') {
          fromPath = last;
        }
      }
    }

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
