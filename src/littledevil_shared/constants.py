"""Versioned detector constants — the single source of truth referenced by
docs/repo-structure.md §3 ("every versioned constant... No repo redefines
any of these locally").

FEATURE_VERSION is a naming convention only, safe to set now. `k` (pivot
lookback bars) and the ATR tolerances are real detector parameters that
strategy-playbook.md §3 and architecture-review.md §4.4 both require to be
frozen *before* any base-rate study runs, and never tuned against results.
They are left unset here deliberately — Stage 0 builds no detector that
reads them — and must come from Omar when Trunk's pattern/setup detectors
are decomposed, not from a guess made while writing this module.
"""

from __future__ import annotations

FEATURE_VERSION = "0.1.0"

# Deliberately unset — see module docstring. Do not default these to a
# guessed value; a detector reading `PIVOT_LOOKBACK_K` or
# `ATR_TOLERANCES` before it's set should fail loudly, not silently run
# with an invented number.
PIVOT_LOOKBACK_K: int | None = None
ATR_TOLERANCES: dict[str, float] | None = None
