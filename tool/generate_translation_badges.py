#!/usr/bin/env python3

import json
import re
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
ARB_DIR = ROOT / "lib" / "l10n"
EN_ARB = ARB_DIR / "app_en.arb"
UNTRANSLATED_JSON = ROOT / "untranslated.json"
OUTPUT_DIR = ROOT / "site" / "badges"


def load_json(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def get_translation_keys(arb: dict) -> set[str]:
    # ARB metadata entries start with @ and are not translation keys.
    return {key for key in arb if not key.startswith("@")}


def discover_languages() -> set[str]:
    # Discover languages from app_<language>.arb files.
    # English is the source language, not a translation target.
    languages = set()

    for path in ARB_DIR.glob("app_*.arb"):
        match = re.fullmatch(r"app_(.+)\.arb", path.name)
        if match:
            language = match.group(1)
            if language != "en":
                languages.add(language)

    return languages


def badge_svg(language: str, percentage: int) -> str:
    label = escape(language, {'"': "&quot;", "'": "&apos;"})
    value = f"{percentage}%"

    # Green for complete translations; amber otherwise.
    color = "#4c1" if percentage == 100 else "#dfb317"

    # Approximate widths for the standard badge font.
    label_width = max(30, len(language) * 7 + 12)
    value_width = len(value) * 7 + 12
    width = label_width + value_width

    return f"""<svg xmlns="http://www.w3.org/2000/svg"
  width="{width}" height="20" role="img"
  aria-label="{label}: {percentage}% translated">
  <title>{label}: {percentage}% translated</title>
  <linearGradient id="b" x2="0" y2="100%">
    <stop offset="0" stop-color="#fff" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="r">
    <rect width="{width}" height="20" rx="3"/>
  </clipPath>
  <g clip-path="url(#r)">
    <rect width="{label_width}" height="20" fill="#555"/>
    <rect x="{label_width}" width="{value_width}"
      height="20" fill="{color}"/>
    <rect width="{width}" height="20" fill="url(#b)"/>
  </g>
  <g font-family="Verdana,Geneva,DejaVu Sans,sans-serif"
    font-size="11" text-anchor="middle">
    <text x="{label_width / 2}" y="14" fill="#fff">{label}</text>
    <text x="{label_width + value_width / 2}" y="14"
      fill="#111">{value}</text>
  </g>
</svg>
"""


def main() -> None:
    if not EN_ARB.is_file():
        raise FileNotFoundError(f"English ARB not found: {EN_ARB}")

    if not UNTRANSLATED_JSON.is_file():
        raise FileNotFoundError(
            f"Untranslated JSON not found: {UNTRANSLATED_JSON}"
        )

    english_arb = load_json(EN_ARB)
    keys = get_translation_keys(english_arb)
    total = len(keys)

    if total == 0:
        raise ValueError(f"No translation keys found in {EN_ARB}")

    untranslated = load_json(UNTRANSLATED_JSON)

    if not isinstance(untranslated, dict):
        raise ValueError("untranslated.json must contain a JSON object")

    # Include all discovered languages, even when untranslated.json
    # omits a language because it has no untranslated strings.
    languages = discover_languages() | set(untranslated)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    generated = 0

    for language in sorted(languages):
        missing = untranslated.get(language, [])

        if not isinstance(missing, list):
            raise ValueError(
                f"{language}: expected an array of untranslated keys"
            )

        missing_keys = set(missing)

        if not all(isinstance(key, str) for key in missing):
            raise ValueError(
                f"{language}: untranslated keys must all be strings"
            )

        unknown = missing_keys - keys
        if unknown:
            raise ValueError(
                f"{language}: keys absent from English ARB: "
                f"{sorted(unknown)}"
            )

        if len(missing_keys) > total:
            raise ValueError(
                f"{language}: more untranslated keys than English keys"
            )

        remaining = len(missing_keys)
        percentage = (
            100 if remaining == 0
            else min(99, (100 * (total - remaining)) // total)
        )

        output_path = OUTPUT_DIR / f"{language}.svg"
        output_path.write_text(
            badge_svg(language, percentage),
            encoding="utf-8",
        )

        print(
            f"{language}: {percentage}% complete "
            f"({remaining}/{total} untranslated) -> {output_path.relative_to(ROOT)}"
        )
        generated += 1

    print(f"Generated {generated} translation badges.")


if __name__ == "__main__":
    main()
