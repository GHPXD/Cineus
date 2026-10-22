import 'challenge_code.dart';

abstract final class FriendCode {
  static bool valid(String value) =>
      RegExp(r'^[A-Za-z0-9_-]{12}$').hasMatch(value);
  static Uri link(String code) {
    if (!valid(code)) throw const FormatException('Invalid invitation');
    final base = ChallengeCode.configuredPublicBase;
    return base == null
        ? Uri.parse('cineus://friend/$code')
        : base.replace(
            pathSegments: [
              ...base.pathSegments.where((s) => s.isNotEmpty),
              'friend',
              code,
            ],
          );
  }

  static String? parse(String raw) {
    if (raw.length > 2048) return null;
    if (valid(raw.trim())) return raw.trim();
    final uri = Uri.tryParse(raw.trim()),
        base = ChallengeCode.configuredPublicBase;
    if (uri == null ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }
    final custom =
        uri.scheme == 'cineus' && uri.host == 'friend' && !uri.hasPort;
    final https =
        base != null && uri.scheme == 'https' && uri.origin == base.origin;
    if (!custom && !https) return null;
    final expected = custom
        ? <String>[]
        : [...base!.pathSegments.where((s) => s.isNotEmpty), 'friend'];
    final path = uri.pathSegments;
    if (path.length != expected.length + 1) return null;
    for (var i = 0; i < expected.length; i++) {
      if (path[i] != expected[i]) return null;
    }
    return valid(path.last) ? path.last : null;
  }
}
