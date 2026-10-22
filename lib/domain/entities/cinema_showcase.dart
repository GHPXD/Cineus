class CinemaShowcase {
  final String id, version;
  final List<int> movies;
  const CinemaShowcase(this.id, this.version, this.movies);
  String get sessionKey => 'showcase:$version:$id';
  static List<CinemaShowcase> parse(Map<String, dynamic> json) {
    if (json['schema'] != 1 ||
        json['version'] is! String ||
        !RegExp(r'^[a-z0-9-]{1,60}$').hasMatch(json['version'])) {
      throw const FormatException('Invalid showcase version');
    }
    final seen = <String>{};
    return List.unmodifiable(
      (json['themes'] as List).map((raw) {
        final id = raw['id'] as String;
        final movies = List<int>.from(raw['movies']);
        if (!{'animation', 'fantasy', 'classics'}.contains(id) ||
            !seen.add(id) ||
            movies.isEmpty ||
            movies.length > 30 ||
            movies.toSet().length != movies.length ||
            movies.any((id) => id < 1)) {
          throw const FormatException('Invalid showcase');
        }
        return CinemaShowcase(id, json['version'], List.unmodifiable(movies));
      }),
    );
  }
}
