"""
Exporta o cineus.db para JSON compacto para uso como seed da versão web.
Execute: python export_seed_json.py
"""
import sqlite3
import json
import pathlib

DB_PATH = '../cineus.db'
OUT_PATH = '../assets/cineus_v1_seed.json'

conn = sqlite3.connect(DB_PATH)
conn.row_factory = sqlite3.Row

movies = [
    dict(r)
    for r in conn.execute(
        'SELECT id, title, original_title, year, director, '
        'genres, poster_path, overview, tagline, runtime '
        'FROM movies ORDER BY id'
    ).fetchall()
]

clues = [
    dict(r)
    for r in conn.execute(
        'SELECT movie_id, clue_number, category, text '
        'FROM clues ORDER BY movie_id, clue_number'
    ).fetchall()
]

conn.close()

data = {'movies': movies, 'clues': clues}
out = pathlib.Path(OUT_PATH)
out.write_text(
    json.dumps(data, ensure_ascii=False, separators=(',', ':')),
    encoding='utf-8',
)
size_kb = out.stat().st_size / 1024
print(f'✓ Exportado: {len(movies)} filmes × {len(clues)} dicas → {out} ({size_kb:.0f} KB)')
