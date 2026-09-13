from pathlib import Path


MIGRATION = Path(__file__).resolve().parents[1] / "migrations" / "0002_candidates_decisions.sql"


def test_candidates_decisions_migration_defines_only_the_required_tables() -> None:
    sql = MIGRATION.read_text().lower()
    for table in ("candidates", "decisions", "thesis_state"):
        assert f"create table if not exists {table}" in sql
    assert "escalation_mode" in sql
    assert "verdict_source" in sql
    assert "'real', 'testnet', 'demo', 'backtest'" in sql
