"""Validate the FiveM manifest and runtime file references without a server."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "fxmanifest.lua"


def main() -> int:
    source = MANIFEST.read_text(encoding="utf-8")
    references = re.findall(r'"([^"\n]+)"', source)
    runtime = [
        value
        for value in references
        if value.startswith(("server/", "client/", "shared/", "config/", "locales/", "web/"))
    ]
    missing = [value for value in runtime if not (ROOT / value).is_file()]
    if missing:
        raise SystemExit("Manifest references missing files:\n- " + "\n- ".join(missing))
    if "server/bootstrap.lua" not in runtime:
        raise SystemExit("server/bootstrap.lua is not present in fxmanifest.lua")
    if "web/dist/index.html" not in runtime:
        raise SystemExit("web/dist/index.html is not present in fxmanifest.lua")
    print(f"Manifest OK: {len(runtime)} runtime files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
