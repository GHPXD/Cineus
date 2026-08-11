from pathlib import Path


def read(path: str) -> str:
    return Path(path).read_text(encoding='utf-8')


def write(path: str, text: str) -> None:
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding='utf-8')


def replace_once(path: str, old: str, new: str) -> None:
    text = read(path)
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f'{path}: expected one match, got {count}: {old[:80]!r}')
    write(path, text.replace(old, new, 1))


# SQLite schema and seed support.
replace_once(
    'lib/data/datasources/database_seeder.dart',
    "    await db.execute(\n      'CREATE INDEX IF NOT EXISTS idx_clues_movie ON clues(movie_id)',\n    );\n  }",
    "    await db.execute(\n      'CREATE INDEX IF NOT EXISTS idx_clues_movie ON clues(movie_id)',\n    );\n    await ensureLocalizationTables(db);\n  }",
)

marker = "\n  /// Creates `game_sessions`, migrating the legacy single-key layout first.\n"
localization_schema = r"""

  /// Optional translated catalogue content. Portuguese stays in the base tables
  /// and is therefore always the fallback when a translation is incomplete.
  Future<void> ensureLocalizationTables(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS movie_localizations (
        movie_id  INTEGER NOT NULL,
        locale    TEXT    NOT NULL,
        title     TEXT    NOT NULL,
        genres    TEXT,
        overview  TEXT,
        tagline   TEXT,
        PRIMARY KEY (movie_id, locale),
        FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS clue_localizations (
        clue_id   INTEGER NOT NULL,
        locale    TEXT    NOT NULL,
        category  TEXT    NOT NULL,
        text      TEXT    NOT NULL,
        PRIMARY KEY (clue_id, locale),
        FOREIGN KEY (clue_id) REFERENCES clues(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_movie_localizations_locale '
      'ON movie_localizations(locale, movie_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_clue_localizations_locale '
      'ON clue_localizations(locale, clue_id)',
    );
  }
"""
text = read('lib/data/datasources/database_seeder.dart')
if text.count(marker) != 1:
    raise RuntimeError('database seeder game-session marker missing')
write(
    'lib/data/datasources/database_seeder.dart',
    text.replace(marker, localization_schema + marker, 1),
)

replace_once(
    'lib/data/datasources/database_seeder.dart',
    "    final movies = (data['movies'] as List).cast<Map<String, dynamic>>();\n    final clues = (data['clues'] as List).cast<Map<String, dynamic>>();",
    "    final movies = (data['movies'] as List).cast<Map<String, dynamic>>();\n"
    "    final clues = (data['clues'] as List).cast<Map<String, dynamic>>();\n"
    "    final movieLocalizations =\n"
    "        (data['movie_localizations'] as List? ?? const [])\n"
    "            .cast<Map<String, dynamic>>();\n"
    "    final clueLocalizations =\n"
    "        (data['clue_localizations'] as List? ?? const [])\n"
    "            .cast<Map<String, dynamic>>();",
)
replace_once(
    'lib/data/datasources/database_seeder.dart',
    "    const clueCols = {'id', 'movie_id', 'clue_number', 'category', 'text'};\n\n    const chunkSize = 100;",
    "    const clueCols = {'id', 'movie_id', 'clue_number', 'category', 'text'};\n"
    "    const movieLocalizationCols = {\n"
    "      'movie_id', 'locale', 'title', 'genres', 'overview', 'tagline',\n"
    "    };\n"
    "    const clueLocalizationCols = {'clue_id', 'locale', 'category', 'text'};\n\n"
    "    const chunkSize = 100;\n"
    "    await ensureLocalizationTables(db);",
)

json_end = """      await batch.commit(noResult: true);
    }
  }

  /// Copies catalogue rows from another SQLite database into [db]."""
