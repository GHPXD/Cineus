"""Validate that the shipped SQLite DB and JSON catalogue agree.

This is intentionally stdlib-only so CI and local catalogue maintenance use the
same checks without a Python environment bootstrap.
"""

from __future__ import annotations

import json
import pathlib
import sqlite3
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "assets" / "cineus_v1.db"
JSON_PATH = ROOT / "assets" / "cineus_v1_seed.json"
POSTERS_PATH = ROOT / "assets" / "posters"
EXPECTED_CLUES = 10


def fail(message: str) -> None:
    raise SystemExit(f"catalogue validation failed: {message}")


def normalized_movie(row: dict[str, object]) -> tuple[object, ...]:
    return (
        row.get("id"),
        row.get("tmdb_id"),
        row.get("title"),
        row.get("original_title") or "",
        row.get("year") or 0,
        row.get("director") or "",
        row.get("genres") or "",
        row.get("poster_path") or "",
        row.get("overview") or "",
        row.get("tagline") or "",
        row.get("runtime") or 0,
    )


def normalized_clue(row: dict[str, object]) -> tuple[object, ...]:
    return (
        row.get("movie_id"),
        row.get("clue_number"),
        row.get("category"),
        row.get("text"),
    )


if not DB_PATH.is_file():
    fail(f"missing {DB_PATH.relative_to(ROOT)}")
if not JSON_PATH.is_file():
    fail(f"missing {JSON_PATH.relative_to(ROOT)}")

with sqlite3.connect(DB_PATH) as conn:
    conn.row_factory = sqlite3.Row
    quick_check = conn.execute("PRAGMA quick_check(1)").fetchone()[0]
    if quick_check != "ok":
        fail(f"SQLite quick_check returned {quick_check!r}")

    db_movies = [
        dict(row)
        for row in conn.execute(
            """
            SELECT id, tmdb_id, title, original_title, year, director,
                   genres, poster_path, overview, tagline, runtime
            FROM movies
            ORDER BY id
            """
        )
    ]
    db_clues = [
        dict(row)
        for row in conn.execute(
            """
            SELECT movie_id, clue_number, category, text
            FROM clues
            ORDER BY movie_id, clue_number
            """
        )
    ]

payload = json.loads(JSON_PATH.read_text(encoding="utf-8"))
if not isinstance(payload, dict):
    fail("JSON root must be an object")
json_movies = payload.get("movies")
json_clues = payload.get("clues")
if not isinstance(json_movies, list) or not isinstance(json_clues, list):
    fail("JSON must contain movies[] and clues[]")

if len(db_movies) != len(json_movies):
    fail(f"DB has {len(db_movies)} movies but JSON has {len(json_movies)}")
if len(db_clues) != len(json_clues):
    fail(f"DB has {len(db_clues)} clues but JSON has {len(json_clues)}")

for index, (db_movie, json_movie) in enumerate(zip(db_movies, json_movies)):
    if not isinstance(json_movie, dict):
        fail(f"movies[{index}] is not an object")
    if normalized_movie(db_movie) != normalized_movie(json_movie):
        fail(
            f"movie mismatch at index {index}: DB id={db_movie['id']} "
            f"JSON id={json_movie.get('id')}"
        )
    if json_movie.get("tmdb_id") is None:
        fail(f"movie id={json_movie.get('id')} has no tmdb_id")

clue_counts: dict[int, int] = {}
for index, (db_clue, json_clue) in enumerate(zip(db_clues, json_clues)):
    if not isinstance(json_clue, dict):
        fail(f"clues[{index}] is not an object")
    if normalized_clue(db_clue) != normalized_clue(json_clue):
        fail(
            f"clue mismatch at index {index}: "
            f"DB={normalized_clue(db_clue)!r} JSON={normalized_clue(json_clue)!r}"
        )
    movie_id = int(json_clue["movie_id"])
    clue_counts[movie_id] = clue_counts.get(movie_id, 0) + 1

movie_ids = [int(movie["id"]) for movie in json_movies]
if len(movie_ids) != len(set(movie_ids)):
    fail("duplicate movie IDs")
tmdb_ids = [int(movie["tmdb_id"]) for movie in json_movies]
if len(tmdb_ids) != len(set(tmdb_ids)):
    fail("duplicate tmdb_ids")

for movie_id in movie_ids:
    if clue_counts.get(movie_id) != EXPECTED_CLUES:
        fail(
            f"movie {movie_id} has {clue_counts.get(movie_id, 0)} clues; "
            f"expected {EXPECTED_CLUES}"
        )

missing_posters = [
    movie_id for movie_id in movie_ids if not (POSTERS_PATH / f"{movie_id}.jpg").is_file()
]
if missing_posters:
    fail(f"missing poster assets for movie IDs: {missing_posters[:20]}")

print(
    f"✓ Catalogue consistent: {len(movie_ids)} movies, {len(json_clues)} clues, "
    f"{len(movie_ids)} posters; DB and JSON identities match"
)
