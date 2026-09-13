from pathlib import Path


MIGRATION = Path(__file__).resolve().parents[1] / "migrations" / "0003_positions_risk_config.sql"


def test_positions_risk_config_migration_defines_only_the_required_tables() -> None:
    sql = MIGRATION.read_text().lower()
    for table in ("positions", "risk_state", "config_changes", "config_current"):
        assert f"create table if not exists {table}" in sql
    assert "allocation_plan" in sql
    assert "drawdown_from_peak_pct" in sql
