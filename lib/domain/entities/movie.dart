import 'clue.dart';

class Movie {
  final int id;
  final String title;
  final String? originalTitle;
  final int year;
  final String director;
  final List<String> genres;
  final String? posterUrl;
  final String? overview;
  final String? tagline;
  final int? runtime;
  final List<Clue> clues;

  const Movie({
    required this.id,
    required this.title,
    this.originalTitle,
    required this.year,
    required this.director,
    required this.genres,
    this.posterUrl,
    this.overview,
    this.tagline,
    this.runtime,
    this.clues = const [],
  });

  /// Accepted titles for guess matching (case-insensitive, accent-insensitive).
  List<String> get acceptedTitles => [
    title,
    if (originalTitle != null) originalTitle!,
  ];

  Movie copyWith({
    int? id,
    String? title,
    String? originalTitle,
    int? year,
    String? director,
    List<String>? genres,
    String? posterUrl,
    String? overview,
    String? tagline,
    int? runtime,
    List<Clue>? clues,
  }) {
    return Movie(
      id: id ?? this.id,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      year: year ?? this.year,
      director: director ?? this.director,
      genres: genres ?? this.genres,
      posterUrl: posterUrl ?? this.posterUrl,
      overview: overview ?? this.overview,
      tagline: tagline ?? this.tagline,
      runtime: runtime ?? this.runtime,
      clues: clues ?? this.clues,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Movie && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