json_localization_loops = r"""      await batch.commit(noResult: true);
    }

    for (var i = 0; i < movieLocalizations.length; i += chunkSize) {
      final batch = db.batch();
      for (final row in movieLocalizations.sublist(
        i,
        (i + chunkSize).clamp(0, movieLocalizations.length),
      )) {
        batch.insert('movie_localizations', {
          for (final entry in row.entries)
            if (movieLocalizationCols.contains(entry.key))
              entry.key: entry.value,
        }, conflictAlgorithm: conflict);
      }
      await batch.commit(noResult: true);
    }

    for (var i = 0; i < clueLocalizations.length; i += chunkSize) {
      final batch = db.batch();
      for (final row in clueLocalizations.sublist(
        i,
        (i + chunkSize).clamp(0, clueLocalizations.length),
      )) {
        batch.insert('clue_localizations', {
          for (final entry in row.entries)
            if (clueLocalizationCols.contains(entry.key))
              entry.key: entry.value,
        }, conflictAlgorithm: conflict);
      }
      await batch.commit(noResult: true);
    }
  }

  /// Copies catalogue rows from another SQLite database into [db]."""
replace_once(
    'lib/data/datasources/database_seeder.dart',
    json_end,
    json_localization_loops,
)

marker = "\n  Future<void> seedFromDatabase(\n"
helper = r"""

  Future<List<Map<String, Object?>>> _optionalRows(
    Database source,
    String table,
  ) async {
    final exists = await source.rawQuery(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
      [table],
    );
    if (exists.isEmpty) return const [];
    return source.query(table);
  }
"""
text = read('lib/data/datasources/database_seeder.dart')
if text.count(marker) != 1:
    raise RuntimeError('seedFromDatabase marker missing')
write(
    'lib/data/datasources/database_seeder.dart',
    text.replace(marker, helper + marker, 1),
)

replace_once(
    'lib/data/datasources/database_seeder.dart',
    "    final movies = await source.query('movies');\n    final clues = await source.query('clues');",
    "    final movies = await source.query('movies');\n"
    "    final clues = await source.query('clues');\n"
    "    final movieLocalizations =\n"
    "        await _optionalRows(source, 'movie_localizations');\n"
    "    final clueLocalizations =\n"
    "        await _optionalRows(source, 'clue_localizations');",
)
text = read('lib/data/datasources/database_seeder.dart')
old = "    const clueCols = {'id', 'movie_id', 'clue_number', 'category', 'text'};\n    const chunkSize = 100;"
if text.count(old) != 1:
    raise RuntimeError(f'seedFromDatabase clueCols count: {text.count(old)}')
new = (
    "    const clueCols = {'id', 'movie_id', 'clue_number', 'category', 'text'};\n"
    "    const movieLocalizationCols = {\n"
    "      'movie_id', 'locale', 'title', 'genres', 'overview', 'tagline',\n"
    "    };\n"
    "    const clueLocalizationCols = {'clue_id', 'locale', 'category', 'text'};\n"
    "    const chunkSize = 100;\n\n"
    "    await ensureLocalizationTables(db);"
)
write('lib/data/datasources/database_seeder.dart', text.replace(old, new, 1))

db_end = """      await batch.commit(noResult: true);
    }
  }

  // ── Content versioning"""
db_localization_loops = r"""      await batch.commit(noResult: true);
    }

    for (var i = 0; i < movieLocalizations.length; i += chunkSize) {
      final batch = db.batch();
      for (final row in movieLocalizations.sublist(
        i,
        (i + chunkSize).clamp(0, movieLocalizations.length),
      )) {
        batch.insert('movie_localizations', {
          for (final entry in row.entries)
            if (movieLocalizationCols.contains(entry.key))
              entry.key: entry.value,
        }, conflictAlgorithm: conflict);
      }
      await batch.commit(noResult: true);
    }

    for (var i = 0; i < clueLocalizations.length; i += chunkSize) {
      final batch = db.batch();
      for (final row in clueLocalizations.sublist(
        i,
        (i + chunkSize).clamp(0, clueLocalizations.length),
      )) {
        batch.insert('clue_localizations', {
          for (final entry in row.entries)
            if (clueLocalizationCols.contains(entry.key))
              entry.key: entry.value,
        }, conflictAlgorithm: conflict);
      }
      await batch.commit(noResult: true);
    }
  }

  // ── Content versioning"""
