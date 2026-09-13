-- Stage 0 / Roots.  The canonical definitions are docs/data-and-events.md §1.

-- Append-only: every attempted configuration, winners and losers alike (architecture-review.md §8).
CREATE TABLE IF NOT EXISTS experiments (
  id UUID PRIMARY KEY,
  dataset_id TEXT NOT NULL,
  feature_version TEXT NOT NULL,
  prompt_version TEXT NOT NULL,
  model_id TEXT NOT NULL,
  config_hash TEXT NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS base_rate_results (
  id UUID PRIMARY KEY,
  experiment_id UUID NOT NULL REFERENCES experiments(id),
  evidence_class TEXT NOT NULL
    CHECK (evidence_class IN ('A', 'B')),
  setup_type TEXT NOT NULL,
  pattern_type TEXT,
  conditions JSONB NOT NULL,
  regime TEXT,
  sample_size INT NOT NULL,
  effective_sample_size INT NOT NULL,
  hit_rate NUMERIC NOT NULL,
  ci_low NUMERIC NOT NULL,
  ci_high NUMERIC NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_base_rate_results_setup_pattern
  ON base_rate_results (setup_type, pattern_type);

CREATE TABLE IF NOT EXISTS lessons (
  id UUID PRIMARY KEY,
  setup_type TEXT NOT NULL,
  pattern_type TEXT,
  regime TEXT,
  lesson_text TEXT NOT NULL,
  sample_size_note TEXT NOT NULL,
  source_decision_ids UUID[],
  status TEXT NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'promoted', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  decided_at TIMESTAMPTZ,
  decided_by TEXT
);
