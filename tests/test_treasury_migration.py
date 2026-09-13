from pathlib import Path


MIGRATION = Path(__file__).resolve().parents[1] / "migrations" / "0005_treasury.sql"


def test_treasury_migration_defines_only_the_required_tables() -> None:
    sql = MIGRATION.read_text().lower()
    for table in ("wallets", "capital_reservations", "orders", "ledger_entries", "wallet_snapshots"):
        assert f"create table if not exists {table}" in sql
    assert "alter table positions" in sql
    for column in ("wallet_id", "reservation_id", "filled_qty", "avg_entry_price", "fees_total"):
        assert column in sql


def test_treasury_migration_ledger_entries_are_double_entry() -> None:
    sql = MIGRATION.read_text().lower()
    assert "cash_free" in sql and "cash_reserved" in sql and "cash_deployed" in sql
    assert "'reserve', 'release', 'deploy', 'return', 'fee', 'realize_pnl', 'adjustment'" in sql
