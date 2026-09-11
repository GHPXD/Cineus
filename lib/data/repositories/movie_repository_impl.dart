import '../../core/utils/movie_search.dart';
import '../../domain/entities/movie.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/database_provider.dart';
import '../models/movie_model.dart';

class MovieRepositoryImpl implements MovieRepository {
  final DatabaseProvider _db;

  MovieRepositoryImpl(this._db);

  /// Normalized titles held in memory so each keystroke ranks without a query.
  List<SearchCandidate>? _searchIndex;

  @override
  Future<Movie?> getMovieById(int id) async {
    final db = await _db.database;
    final movieMaps = await db.query('movies', where: 'id = ?', whereArgs: [id]);
    if (movieMaps.isEmpty) return null;

    final clueMaps = await db.query(
      'clues',
      where: 'movie_id = ?',
      whereArgs: [id],
      orderBy: 'clue_number ASC',
    );

    final clues = clueMaps.map(ClueModel.fromMap).toList();
    return MovieModel.fromMap(movieMaps.first, clues);
  }

  @override
  Future<int> getMovieCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM movies');
    return result.first['count'] as int;
  }

  @override
  Future<List<int>> getMovieIds() async {
    final db = await _db.database;
    final rows = await db.query('movies', columns: ['id'], orderBy: 'id ASC');
    return rows.map((row) => row['id'] as int).toList(growable: false);
  }

  Future<List<SearchCandidate>> _loadSearchIndex() async {
    final cached = _searchIndex;
    if (cached != null) return cached;

    final db = await _db.database;
    final rows = await db.query(
      'movies',
      columns: ['id', 'title', 'original_title'],
    );

    final index = rows
        .map((r) => SearchCandidate.fromTitles(
              r['id'] as int,
              r['title'] as String? ?? '',
              r['original_title'] as String?,
            ))
        .toList(growable: false);

    _searchIndex = index;
    return index;
  }

  @override
  Future<List<Movie>> searchMovies(String query, {int limit = 10}) async {
    final ids = MovieSearch.rank(
      query,
      await _loadSearchIndex(),
      limit: limit,
    );
    return getMoviesByIds(ids);
  }

  @override
  Future<List<Movie>> getMoviesByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final db = await _db.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await db.query(
      'movies',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    final byId = {for (final m in maps) m['id'] as int: MovieModel.fromMap(m)};
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }
}
