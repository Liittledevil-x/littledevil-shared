# CLAUDE.md — littledevil-shared

Full architecture: `docs/` (submodule → littledevil-docs, pinned; `git submodule update --remote docs` to refresh).

## This repo's scope
Not a running service — a versioned package every other repo depends on: Postgres models, the tool JSON schemas, detector constants (`k`, ATR tolerances, `feature_version`), the event envelope shape. The single source of truth that prevents schema drift across the other repos (docs/repo-structure.md §3). Every consuming repo's CI pins this package's version explicitly and fails the build on a mismatch.

Primary references: docs/data-and-events.md §1; docs/tool-schemas.md; docs/repo-structure.md §3.

## Non-negotiables (repeated here so they hold even if docs/ isn't checked out)
- Agents request; Python executes and gates.
- The RR floor, risk limits, fill rule, and forbidden-claims/forbidden-fields lists are speed-bumped — no silent path around them (docs/orchestration-and-platform.md §12).
- Never fit a detector parameter against the same data used to validate it — dev/holdout split, always (docs/architecture-review.md §8, §8b).
- A frozen decision is never edited after the fact — corrections are new rows.
- Recording never pauses, for any reason.
- `README.md`'s ~37x/year aspiration is never an input to any agent, prompt, config, or task — see docs/CLAUDE.md's non-negotiables for the full statement of this rule.
- The Vercel↔AWS boundary is never trusted by network origin, only by the minted token (docs/repo-structure.md §5).
- No paid data sources in v1.
- Append to dev-journal.md (this repo's local one) after every change or decision — see docs/CLAUDE.md for format.

If a task seems to need something not covered by any of the above, that's a signal to stop and ask, not to invent it.
