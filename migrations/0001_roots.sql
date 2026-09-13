-- Stage 0 / Roots.  The canonical definitions are docs/data-and-events.md §1.

CREATE TABLE IF NOT EXISTS patterns (
  id UUID PRIMARY KEY,
  symbol TEXT NOT NULL,
  timeframe TEXT NOT NULL,
  pattern_type TEXT NOT NULL,
  upper_line JSONB NOT NULL,
  lower_line JSONB NOT NULL,
  touches INT NOT NULL DEFAULT 0,
  apex_fraction NUMERIC,
  width_now_pct NUMERIC,
  preceded_by_impulse BOOLEAN NOT NULL DEFAULT FALSE,
  impulse_height_atr NUMERIC,
  tf_confluence TEXT[] NOT NULL DEFAULT '{}',
  valid BOOLEAN NOT NULL DEFAULT TRUE,
  break_flag BOOLEAN NOT NULL DEFAULT FALSE,
  retest_flag BOOLEAN NOT NULL DEFAULT FALSE,
  pivot_known_at TIMESTAMPTZ NOT NULL,
  feature_version TEXT NOT NULL,
  bar_time TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS universe_membership (
  symbol TEXT NOT NULL,
  as_of_date DATE NOT NULL,
  eligible BOOLEAN NOT NULL,
  eligibility_basis TEXT NOT NULL DEFAULT 'full'
    CHECK (eligibility_basis IN ('full', 'proxy')),
  criteria_snapshot JSONB NOT NULL,
  consecutive_pass_days INT NOT NULL DEFAULT 0,
  consecutive_fail_days INT NOT NULL DEFAULT 0,
  PRIMARY KEY (symbol, as_of_date)
);

CREATE TABLE IF NOT EXISTS data_health (
  channel TEXT PRIMARY KEY,
  last_message_at TIMESTAMPTZ,
  gap_started_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'ok'
    CHECK (status IN ('ok', 'stale', 'suspended'))
);
