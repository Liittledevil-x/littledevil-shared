"""Property test for the wallet-and-capital.md §13 double-entry invariant:

    cash_free + cash_reserved + cash_deployed + sum(realized_pnl) - sum(fees) == starting_equity

Replays a synthetic sequence of ledger transactions against a real Postgres
database and asserts the invariant holds after every one. Requires
DATABASE_URL to point at a disposable database with the migrations applied;
skipped otherwise.

Accounting convention used here: cash_free/cash_reserved/cash_deployed track
cash at cost basis only -- reserving, deploying, and returning capital are
zero-sum transfers among the three. Realized gains/losses and fees never
move cash-account balances directly; they are recorded purely in the pnl
and fees accounts. This is what makes the identity an invariant against the
fixed `starting_equity` constant: cash-at-cost plus cumulative pnl minus
cumulative fees is definitionally today's total equity, and the wallet's
`starting_equity` column is the value of that same expression at t=0 (before
any pnl or fees exist), so the two sides match by construction at every
step, not only when net pnl happens to be zero.
"""

from __future__ import annotations

import os
import uuid

import pytest

psycopg = pytest.importorskip("psycopg")

DATABASE_URL = os.getenv("DATABASE_URL")
pytestmark = pytest.mark.skipif(not DATABASE_URL, reason="DATABASE_URL not set")


def _balance(cursor, wallet_id: str) -> dict[str, float]:
    cursor.execute(
        """
        SELECT account, COALESCE(SUM(amount), 0)
        FROM ledger_entries
        WHERE wallet_id = %s
        GROUP BY account
        """,
        (wallet_id,),
    )
    return {account: float(total) for account, total in cursor.fetchall()}


def _assert_invariant(cursor, wallet_id: str, starting_equity: float) -> None:
    balances = _balance(cursor, wallet_id)
    cash_free = balances.get("cash_free", 0.0)
    cash_reserved = balances.get("cash_reserved", 0.0)
    cash_deployed = balances.get("cash_deployed", 0.0)
    realized_pnl = balances.get("pnl", 0.0)
    fees = balances.get("fees", 0.0)
    total = cash_free + cash_reserved + cash_deployed + realized_pnl - fees
    assert total == pytest.approx(starting_equity), (
        f"invariant broken: {cash_free=} {cash_reserved=} {cash_deployed=} "
        f"{realized_pnl=} {fees=} -> {total=} != {starting_equity=}"
    )


def _insert_entries(cursor, wallet_id: str, legs: list[tuple[str, str, float]]) -> None:
    txn_id = str(uuid.uuid4())
    for entry_type, account, amount in legs:
        cursor.execute(
            """
            INSERT INTO ledger_entries (wallet_id, entry_type, account, amount, txn_id, as_of)
            VALUES (%s, %s, %s, %s, %s, now())
            """,
            (wallet_id, entry_type, account, amount, txn_id),
        )


def test_wallet_ledger_replay_holds_invariant() -> None:
    starting_equity = 1000.0
    equity = starting_equity  # today's cash-at-cost + pnl - fees; grows/shrinks as we go
    wallet_id = str(uuid.uuid4())

    with psycopg.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO wallets
                    (id, wallet_mode, base_currency, starting_equity, equity_realized,
                     session_start_equity, peak_equity, fee_schedule)
                VALUES (%s, 'backtest', 'USDT', %s, %s, %s, %s, '{}'::jsonb)
                """,
                (wallet_id, starting_equity, starting_equity, starting_equity, starting_equity),
            )

            # Opening balance: starting equity lands entirely in cash_free.
            _insert_entries(cur, wallet_id, [("adjustment", "cash_free", starting_equity)])
            _assert_invariant(cur, wallet_id, equity)

            # Reserve $100 for a candidate about to be armed (cost-basis transfer).
            _insert_entries(
                cur, wallet_id,
                [("reserve", "cash_free", -100.0), ("reserve", "cash_reserved", 100.0)],
            )
            _assert_invariant(cur, wallet_id, equity)

            # Deploy the reservation on fill (cost-basis transfer).
            _insert_entries(
                cur, wallet_id,
                [("deploy", "cash_reserved", -100.0), ("deploy", "cash_deployed", 100.0)],
            )
            _assert_invariant(cur, wallet_id, equity)

            # Close the position: the $100 cost basis transfers back to
            # cash_free (cost-basis transfer, zero-sum). The $20 realized
            # gain and $1 fee are recorded only in pnl/fees -- they never
            # touch a cash account directly in this model -- so equity
            # itself grows by the net of the two.
            _insert_entries(
                cur, wallet_id,
                [("return", "cash_deployed", -100.0), ("return", "cash_free", 100.0)],
            )
            _insert_entries(cur, wallet_id, [("realize_pnl", "pnl", 20.0)])
            equity += 20.0
            _assert_invariant(cur, wallet_id, equity)

            _insert_entries(cur, wallet_id, [("fee", "fees", 1.0)])
            equity -= 1.0
            _assert_invariant(cur, wallet_id, equity)

            conn.rollback()
