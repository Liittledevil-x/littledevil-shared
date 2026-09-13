-- Stage 0 / Roots.  The canonical definitions are docs/data-and-events.md §1.

CREATE TABLE IF NOT EXISTS candidates (
  id UUID PRIMARY KEY,
  symbol TEXT NOT NULL,
  venue TEXT NOT NULL DEFAULT 'binance_spot',
  wallet_mode TEXT NOT NULL
    CHECK (wallet_mode IN ('real', 'testnet', 'demo', 'backtest')),
  state TEXT NOT NULL,
  setup_type TEXT
    CHECK (setup_type IN ('T1', 'T2', 'T3')),
  pattern_id UUID REFERENCES patterns(id),
  cluster_id TEXT,
  rank_score NUMERIC,
  rank_components JSONB,
  manual_trigger BOOLEAN NOT NULL DEFAULT FALSE,
  shadow BOOLEAN NOT NULL DEFAULT FALSE,
  handoff_from UUID REFERENCES candidates(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_candidates_wallet_mode_state
  ON candidates (wallet_mode, state);

-- Append-only: rows are never edited after write, only inserted (docs/CLAUDE.md non-negotiables).
CREATE TABLE IF NOT EXISTS decisions (
  id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL REFERENCES candidates(id),
  wallet_mode TEXT NOT NULL
    CHECK (wallet_mode IN ('real', 'testnet', 'demo', 'backtest')),
  role TEXT NOT NULL
    CHECK (role IN ('htf_prior', 'escalation', 'demon', 'adversary', 'reviewer', 'analyst')),
  verdict TEXT,
  packet_hash TEXT NOT NULL,
  packet_json JSONB NOT NULL,
  prompt_version TEXT NOT NULL,
  model_id TEXT NOT NULL,
  response_json JSONB NOT NULL,
  thinking_trace TEXT,
  tool_calls_json JSONB,
  estimated_cost_usd NUMERIC NOT NULL,
  verdict_source TEXT NOT NULL DEFAULT 'model'
    CHECK (verdict_source IN ('model', 'fallback')),
  escalation_mode TEXT
    CHECK (escalation_mode IN ('llm', 'deterministic')),
  review_tag TEXT
    CHECK (review_tag IN ('data_gap', 'prompting_or_strategy', 'calibration_risk', 'ok')),
  review_note TEXT,
  truncated_blocks TEXT[],
  packet_as_of TIMESTAMPTZ NOT NULL,
  decision_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_decisions_candidate_created
  ON decisions (candidate_id, created_at);

CREATE INDEX IF NOT EXISTS idx_decisions_wallet_mode_verdict
  ON decisions (wallet_mode, verdict);

CREATE TABLE IF NOT EXISTS thesis_state (
  id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL REFERENCES candidates(id),
  version INT NOT NULL,
  verdict TEXT NOT NULL,
  invalidation_condition TEXT,
  opposing_evidence JSONB,
  superseded_by UUID REFERENCES thesis_state(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (candidate_id, version)
);
