import '../entities/movie.dart';

abstract class MovieRepository {
  /// Get a movie by its ID with all clues loaded.
  Future<Movie?> getMovieById(int id);

  /// Get total number of movies in the database.
  Future<int> getMovieCount();

  /// Search movies by title (for autocomplete). Returns up to [limit] results.
  Future<List<Movie>> searchMovies(String query, {int limit = 10});

  /// Movies for [ids], in the order given. Missing ids are skipped.
  Future<List<Movie>> getMoviesByIds(List<int> ids);
}
