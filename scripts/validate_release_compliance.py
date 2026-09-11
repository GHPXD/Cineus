"""Fail CI when release-compliance files or mandatory notices regress."""

from __future__ import annotations

import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    ROOT / "docs" / "privacy.html",
    ROOT / "docs" / "terms.html",
    ROOT / "lib" / "l10n" / "release_legal_l10n.dart",
    ROOT / "lib" / "presentation" / "screens" / "about_screen.dart",
    ROOT / "lib" / "presentation" / "screens" / "legal_screen.dart",
]

TMDB_NOTICE = (
    "This product uses the TMDB API but is not endorsed or certified by TMDB."
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(f"release compliance validation failed: {message}")


for path in REQUIRED_FILES:
    require(path.is_file(), f"missing {path.relative_to(ROOT)}")

about = (ROOT / "lib/presentation/screens/about_screen.dart").read_text(
    encoding="utf-8"
)
legal_l10n = (ROOT / "lib/l10n/release_legal_l10n.dart").read_text(
    encoding="utf-8"
)
router = (ROOT / "lib/presentation/routes/app_router.dart").read_text(encoding="utf-8")
settings = (ROOT / "lib/presentation/widgets/settings_section.dart").read_text(
    encoding="utf-8"
)
gradle = (ROOT / "android/app/build.gradle.kts").read_text(encoding="utf-8")
privacy = (ROOT / "docs/privacy.html").read_text(encoding="utf-8")
terms = (ROOT / "docs/terms.html").read_text(encoding="utf-8")

require(TMDB_NOTICE in legal_l10n,
        "mandatory TMDB attribution notice missing from legal localization")
require("ReleaseLegalL10n.tmdbNotice" in about,
        "About/Credits is not rendering the mandatory TMDB notice")
require("/about" in router and "/privacy" in router and "/terms" in router,
        "legal routes are incomplete")
require("/about" in settings, "About/Credits entry is not reachable from settings")
require("CINEUS_ALLOW_DEBUG_SIGNED_RELEASE" in gradle,
        "Android release signing bypass must be explicit")
require("throw GradleException" in gradle,
        "Android release build must fail closed without upload credentials")
require("11 de setembro de 2026" in privacy and "September 11, 2026" in privacy,
        "privacy policy effective date/locales missing")
require("11 de setembro de 2026" in terms and "September 11, 2026" in terms,
        "terms effective date/locales missing")

print("✓ Release compliance files, routes, TMDB notice and signing guard present")
