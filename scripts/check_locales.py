"""Ensure the fallback locale and configured locale expose the same keys."""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def keys(value: object, prefix: str = "") -> set[str]:
    if not isinstance(value, dict):
        return {prefix}
    result: set[str] = set()
    for key, child in value.items():
        path = f"{prefix}.{key}" if prefix else key
        result.update(keys(child, path))
    return result


def main() -> int:
    with (ROOT / "locales" / "en.json").open(encoding="utf-8") as handle:
        fallback = keys(json.load(handle))
    with (ROOT / "locales" / "tr.json").open(encoding="utf-8") as handle:
        configured = keys(json.load(handle))
    missing = sorted(fallback - configured)
    extra = sorted(configured - fallback)
    if missing or extra:
        if missing:
            print("Missing in tr.json:", *missing, sep="\n- ")
        if extra:
            print("Only in tr.json:", *extra, sep="\n- ")
        return 1
    print(f"Locale keys OK: {len(fallback)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