replace_once(
    'lib/data/datasources/database_seeder.dart',
    db_end,
    db_localization_loops,
)

# Existing mobile databases need the additive tables even without a content bump.
replace_once(
    'lib/data/datasources/database_helper.dart',
    "    await _seeder.ensureRewardTables(db);\n"
    "    await _seeder.ensureExtraHintsColumn(db);\n\n"
    "    if (isFirstLaunch) {",
    "    await _seeder.ensureRewardTables(db);\n"
    "    await _seeder.ensureExtraHintsColumn(db);\n"
    "    await _seeder.ensureLocalizationTables(db);\n\n"
    "    if (isFirstLaunch) {",
)
replace_once(
    'lib/data/datasources/database_helper.dart',
    "    await _seeder.ensureExtraHintsColumn(db);\n"
    "    await _seeder.ensureAppMetaTable(db);\n  }",
    "    await _seeder.ensureExtraHintsColumn(db);\n"
    "    await _seeder.ensureLocalizationTables(db);\n"
    "    await _seeder.ensureAppMetaTable(db);\n  }",
)

# Locale-aware repository with Portuguese fallback.
write('lib/data/repositories/movie_repository_impl.dart', r"""import '../../core/utils/movie_search.dart';
import '../../domain/entities/movie.dart';
import '../../domain/repositories/movie_repository.dart';
import '../datasources/database_provider.dart';
import '../models/movie_model.dart';

typedef CatalogLocaleLoader = Future<String> Function();

class MovieRepositoryImpl implements MovieRepository {
  final DatabaseProvider _db;
  final CatalogLocaleLoader _localeLoader;

  MovieRepositoryImpl(
    this._db, {
    CatalogLocaleLoader? localeLoader,
  }) : _localeLoader = localeLoader ?? (() async => 'pt');

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
        : await db.rawQuery('''
            SELECT m.id,
                   COALESCE(ml.title, m.title) AS title,
                   m.original_title
              FROM movies m
              LEFT JOIN movie_localizations ml
                ON ml.movie_id = m.id AND ml.locale = ?
          ''', [locale]);

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
""")

# Resolve catalogue language from the persisted UI preference.
replace_once(
    'lib/presentation/providers/providers.dart',
    "import 'package:flutter_riverpod/flutter_riverpod.dart';",
    "import 'dart:ui';\n\nimport 'package:flutter_riverpod/flutter_riverpod.dart';",
)
old_repos = r"""/// Repository providers
final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepositoryImpl(ref.read(databaseProvider));
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepositoryImpl(ref.read(databaseProvider));
});

final stageRepositoryProvider = Provider<StageRepository>((ref) {
  return StageRepositoryImpl(ref.read(databaseProvider));
});

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepositoryImpl(ref.read(databaseProvider));
});

final appMetaRepositoryProvider = Provider<AppMetaRepository>((ref) {
  return AppMetaRepositoryImpl(ref.read(databaseProvider));
});"""
new_repos = r"""/// Repository providers
final appMetaRepositoryProvider = Provider<AppMetaRepository>((ref) {
  return AppMetaRepositoryImpl(ref.read(databaseProvider));
});

const _catalogLocales = {'pt', 'en', 'es'};

Future<String> _catalogLocale(Ref ref) async {
  final stored = await ref.read(appMetaRepositoryProvider).read('locale');
  if (stored != null && _catalogLocales.contains(stored)) return stored;

  final device = PlatformDispatcher.instance.locale.languageCode;
  return _catalogLocales.contains(device) ? device : 'pt';
}

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return MovieRepositoryImpl(
    ref.read(databaseProvider),
    localeLoader: () => _catalogLocale(ref),
  );
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepositoryImpl(ref.read(databaseProvider));
});

final stageRepositoryProvider = Provider<StageRepository>((ref) {
  return StageRepositoryImpl(ref.read(databaseProvider));
});

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return RewardRepositoryImpl(ref.read(databaseProvider));
});"""
replace_once('lib/presentation/providers/providers.dart', old_repos, new_repos)

