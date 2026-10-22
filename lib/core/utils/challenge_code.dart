import '../../domain/entities/game_session.dart';

class ChallengeTarget {
  final int movieId;
  final GameMode mode;
  const ChallengeTarget(this.movieId, {this.mode = GameMode.clue});
}

/// Short shareable code identifying one film and its mode.
///
/// Legacy clues: `CIN-XXXX`; Poster: `CINP-XXXX`. The four payload characters
/// carry the film id plus a checksum in a Crockford-style base-32 alphabet.
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
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    return uri;
  }

  /// Encodes [movieId] into `CIN-XXXX`.
  static String encode(int movieId, {GameMode mode = GameMode.clue}) {
    if (movieId <= 0 || movieId > _idMask) {
      throw ArgumentError.value(
        movieId,
        'movieId',
        'fora da faixa codificável',
      );
    }

    final scrambled = (movieId * _mix) & _idMask;
    final payload = (scrambled << 5) | _checksum(scrambled);

    final chars = <String>[];
    for (var shift = 15; shift >= 0; shift -= 5) {
      chars.add(_alphabet[(payload >> shift) & 0x1F]);
    }
    return '${mode == GameMode.poster ? 'CINP' : prefix}-${chars.join()}';
  }

  /// Decodes a code back to a film id, or null when invalid.
  static int? decode(String raw) => decodeTarget(raw)?.movieId;

  static ChallengeTarget? decodeTarget(String raw) {
    if (raw.length > 64) return null;
    final cleaned = raw.trim().toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '');
    final poster = cleaned.length == 8 && cleaned.startsWith('CINP');
    final codePrefix = poster ? 'CINP' : prefix;
    if (!cleaned.startsWith(codePrefix)) return null;

    final body = cleaned.substring(codePrefix.length);
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
    return movieId == 0
        ? null
        : ChallengeTarget(
            movieId,
            mode: poster ? GameMode.poster : GameMode.clue,
          );
  }

  static bool isValid(String raw) => decode(raw) != null;

  /// Generates an HTTPS challenge URL when a verified base is configured;
  /// otherwise preserves the existing custom-scheme behavior.
  static Uri linkFor(
    int movieId, {
    Uri? publicBase,
    GameMode mode = GameMode.clue,
  }) {
    final code = encode(movieId, mode: mode);
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
  static int? movieIdFromLink(Uri uri, {Uri? publicBase}) =>
      targetFromLink(uri, publicBase: publicBase)?.movieId;

  static ChallengeTarget? parseInput(String raw, {Uri? publicBase}) {
    if (raw.length > 2048) return null;
    final value = raw.trim();
    final code = decodeTarget(value);
    if (code != null) return code;
    final uri = Uri.tryParse(value);
    return uri == null ? null : targetFromLink(uri, publicBase: publicBase);
  }

  static ChallengeTarget? targetFromLink(Uri uri, {Uri? publicBase}) {
    if (uri.toString().length > 2048 ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment) {
      return null;
    }
    final customScheme =
        uri.scheme.toLowerCase() == 'cineus' && uri.host == 'challenge';

    final base = _validatedPublicBase(publicBase) ?? configuredPublicBase;
    final verifiedHttps =
        base != null &&
        uri.scheme.toLowerCase() == 'https' &&
        uri.host.toLowerCase() == base.host.toLowerCase() &&
        uri.port == base.port;

    if (!customScheme && !verifiedHttps) return null;

    if (customScheme && uri.hasPort) return null;
    if (uri.queryParametersAll.keys.any((key) => key != 'code')) return null;
    final codes = uri.queryParametersAll['code'];
    if (codes != null && codes.length != 1) return null;
    final path = uri.pathSegments;
    final expected = customScheme
        ? <String>[]
        : [...base!.pathSegments.where((s) => s.isNotEmpty), 'challenge'];
    if (path.length != expected.length && path.length != expected.length + 1) {
      return null;
    }
    for (var i = 0; i < expected.length; i++) {
      if (path[i] != expected[i]) return null;
    }
    final fromPath = path.length == expected.length + 1 ? path.last : null;
    if (codes != null && fromPath != null) return null;
    return decodeTarget(fromPath ?? codes?.single ?? '');
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
