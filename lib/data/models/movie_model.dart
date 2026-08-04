import '../../domain/entities/clue.dart';
import '../../domain/entities/movie.dart';

class MovieModel {
  static Movie fromMap(Map<String, dynamic> map, [List<Clue>? clues]) {
    final genresRaw = map['genres'] as String? ?? '';
    return Movie(
      id: map['id'] as int,
      title: map['title'] as String,
      originalTitle: map['original_title'] as String?,
      year: map['year'] as int,
      director: map['director'] as String,
      genres: genresRaw.isNotEmpty ? genresRaw.split(',') : [],
      posterUrl: map['poster_path'] as String?,
      overview: map['overview'] as String?,
      tagline: map['tagline'] as String?,
      runtime: map['runtime'] as int?,
      clues: clues ?? [],
    );
  }

  static Map<String, dynamic> toMap(Movie movie) => {
        'id': movie.id,
        'title': movie.title,
        'original_title': movie.originalTitle,
        'year': movie.year,
        'director': movie.director,
        'genres': movie.genres.join(','),
        'poster_path': movie.posterUrl,
        'overview': movie.overview,
        'tagline': movie.tagline,
        'runtime': movie.runtime,
      };
}

class ClueModel {
  static Clue fromMap(Map<String, dynamic> map) => Clue(
        id: map['id'] as int,
        movieId: map['movie_id'] as int,
        clueNumber: map['clue_number'] as int,
        category: map['category'] as String,
        text: map['text'] as String,
      );

  static Map<String, dynamic> toMap(Clue clue) => {
        'movie_id': clue.movieId,
        'clue_number': clue.clueNumber,
        'category': clue.category,
        'text': clue.text,
      };
}