replace_once(
    'lib/presentation/providers/locale_notifier.dart',
    "/// Scope note: this localises the interface only. Clues, clue categories and\n"
    "/// film titles come from the bundled catalogue, which is Portuguese (plus the\n"
    "/// original — usually English — title). Translating 500 films and 5.000 clues is\n"
    "/// content work, not a code change.",
    "/// The catalogue follows the same locale when translated rows are available.\n"
    "/// Missing movie/clue translations fall back to the Portuguese base catalogue,\n"
    "/// so partial content packs are safe to ship.",
)

notes = {
    'lib/l10n/app_pt.arb': (
        '"contentLanguageNote": "As dicas e os títulos dos filmes vêm do catálogo em português."',
        '"contentLanguageNote": "Filmes e dicas usam a tradução disponível; conteúdo ainda não traduzido aparece em português."',
    ),
    'lib/l10n/app_en.arb': (
        '"contentLanguageNote": "Clues and film titles come from the Portuguese catalogue."',
        '"contentLanguageNote": "Movies and clues use available translations; untranslated content falls back to Portuguese."',
    ),
    'lib/l10n/app_es.arb': (
        '"contentLanguageNote": "Las pistas y los títulos provienen del catálogo en portugués."',
        '"contentLanguageNote": "Las películas y pistas usan las traducciones disponibles; el contenido no traducido aparece en portugués."',
    ),
}
for path, (old, new) in notes.items():
    replace_once(path, old, new)

