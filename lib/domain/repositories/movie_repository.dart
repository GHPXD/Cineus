import '../entities/movie.dart';

abstract class MovieRepository {
  /// Get a movie by its ID with all clues loaded.
  Future<Movie?> getMovieById(int id);

  /// Get total number of movies in the database.
  Future<int> getMovieCount();

  /// All real movie IDs in deterministic ascending order.
  ///
  /// Daily selection must use this list instead of assuming the catalogue IDs
  /// are the contiguous range 1..COUNT(*).
  Future<List<int>> getMovieIds();

  /// Search movies by title (for autocomplete). Returns up to [limit] results.
  Future<List<Movie>> searchMovies(String query, {int limit = 10});

  /// Movies for [ids], in the order given. Missing ids are skipped.
  Future<List<Movie>> getMoviesByIds(List<int> ids);
}
