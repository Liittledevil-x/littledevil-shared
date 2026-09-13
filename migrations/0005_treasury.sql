-- Stage 0 / Roots.  The canonical definitions are docs/wallet-and-capital.md §13
-- and docs/data-and-events.md §1 (positions, as amended by the Treasury layer).
--
-- candidates/decisions/positions already carry the four-value wallet_mode
-- CHECK ('real','testnet','demo','backtest') as of migrations 0002/0003 --
-- there is no earlier two-value draft in this schema to migrate away from.

CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY,
  wallet_mode TEXT NOT NULL
    CHECK (wallet_mode IN ('real', 'testnet', 'demo', 'backtest')),
  run_id UUID,
  base_currency TEXT NOT NULL DEFAULT 'USDT',
  starting_equity NUMERIC NOT NULL,
  equity_realized NUMERIC NOT NULL,
  session_start_equity NUMERIC NOT NULL,
  peak_equity NUMERIC NOT NULL,
  fee_schedule JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (wallet_mode, run_id)
);

CREATE TABLE IF NOT EXISTS capital_reservations (
  id UUID PRIMARY KEY,
  wallet_id UUID NOT NULL REFERENCES wallets(id),
  candidate_id UUID NOT NULL REFERENCES candidates(id),
  decision_id UUID NOT NULL REFERENCES decisions(id),
  client_order_id TEXT NOT NULL UNIQUE,
  cluster_id TEXT NOT NULL,
  notional NUMERIC NOT NULL,
  qty NUMERIC NOT NULL,
  risk_amount NUMERIC NOT NULL,
  status TEXT NOT NULL
    CHECK (status IN ('held', 'filled', 'partial', 'expired', 'cancelled', 'rejected')),
  filled_qty NUMERIC NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ NOT NULL,
  released_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY,
  reservation_id UUID NOT NULL REFERENCES capital_reservations(id),
  position_id UUID REFERENCES positions(id),
  venue_order_id TEXT,
  side TEXT NOT NULL
    CHECK (side IN ('buy', 'sell')),
  order_type TEXT NOT NULL
    CHECK (order_type IN ('limit', 'market', 'stop')),
  price NUMERIC,
  qty NUMERIC NOT NULL,
  filled_qty NUMERIC NOT NULL DEFAULT 0,
  avg_fill_price NUMERIC,
  fee_paid NUMERIC NOT NULL DEFAULT 0,
  fee_asset TEXT,
  status TEXT NOT NULL,
  reject_reason TEXT,
  submitted_at TIMESTAMPTZ NOT NULL,
  eligible_at TIMESTAMPTZ NOT NULL
);

-- Append-only, double-entry: paired entries for one txn_id sum to zero.
CREATE TABLE IF NOT EXISTS ledger_entries (
  id BIGSERIAL PRIMARY KEY,
  wallet_id UUID NOT NULL REFERENCES wallets(id),
  entry_type TEXT NOT NULL
    CHECK (entry_type IN ('reserve', 'release', 'deploy', 'return', 'fee', 'realize_pnl', 'adjustment')),
  account TEXT NOT NULL
    CHECK (account IN ('cash_free', 'cash_reserved', 'cash_deployed', 'pnl', 'fees')),
  amount NUMERIC NOT NULL,
  txn_id UUID NOT NULL,
  reservation_id UUID REFERENCES capital_reservations(id),
  position_id UUID REFERENCES positions(id),
  as_of TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wallet_snapshots (
  wallet_id UUID NOT NULL REFERENCES wallets(id),
  as_of TIMESTAMPTZ NOT NULL,
  equity_realized NUMERIC NOT NULL,
  equity_marked NUMERIC NOT NULL,
  cash_available NUMERIC NOT NULL,
  cash_reserved NUMERIC NOT NULL,
  cash_deployed NUMERIC NOT NULL,
  open_risk NUMERIC NOT NULL,
  PRIMARY KEY (wallet_id, as_of)
);

-- positions gains Treasury linkage and partial-fill fields (wallet-and-capital.md §13).
ALTER TABLE positions
  ADD COLUMN IF NOT EXISTS wallet_id UUID REFERENCES wallets(id),
  ADD COLUMN IF NOT EXISTS reservation_id UUID REFERENCES capital_reservations(id),
  ADD COLUMN IF NOT EXISTS filled_qty NUMERIC,
  ADD COLUMN IF NOT EXISTS avg_entry_price NUMERIC,
  ADD COLUMN IF NOT EXISTS fees_total NUMERIC;
