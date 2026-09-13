from pathlib import Path


MIGRATION = Path(__file__).resolve().parents[1] / "migrations" / "0001_roots.sql"


def test_roots_migration_defines_only_the_required_tables() -> None:
    sql = MIGRATION.read_text().lower()
    for table in ("patterns", "universe_membership", "data_health"):
        assert f"create table if not exists {table}" in sql
    assert "eligibility_basis" in sql
    assert "gap_started_at" in sql
    assert "feature_version" in sql
