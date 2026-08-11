import '../../core/utils/movie_search.dart';
import '../../domain/entities/movie.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/database_provider.dart';
import '../models/movie_model.dart';

typedef CatalogLocaleLoader = Future<String> Function();

class MovieRepositoryImpl implements MovieRepository {
  final DatabaseProvider _db;
  final CatalogLocaleLoader _localeLoader;

  MovieRepositoryImpl(this._db, {CatalogLocaleLoader? localeLoader})
    : _localeLoader = localeLoader ?? (() async => 'pt');

  static const _supportedLocales = {'pt', 'en', 'es'};
  final Map<String, List<SearchCandidate>> _searchIndexes = {};

  Future<String> _locale() async {
    final raw = (await _localeLoader()).trim().toLowerCase();
    final language = raw.split(RegExp('[-_]')).first;
    return _supportedLocales.contains(language) ? language : 'pt';
  }

  Map<String, dynamic> _overlayMovie(
    Map<String, dynamic> base,
    Map<String, dynamic>? localized,
  ) {
    if (localized == null) return base;
    return {
      ...base,
      'title': localized['title'] ?? base['title'],
      'genres': localized['genres'] ?? base['genres'],
      'overview': localized['overview'] ?? base['overview'],
      'tagline': localized['tagline'] ?? base['tagline'],
    };
  }

  @override
  Future<Movie?> getMovieById(int id) async {
    final db = await _db.database;
    final locale = await _locale();
    final movieMaps = await db.query(
      'movies',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (movieMaps.isEmpty) return null;

    final clueMaps = await db.query(
      'clues',
      where: 'movie_id = ?',
      whereArgs: [id],
      orderBy: 'clue_number ASC',
    );

    Map<String, dynamic>? movieLocalization;
    final clueLocalizations = <int, Map<String, dynamic>>{};
    if (locale != 'pt') {
      final movieRows = await db.query(
        'movie_localizations',
        where: 'movie_id = ? AND locale = ?',
        whereArgs: [id, locale],
        limit: 1,
      );
      if (movieRows.isNotEmpty) movieLocalization = movieRows.first;

      final clueIds = [for (final row in clueMaps) row['id'] as int];
      if (clueIds.isNotEmpty) {
        final placeholders = List.filled(clueIds.length, '?').join(',');
        final rows = await db.query(
          'clue_localizations',
          where: 'locale = ? AND clue_id IN ($placeholders)',
          whereArgs: [locale, ...clueIds],
        );
        for (final row in rows) {
          clueLocalizations[row['clue_id'] as int] = row;
        }
      }
    }

    final clues = clueMaps.map((base) {
      final localized = clueLocalizations[base['id'] as int];
      if (localized == null) return ClueModel.fromMap(base);
      return ClueModel.fromMap({
        ...base,
        'category': localized['category'] ?? base['category'],
        'text': localized['text'] ?? base['text'],
      });
    }).toList();

    return MovieModel.fromMap(
      _overlayMovie(movieMaps.first, movieLocalization),
      clues,
    );
  }

  @override
  Future<int> getMovieCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM movies');
    return result.first['count'] as int;
  }

  Future<List<SearchCandidate>> _loadSearchIndex(String locale) async {
    final cached = _searchIndexes[locale];
    if (cached != null) return cached;

    final db = await _db.database;
    final rows = locale == 'pt'
        ? await db.query('movies', columns: ['id', 'title', 'original_title'])
        : await db.rawQuery(
            '''
            SELECT m.id,
                   COALESCE(ml.title, m.title) AS title,
                   m.original_title
              FROM movies m
              LEFT JOIN movie_localizations ml
                ON ml.movie_id = m.id AND ml.locale = ?
          ''',
            [locale],
          );

    final index = rows
        .map(
          (row) => SearchCandidate.fromTitles(
            row['id'] as int,
            row['title'] as String? ?? '',
            row['original_title'] as String?,
          ),
        )
        .toList(growable: false);

    _searchIndexes[locale] = index;
    return index;
  }

  @override
  Future<List<Movie>> searchMovies(String query, {int limit = 10}) async {
    final locale = await _locale();
    final ids = MovieSearch.rank(
      query,
      await _loadSearchIndex(locale),
      limit: limit,
    );
    return getMoviesByIds(ids);
  }

  @override
  Future<List<Movie>> getMoviesByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final db = await _db.database;
    final locale = await _locale();
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await db.query(
      'movies',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    final localizations = <int, Map<String, dynamic>>{};
    if (locale != 'pt') {
      final rows = await db.query(
        'movie_localizations',
        where: 'locale = ? AND movie_id IN ($placeholders)',
        whereArgs: [locale, ...ids],
      );
      for (final row in rows) {
        localizations[row['movie_id'] as int] = row;
      }
    }

    final byId = {
      for (final map in maps)
        map['id'] as int: MovieModel.fromMap(
          _overlayMovie(map, localizations[map['id'] as int]),
        ),
    };
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }
}
