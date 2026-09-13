-- Stage 0 / Roots.  The canonical definitions are docs/data-and-events.md §1.

CREATE TABLE IF NOT EXISTS positions (
  id UUID PRIMARY KEY,
  candidate_id UUID NOT NULL REFERENCES candidates(id),
  wallet_mode TEXT NOT NULL
    CHECK (wallet_mode IN ('real', 'testnet', 'demo', 'backtest')),
  entry_type TEXT NOT NULL
    CHECK (entry_type IN ('limit', 'stop')),
  entry_price NUMERIC,
  stop NUMERIC NOT NULL,
  targets NUMERIC[] NOT NULL,
  allocation_plan JSONB NOT NULL,
  filled_at TIMESTAMPTZ,
  fill_price NUMERIC,
  slippage_modeled_bps NUMERIC,
  slippage_actual_bps NUMERIC,
  closed_at TIMESTAMPTZ,
  close_reason TEXT
    CHECK (close_reason IN ('stop', 'target', 'time_stop', 'session_end', 'model_exit', 'abandon')),
  realized_r NUMERIC,
  fees_paid NUMERIC,
  exchange_order_id TEXT
);

CREATE TABLE IF NOT EXISTS risk_state (
  wallet_mode TEXT NOT NULL,
  trading_day DATE NOT NULL,
  realized_pnl_pct NUMERIC NOT NULL DEFAULT 0,
  unrealized_pnl_pct NUMERIC NOT NULL DEFAULT 0,
  open_risk_pct NUMERIC NOT NULL DEFAULT 0,
  exposure_by_cluster JSONB NOT NULL DEFAULT '{}',
  daily_target_hit BOOLEAN NOT NULL DEFAULT FALSE,
  daily_loss_halt_hit BOOLEAN NOT NULL DEFAULT FALSE,
  drawdown_from_peak_pct NUMERIC NOT NULL DEFAULT 0,
  PRIMARY KEY (wallet_mode, trading_day)
);

CREATE TABLE IF NOT EXISTS config_changes (
  id UUID PRIMARY KEY,
  key TEXT NOT NULL,
  wallet_mode TEXT,
  old_value JSONB,
  new_value JSONB NOT NULL,
  speed_bumped BOOLEAN NOT NULL,
  changed_by TEXT NOT NULL DEFAULT 'omar',
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS config_current (
  key TEXT NOT NULL,
  wallet_mode TEXT NOT NULL DEFAULT '*',
  value JSONB NOT NULL,
  PRIMARY KEY (key, wallet_mode)
);
