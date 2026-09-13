"""Versioned Anthropic tool-use schemas — the canonical source is docs/tool-schemas.md.

No agent calls any of these yet at Stage 0 (no demon exists). They're loaded
here as versioned JSON artifacts now so nothing drifts once the Decision
Room starts wiring them in.
"""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path

_DIR = Path(__file__).resolve().parent


@lru_cache(maxsize=1)
def manifest() -> dict:
    return json.loads((_DIR / "manifest.json").read_text())


@lru_cache(maxsize=None)
def load(name: str) -> dict:
    if name not in manifest()["schemas"]:
        raise KeyError(f"unknown tool schema: {name!r}")
    return json.loads((_DIR / f"{name}.json").read_text())


def all_schemas() -> dict[str, dict]:
    return {name: load(name) for name in manifest()["schemas"]}
