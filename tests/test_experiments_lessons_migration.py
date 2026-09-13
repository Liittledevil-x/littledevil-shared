from pathlib import Path


MIGRATION = Path(__file__).resolve().parents[1] / "migrations" / "0004_experiments_lessons.sql"


def test_experiments_lessons_migration_defines_only_the_required_tables() -> None:
    sql = MIGRATION.read_text().lower()
    for table in ("experiments", "base_rate_results", "lessons"):
        assert f"create table if not exists {table}" in sql
    assert "effective_sample_size" in sql
    assert "'draft', 'promoted', 'rejected'" in sql
