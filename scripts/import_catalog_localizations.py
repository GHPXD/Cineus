#!/usr/bin/env python3
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
