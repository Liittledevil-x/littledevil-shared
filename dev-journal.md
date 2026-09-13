# Dev Journal — littledevil-shared

Append-only, scoped to changes local to this repo only. Cross-repo decisions (schema changes, repo-boundary
changes) go in root directory own `dev-journal.md` instead — see `docs/CLAUDE.md` for that distinction
and for the required entry format.

No entries yet — this repo hasn't been built against.

## 2026-09-12 17:35 — Roots schema migration

**Model:** GPT-5
**Pillar/task:** Roots, task 1 / build-plan 0.1
**What changed:** Added the versioned, idempotent `0001_roots.sql` migration for `patterns`, `universe_membership`, and `data_health`, plus an explicit migration runner.
**Why:** Implements the canonical table definitions in `docs/data-and-events.md` §1 before any recorder service can write data.
**Deviates from docs?:** none
**Verified by:** Applied the SQL to a fresh disposable PostgreSQL 16 database; all three tables were created successfully.

## 2026-09-14 01:15 — Remaining schema, tool schemas, versioned constants (0.1.2–0.1.7)

**Model:** claude-sonnet-5
**Pillar/task:** Roots / Group 0, phase 0.1 (Foundation & Schema)
**What changed:** Verified `0001_roots.sql` (GPT-5's prior work) column-by-column against `docs/data-and-events.md` §1 — it matches exactly, kept as-is. Added `0002_candidates_decisions.sql` (`candidates`, `decisions`, `thesis_state`), `0003_positions_risk_config.sql` (`positions`, `risk_state`, `config_changes`, `config_current`), `0004_experiments_lessons.sql` (`experiments`, `base_rate_results`, `lessons`), and `0005_treasury.sql` (the five Treasury tables from `docs/wallet-and-capital.md` §13 — `wallets`, `capital_reservations`, `orders`, `ledger_entries`, `wallet_snapshots` — plus the `positions` ALTER adding `wallet_id`/`reservation_id`/`filled_qty`/`avg_entry_price`/`fees_total`). All new tables use the four-value `wallet_mode` enum (`real`/`testnet`/`demo`/`backtest`) from the start — there was no earlier two-value draft in this schema to migrate away from. Added all 9 Anthropic tool-use schemas as versioned JSON artifacts under `src/littledevil_shared/tool_schemas/`, with a manifest and loader. Added `src/littledevil_shared/constants.py` with `FEATURE_VERSION = "0.1.0"`; left `PIVOT_LOOKBACK_K` and `ATR_TOLERANCES` explicitly `None` — these are real detector parameters that must be frozen before any study runs and are not Claude Code's to guess.
**Why:** Implements the remainder of `docs/data-and-events.md` §1 and `docs/wallet-and-capital.md` §13's schema (per its own §15, the five Treasury tables belong in Group 0's initial migration, not deferred to when Treasury becomes a running service). Tool schemas per `docs/tool-schemas.md`, versioned now per `docs/repo-structure.md` §3 even though no agent calls them until the Decision Room exists (Stage 3+).
**Deviates from docs?:** none. `k` and ATR tolerances are flagged as open, not guessed — per `build-plan.md` §3 step 5, this was surfaced to Omar in the Stage 0 plan rather than defaulted.
**Verified by:** All five migrations applied cleanly, in order, on a fresh disposable PostgreSQL 16 database (via Docker). Full `positions` table schema inspected post-migration to confirm the ALTER succeeded with correct types/FKs. 12 pytest tests pass, including a property test (`test_wallet_invariant.py`) that replays a synthetic reserve→deploy→return→realize→fee sequence and asserts `cash_free + cash_reserved + cash_deployed + Σrealized_pnl − Σfees` equals the wallet's running equity after every step. All 9 tool schemas load via the new loader and validate structurally (each has `name`, non-empty `description`, and a well-formed `input_schema`).
