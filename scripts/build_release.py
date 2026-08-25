"""Build a deterministic CivicOS runtime artifact.

The output is restricted to the repository's ``build/`` directory so a release
run cannot delete an arbitrary workspace path. Development tests, source NUI
modules, local graph artifacts, and secret-like files are excluded.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "build" / "gnsh-civicos"
EXCLUDED_DIRS = {
    ".git",
    ".github",
    ".codebase-memory",
    ".impeccable",
    "build",
    "node_modules",
    "tests",
    "scripts",
}
EXCLUDED_PATHS = {"web/src", "web/package.json", "web/tsconfig.json"}
EXCLUDED_NAMES = {".gitignore", "design.json"}
SECRET_NAMES = {".env", ".env.local", ".env.production", "secrets.json", "credentials.json"}


def version() -> str:
    source = (ROOT / "shared" / "version.lua").read_text(encoding="utf-8")
    match = re.search(r'version\s*=\s*"([^"]+)"', source)
    return match.group(1) if match else "0.0.0"


def commit() -> str:
    try:
        return subprocess.check_output(
            ["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, text=True
        ).strip()
    except (OSError, subprocess.CalledProcessError):
        return "unknown"


def is_excluded(path: Path) -> bool:
    relative = path.relative_to(ROOT).as_posix()
    if relative in EXCLUDED_PATHS or any(
        relative.startswith(prefix + "/") for prefix in EXCLUDED_PATHS
    ):
        return True
    if any(part in EXCLUDED_DIRS for part in path.relative_to(ROOT).parts):
        return True
    if path.name in EXCLUDED_NAMES:
        return True
    if path.name in SECRET_NAMES or path.name.endswith((".pem", ".key")):
        return True
    return any(part.startswith(".env") for part in path.relative_to(ROOT).parts)


def copy_runtime(output: Path) -> list[Path]:
    copied: list[Path] = []
    for source in ROOT.rglob("*"):
        if not source.is_file() or is_excluded(source):
            continue
        relative = source.relative_to(ROOT)
        target = output / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        copied.append(target)
    return sorted(copied)


def write_manifest(output: Path, files: list[Path]) -> Path:
    entries = []
    for path in files:
        entries.append(
            {
                "path": path.relative_to(output).as_posix(),
                "bytes": path.stat().st_size,
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            }
        )
    manifest = {
        "resource": "gnsh-civicos",
        "version": version(),
        "commit": commit(),
        "files": entries,
    }
    path = output / "release-manifest.json"
    path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return path


def zip_output(output: Path) -> Path:
    archive = output.with_suffix(".zip")
    if archive.exists():
        archive.unlink()
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as handle:
        for path in sorted(output.rglob("*")):
            if path.is_file():
                handle.write(path, path.relative_to(output.parent))
    return archive


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--zip", action="store_true", dest="make_zip")
    args = parser.parse_args()
    output = args.output.resolve()
    build_root = (ROOT / "build").resolve()
    if build_root not in output.parents:
        raise SystemExit(f"Release output must be inside {build_root}")
    if output == ROOT:
        raise SystemExit("Refusing to use the repository root as release output")
    if output.exists():
        shutil.rmtree(output)
    output.mkdir(parents=True)
    files = copy_runtime(output)
    write_manifest(output, files)
    archive = zip_output(output) if args.make_zip else None
    print(f"Release ready: {output}")
    if archive:
        print(f"Archive ready: {archive}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
