"""Verify a release directory produced by build_release.py."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


REQUIRED = {
    "fxmanifest.lua",
    "README.md",
    "CHANGELOG.md",
    "web/dist/index.html",
    "shared/version.lua",
}
FORBIDDEN_PARTS = {".git", ".codebase-memory", "tests", "node_modules", "scripts"}
FORBIDDEN_SUFFIXES = (".pem", ".key")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("release", type=Path)
    args = parser.parse_args()
    root = args.release.resolve()
    manifest_path = root / "release-manifest.json"
    if not manifest_path.is_file():
        raise SystemExit("release-manifest.json is missing")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    listed = {entry["path"] for entry in manifest.get("files", [])}
    missing = sorted(REQUIRED - listed)
    if missing:
        raise SystemExit("Required release files are missing: " + ", ".join(missing))
    for entry in manifest["files"]:
        path = root / entry["path"]
        if not path.is_file():
            raise SystemExit(f"Manifest file is missing: {entry['path']}")
        if hashlib.sha256(path.read_bytes()).hexdigest() != entry["sha256"]:
            raise SystemExit(f"Manifest hash mismatch: {entry['path']}")
        parts = set(path.relative_to(root).parts)
        if parts & FORBIDDEN_PARTS or path.suffix in FORBIDDEN_SUFFIXES:
            raise SystemExit(f"Forbidden release path: {entry['path']}")
    print(f"Release OK: {manifest.get('resource')} {manifest.get('version')} ({len(listed)} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
