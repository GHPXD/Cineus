"""Fail CI when bundled catalogue assets change without contentVersion bump."""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
CONSTANTS = ROOT / "lib" / "core" / "constants" / "app_constants.dart"
TRACKED_PREFIXES = (
    "assets/cineus_v1.db",
    "assets/cineus_v1_seed.json",
    "assets/posters/",
)
VERSION_RE = re.compile(r"static const int contentVersion\s*=\s*(\d+)\s*;")


def fail(message: str) -> None:
    raise SystemExit(f"content version validation failed: {message}")


def version_from_text(text: str, *, source: str) -> int:
    match = VERSION_RE.search(text)
    if match is None:
        fail(f"could not read contentVersion from {source}")
    return int(match.group(1))


def git(*args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        fail(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout


parser = argparse.ArgumentParser()
parser.add_argument(
    "--base-ref",
    default="",
    help="Git commit/ref to compare against. Empty/zero refs skip comparison.",
)
args = parser.parse_args()

base = args.base_ref.strip()
if not base or set(base) == {"0"}:
    print("✓ No usable base ref; contentVersion comparison skipped")
    raise SystemExit(0)

# Ensure the provided ref exists in the checkout before trying to compare.
probe = subprocess.run(
    ["git", "cat-file", "-e", f"{base}^{{commit}}"],
    cwd=ROOT,
    check=False,
    capture_output=True,
    text=True,
)
if probe.returncode != 0:
    fail(
        f"base ref {base!r} is not available; checkout must use fetch-depth: 0"
    )

changed = [
    line.strip()
    for line in git("diff", "--name-only", base, "HEAD", "--", "assets").splitlines()
    if line.strip()
]
catalogue_changed = [
    path for path in changed if path in TRACKED_PREFIXES or path.startswith("assets/posters/")
]

current_text = CONSTANTS.read_text(encoding="utf-8")
current_version = version_from_text(current_text, source=str(CONSTANTS.relative_to(ROOT)))

if not catalogue_changed:
    print(f"✓ Catalogue unchanged; contentVersion remains {current_version}")
    raise SystemExit(0)

base_constants = git("show", f"{base}:lib/core/constants/app_constants.dart")
base_version = version_from_text(base_constants, source=f"{base}:app_constants.dart")

if current_version <= base_version:
    preview = ", ".join(catalogue_changed[:8])
    suffix = " ..." if len(catalogue_changed) > 8 else ""
    fail(
        "bundled catalogue changed "
        f"({preview}{suffix}) but contentVersion is {current_version}; "
        f"it must be greater than base version {base_version}"
    )

print(
    "✓ Catalogue changed and contentVersion was bumped: "
    f"{base_version} -> {current_version}"
)
