# Catalogue localization

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