# Reviewed translation-pack importer.
write('scripts/import_catalog_localizations.py', r'''#!/usr/bin/env python3
# Import a reviewed Cineus catalogue translation pack into mobile + web data.

from __future__ import annotations

import json
import sqlite3
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DB_PATH = ROOT / 'assets' / 'cineus_v1.db'
WEB_SEED = ROOT / 'web' / 'cineus_v1_seed.json'
SUPPORTED = {'en', 'es', 'pt'}

SCHEMA = """
CREATE TABLE IF NOT EXISTS movie_localizations (
  movie_id INTEGER NOT NULL,
  locale TEXT NOT NULL,
  title TEXT NOT NULL,
  genres TEXT,
  overview TEXT,
  tagline TEXT,
  PRIMARY KEY (movie_id, locale),
  FOREIGN KEY (movie_id) REFERENCES movies(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS clue_localizations (
  clue_id INTEGER NOT NULL,
  locale TEXT NOT NULL,
  category TEXT NOT NULL,
  text TEXT NOT NULL,
  PRIMARY KEY (clue_id, locale),
  FOREIGN KEY (clue_id) REFERENCES clues(id) ON DELETE CASCADE
);
"""


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit('Usage: import_catalog_localizations.py <pack.json>')

    pack = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
    locale = str(pack.get('locale', '')).lower().strip()
    if locale not in SUPPORTED:
        raise SystemExit(f'Unsupported locale: {locale!r}')

    movies = pack.get('movies', [])
    clues = pack.get('clues', [])
    if not isinstance(movies, list) or not isinstance(clues, list):
        raise SystemExit('movies and clues must be arrays')

    con = sqlite3.connect(DB_PATH)
    try:
        con.execute('PRAGMA foreign_keys = ON')
        con.executescript(SCHEMA)
        for row in movies:
            movie_id = int(row['movie_id'])
            if con.execute('SELECT 1 FROM movies WHERE id = ?', (movie_id,)).fetchone() is None:
                raise ValueError(f'Unknown movie_id {movie_id}')
            genres = row.get('genres')
            if isinstance(genres, list):
                genres = ','.join(str(value) for value in genres)
            con.execute(
                """INSERT INTO movie_localizations
                   (movie_id, locale, title, genres, overview, tagline)
                   VALUES (?, ?, ?, ?, ?, ?)
                   ON CONFLICT(movie_id, locale) DO UPDATE SET
                     title = excluded.title,
                     genres = excluded.genres,
                     overview = excluded.overview,
                     tagline = excluded.tagline""",
                (movie_id, locale, str(row['title']), genres,
                 row.get('overview'), row.get('tagline')),
            )

        for row in clues:
            clue_id = int(row['clue_id'])
            if con.execute('SELECT 1 FROM clues WHERE id = ?', (clue_id,)).fetchone() is None:
                raise ValueError(f'Unknown clue_id {clue_id}')
            con.execute(
                """INSERT INTO clue_localizations (clue_id, locale, category, text)
                   VALUES (?, ?, ?, ?)
                   ON CONFLICT(clue_id, locale) DO UPDATE SET
                     category = excluded.category,
                     text = excluded.text""",
                (clue_id, locale, str(row['category']), str(row['text'])),
            )
        con.commit()
    finally:
        con.close()

    seed = json.loads(WEB_SEED.read_text(encoding='utf-8'))
    movie_rows = seed.setdefault('movie_localizations', [])
    clue_rows = seed.setdefault('clue_localizations', [])
    movie_ids = {int(row['movie_id']) for row in movies}
    clue_ids = {int(row['clue_id']) for row in clues}

    seed['movie_localizations'] = [
        row for row in movie_rows
        if not (row.get('locale') == locale and int(row.get('movie_id', -1)) in movie_ids)
    ]
    seed['clue_localizations'] = [
        row for row in clue_rows
        if not (row.get('locale') == locale and int(row.get('clue_id', -1)) in clue_ids)
    ]

    for row in movies:
        genres = row.get('genres')
        if isinstance(genres, list):
            genres = ','.join(str(value) for value in genres)
        seed['movie_localizations'].append({
            'movie_id': int(row['movie_id']),
            'locale': locale,
            'title': str(row['title']),
            'genres': genres,
            'overview': row.get('overview'),
            'tagline': row.get('tagline'),
        })
    for row in clues:
        seed['clue_localizations'].append({
            'clue_id': int(row['clue_id']),
            'locale': locale,
            'category': str(row['category']),
            'text': str(row['text']),
        })

    WEB_SEED.write_text(
        json.dumps(seed, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    print(f'Imported {len(movies)} movies and {len(clues)} clues for {locale}.')
    print('Increment AppConstants.contentVersion before shipping the pack.')


if __name__ == '__main__':
    main()
''')

write('docs/CATALOG_LOCALIZATION.md', r'''# Catalogue localization

The Portuguese `movies` and `clues` tables remain the canonical fallback. Optional translations live in `movie_localizations` and `clue_localizations`, keyed by locale (`en`, `es`, `pt`).

At runtime Cineus resolves the same language selected in Settings (or the supported device language when Settings is on **System default**). A translated row is used when present; otherwise the Portuguese base value is returned. Partial translation packs are therefore safe to ship.

## Translation pack format

Create a reviewed JSON file such as `translations/en.json`:

```json
{
  "locale": "en",
  "movies": [
    {
      "movie_id": 1,
      "title": "Localized title",
      "genres": ["Drama", "Thriller"],
      "overview": "Optional localized overview",
      "tagline": "Optional localized tagline"
    }
  ],
  "clues": [
    {
      "clue_id": 1,
      "category": "Theme",
      "text": "Reviewed localized clue"
    }
  ]
}
```

Run:

```bash
python scripts/import_catalog_localizations.py translations/en.json
```

The importer validates IDs and updates both `assets/cineus_v1.db` (mobile catalogue) and `web/cineus_v1_seed.json` (web catalogue). After importing content that must reach existing installations, increment `AppConstants.contentVersion` so the mobile refresh path copies the new localization rows on update.

Do not machine-translate the 5,000 clues directly into production. Clues affect difficulty and scoring, so translation packs should be reviewed per locale. Until a reviewed translation exists, the app deliberately falls back to Portuguese.
''')

