"""Small, explicit migration runner for the shared Postgres schema."""

from __future__ import annotations

import argparse
import os
from pathlib import Path


MIGRATIONS_DIR = Path(__file__).resolve().parents[2] / "migrations"


def migration_files() -> list[Path]:
    return sorted(MIGRATIONS_DIR.glob("*.sql"))


def apply(database_url: str) -> list[str]:
    """Apply migrations once, recording their immutable filenames in Postgres."""
    try:
        import psycopg
    except ImportError as exc:  # pragma: no cover - depends on deployment extras
        raise RuntimeError("Install littledevil-shared with its psycopg dependency.") from exc

    applied: list[str] = []
    with psycopg.connect(database_url) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    filename TEXT PRIMARY KEY,
                    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
                )
                """
            )
            for migration in migration_files():
                cursor.execute(
                    "SELECT 1 FROM schema_migrations WHERE filename = %s", (migration.name,)
                )
                if cursor.fetchone():
                    continue
                cursor.execute(migration.read_text())
                cursor.execute("INSERT INTO schema_migrations (filename) VALUES (%s)", (migration.name,))
                applied.append(migration.name)
        connection.commit()
    return applied


def main() -> None:
    parser = argparse.ArgumentParser(description="Apply LittleDevil shared schema migrations.")
    parser.add_argument("--database-url", default=os.getenv("DATABASE_URL"))
    args = parser.parse_args()
    if not args.database_url:
        parser.error("--database-url or DATABASE_URL is required")
    for filename in apply(args.database_url):
        print(f"applied {filename}")


if __name__ == "__main__":
    main()
