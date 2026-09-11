"""Export the canonical Cineus catalogue DB to the Web/mobile JSON snapshot.

Run from any working directory:
    python scripts/export_seed_json.py

The output is deterministic and includes the stable TMDb identity used to prevent
movie IDs from being accidentally reused across catalogue releases.
"""

from __future__ import annotations

import hashlib
import json
import pathlib
import sqlite3

ROOT = pathlib.Path(__file__).resolve().parents[1]
DB_PATH = ROOT / "assets" / "cineus_v1.db"
OUT_PATH = ROOT / "assets" / "cineus_v1_seed.json"
EXPECTED_CLUES_PER_MOVIE = 10


def rows(conn: sqlite3.Connection, query: str) -> list[dict[str, object]]:
    return [dict(row) for row in conn.execute(query).fetchall()]


def validate(movies: list[dict[str, object]], clues: list[dict[str, object]]) -> None:
    if not movies:
        raise SystemExit("catalogue contains no movies")

    ids = [int(movie["id"]) for movie in movies]
    if len(ids) != len(set(ids)):
        raise SystemExit("duplicate movie id")

    tmdb_ids = [movie["tmdb_id"] for movie in movies]
    if any(value is None for value in tmdb_ids):
        raise SystemExit("every movie must have tmdb_id before export")
    if len(tmdb_ids) != len(set(tmdb_ids)):
        raise SystemExit("duplicate tmdb_id")

    movie_ids = set(ids)
    clue_keys: set[tuple[int, int]] = set()
    clue_count = {movie_id: 0 for movie_id in ids}
    for clue in clues:
        movie_id = int(clue["movie_id"])
        clue_number = int(clue["clue_number"])
        if movie_id not in movie_ids:
            raise SystemExit(f"orphan clue references movie {movie_id}")
        if not 1 <= clue_number <= EXPECTED_CLUES_PER_MOVIE:
            raise SystemExit(f"invalid clue number {clue_number} for movie {movie_id}")
        key = (movie_id, clue_number)
        if key in clue_keys:
            raise SystemExit(f"duplicate clue {key}")
        clue_keys.add(key)
        clue_count[movie_id] += 1

    invalid = [movie_id for movie_id, count in clue_count.items() if count != EXPECTED_CLUES_PER_MOVIE]
    if invalid:
        raise SystemExit(
            f"{len(invalid)} movie(s) do not have exactly "
            f"{EXPECTED_CLUES_PER_MOVIE} clues: {invalid[:10]}"
        )


with sqlite3.connect(DB_PATH) as conn:
    conn.row_factory = sqlite3.Row
    integrity = conn.execute("PRAGMA quick_check(1)").fetchone()[0]
    if integrity != "ok":
        raise SystemExit(f"SQLite integrity check failed: {integrity}")

    movies = rows(
        conn,
        """
        SELECT id, tmdb_id, title, original_title, year, director,
               genres, poster_path, overview, tagline, runtime
        FROM movies
        ORDER BY id
        """,
    )
    clues = rows(
        conn,
        """
        SELECT movie_id, clue_number, category, text
        FROM clues
        ORDER BY movie_id, clue_number
        """,
    )

validate(movies, clues)

payload = json.dumps(
    {"movies": movies, "clues": clues},
    ensure_ascii=False,
    separators=(",", ":"),
).encode("utf-8")
OUT_PATH.write_bytes(payload)

sha256 = hashlib.sha256(payload).hexdigest()
print(
    f"✓ Exported {len(movies)} movies × {len(clues)} clues -> "
    f"{OUT_PATH.relative_to(ROOT)} ({len(payload) / 1024:.0f} KB)"
)
print(f"  sha256: {sha256}")