write('test/catalog_localization_test.dart', r"""import 'package:flutter_test/flutter_test.dart';

import 'package:cineus/data/repositories/movie_repository_impl.dart';

import 'support/test_database.dart';

void main() {
  test('translated movie and clues overlay Portuguese base content', () async {
    final db = await openTestDatabase(withMovies: true);
    addTearDown(db.close);

    await db.insert('movies', {
      'id': 1,
      'title': 'A Viagem de Chihiro',
      'original_title': 'Sen to Chihiro no Kamikakushi',
      'genres': 'Animação,Fantasia',
    });
    await db.insert('clues', {
      'id': 11,
      'movie_id': 1,
      'clue_number': 1,
      'category': 'Atmosfera',
      'text': 'Uma casa de banhos esconde outro mundo.',
    });
    await db.insert('movie_localizations', {
      'movie_id': 1,
      'locale': 'en',
      'title': 'Spirited Away',
      'genres': 'Animation,Fantasy',
      'overview': 'A translated overview',
    });
    await db.insert('clue_localizations', {
      'clue_id': 11,
      'locale': 'en',
      'category': 'Atmosphere',
      'text': 'A bathhouse hides another world.',
    });

    final repo = MovieRepositoryImpl(
      TestDatabaseProvider(db),
      localeLoader: () async => 'en',
    );
    final movie = await repo.getMovieById(1);

    expect(movie!.title, 'Spirited Away');
    expect(movie.genres, ['Animation', 'Fantasy']);
    expect(movie.overview, 'A translated overview');
    expect(movie.clues.single.category, 'Atmosphere');
    expect(movie.clues.single.text, 'A bathhouse hides another world.');
  });

  test('missing translations safely fall back to Portuguese', () async {
    final db = await openTestDatabase(withMovies: true);
    addTearDown(db.close);

    await db.insert('movies', {'id': 2, 'title': 'Central do Brasil'});
    await db.insert('clues', {
      'id': 21,
      'movie_id': 2,
      'clue_number': 1,
      'category': 'Narrativa',
      'text': 'Uma viagem pelo Brasil.',
    });

    final repo = MovieRepositoryImpl(
      TestDatabaseProvider(db),
      localeLoader: () async => 'es',
    );
    final movie = await repo.getMovieById(2);

    expect(movie!.title, 'Central do Brasil');
    expect(movie.clues.single.text, 'Uma viagem pelo Brasil.');
  });

  test('search index follows locale changes and localized titles', () async {
    final db = await openTestDatabase(withMovies: true);
    addTearDown(db.close);

    await db.insert('movies', {
      'id': 3,
      'title': 'O Labirinto do Fauno',
      'original_title': 'El laberinto del fauno',
    });
    await db.insert('movie_localizations', {
      'movie_id': 3,
      'locale': 'en',
      'title': "Pan's Labyrinth",
    });
    await db.insert('movie_localizations', {
      'movie_id': 3,
      'locale': 'es',
      'title': 'El laberinto del fauno',
    });

    var locale = 'en';
    final repo = MovieRepositoryImpl(
      TestDatabaseProvider(db),
      localeLoader: () async => locale,
    );

    expect((await repo.searchMovies('pans labyrinth')).single.id, 3);
    locale = 'es';
    expect((await repo.searchMovies('laberinto del fauno')).single.id, 3);
  });

  test('getMoviesByIds overlays localized list titles', () async {
    final db = await openTestDatabase(withMovies: true);
    addTearDown(db.close);

    await db.insert('movies', {'id': 4, 'title': 'Cidade de Deus'});
    await db.insert('movie_localizations', {
      'movie_id': 4,
      'locale': 'en',
      'title': 'City of God',
    });

    final repo = MovieRepositoryImpl(
      TestDatabaseProvider(db),
      localeLoader: () async => 'en',
    );
    final movies = await repo.getMoviesByIds([4]);
    expect(movies.single.title, 'City of God');
  });
}
""")

print('catalog localization patch applied')
