#!/usr/bin/env python3
"""
Phase 2.2 — verify Supabase is ready for / after Google Sheet sync.

Checks:
  1. Migration applied (questions.external_id, upsert unique keys)
  2. Optional: sample sheet rows landed in Supabase (after you run Sync to App)

Requires in .env: DATABASE_URL
Optional after sync: pass --expect-synced to assert sample content counts.

Run from repo root:
  python3 scripts/validate_phase2_2_sheet_sync.py
  python3 scripts/validate_phase2_2_sheet_sync.py --expect-synced
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENV_PATH = ROOT / ".env"

# Counts from content/google_sheet/tabs/*.csv sample rows
EXPECTED = {
    "subjects_min": 3,
    "topics_min": 3,
    "questions_with_external_id_min": 3,
    "tests_min": 3,
    "test_questions_min": 4,
    "sample_external_ids": ("Q-MED-CARD-001", "Q-MED-PULM-001", "Q-SUR-GEN-001"),
    "sample_test_titles": (
        "Medicine Mini Drill",
        "Surgery Subject Sample",
        "NEET-PG Grand Sample",
    ),
}


def load_env() -> None:
    if not ENV_PATH.exists():
        sys.exit(f"Missing {ENV_PATH}. Copy .env.example and fill in DATABASE_URL.")
    for line in ENV_PATH.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip())


def ensure_psycopg():
    try:
        import psycopg  # noqa: F401

        return
    except ImportError:
        pass

    venv_dir = ROOT / "scripts" / ".venv"
    py = venv_dir / "bin" / "python"
    if not py.exists():
        subprocess.check_call([sys.executable, "-m", "venv", str(venv_dir)])
    subprocess.check_call(
        [str(py), "-m", "pip", "install", "--quiet", "psycopg[binary]"],
    )
    os.execv(str(py), [str(py), str(Path(__file__).resolve()), *sys.argv[1:]])


def column_exists(conn, table: str, column: str) -> bool:
    row = conn.execute(
        """
        select 1 from information_schema.columns
        where table_schema = 'public' and table_name = %s and column_name = %s
        """,
        (table, column),
    ).fetchone()
    return row is not None


def constraint_exists(conn, name: str) -> bool:
    row = conn.execute(
        "select 1 from pg_constraint where conname = %s",
        (name,),
    ).fetchone()
    return row is not None


def check_migration(conn) -> list[str]:
    errors: list[str] = []

    if not column_exists(conn, "questions", "external_id"):
        errors.append(
            "questions.external_id column missing — run "
            "supabase/migrations/20260820133000_phase2_2_sheet_upsert_keys.sql"
        )
    elif not constraint_exists(conn, "questions_external_id_key"):
        errors.append("questions_external_id_key constraint missing — run Phase 2.2 migration")

    if not constraint_exists(conn, "topics_subject_id_name_key"):
        errors.append("topics_subject_id_name_key constraint missing — run Phase 2.2 migration")

    if not constraint_exists(conn, "tests_sheet_key_key"):
        errors.append(
            "tests_sheet_key_key constraint missing — run "
            "supabase/migrations/20260829240000_tests_sheet_key_upsert.sql "
            "(PostgREST cannot upsert on the Phase 4B partial title index)"
        )

    return errors


def check_synced_content(conn) -> list[str]:
    errors: list[str] = []

    def count(sql: str) -> int:
        return int(conn.execute(sql).fetchone()[0])

    subjects = count("select count(*) from public.subjects")
    topics = count("select count(*) from public.topics")
    questions_ext = count(
        "select count(*) from public.questions where external_id is not null"
    )
    tests = count("select count(*) from public.tests")
    tq = count("select count(*) from public.test_questions")

    if subjects < EXPECTED["subjects_min"]:
        errors.append(
            f"subjects: expected at least {EXPECTED['subjects_min']}, got {subjects}"
        )
    if topics < EXPECTED["topics_min"]:
        errors.append(f"topics: expected at least {EXPECTED['topics_min']}, got {topics}")
    if questions_ext < EXPECTED["questions_with_external_id_min"]:
        errors.append(
            "questions with external_id: expected at least "
            f"{EXPECTED['questions_with_external_id_min']}, got {questions_ext}"
        )
    if tests < EXPECTED["tests_min"]:
        errors.append(f"tests: expected at least {EXPECTED['tests_min']}, got {tests}")
    if tq < EXPECTED["test_questions_min"]:
        errors.append(
            f"test_questions: expected at least {EXPECTED['test_questions_min']}, got {tq}"
        )

    for ext_id in EXPECTED["sample_external_ids"]:
        row = conn.execute(
            "select external_id, correct_option from public.questions where external_id = %s",
            (ext_id,),
        ).fetchone()
        if not row:
            errors.append(f"sample question missing: external_id = {ext_id!r}")
        elif row[1] not in ("A", "B", "C", "D"):
            errors.append(f"{ext_id}: invalid correct_option {row[1]!r}")

    for title in EXPECTED["sample_test_titles"]:
        row = conn.execute(
            "select title, total_questions from public.tests where title = %s",
            (title,),
        ).fetchone()
        if not row:
            errors.append(f"sample test missing: title = {title!r}")

    # Medicine Mini Drill should link 2 questions
    row = conn.execute(
        """
        select t.total_questions, count(tq.question_id) as linked
        from public.tests t
        left join public.test_questions tq on tq.test_id = t.id
        where t.title = 'Medicine Mini Drill'
        group by t.id, t.total_questions
        """
    ).fetchone()
    if row and row[0] != row[1]:
        errors.append(
            f"Medicine Mini Drill: total_questions={row[0]} but {row[1]} link(s) in test_questions"
        )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Phase 2.2 sheet sync readiness")
    parser.add_argument(
        "--expect-synced",
        action="store_true",
        help="Also assert sample sheet rows exist in Supabase (run after Sync to App)",
    )
    args = parser.parse_args()

    load_env()
    ensure_psycopg()
    import psycopg

    database_url = os.environ.get("DATABASE_URL", "")
    if not database_url:
        sys.exit("DATABASE_URL not set in .env")

    print("Phase 2.2 validation")
    print("=" * 40)

    with psycopg.connect(database_url) as conn:
        migration_errors = check_migration(conn)
        if migration_errors:
            print("\n❌ Migration checks FAILED:")
            for e in migration_errors:
                print(f"  • {e}")
            print(
                "\nFix: Supabase Dashboard → SQL → paste and run the listed "
                "migration file(s) under supabase/migrations/"
            )
            return 1

        print("\n✅ Migration checks passed (external_id + upsert keys exist)")

        if args.expect_synced:
            sync_errors = check_synced_content(conn)
            if sync_errors:
                print("\n❌ Post-sync content checks FAILED:")
                for e in sync_errors:
                    print(f"  • {e}")
                print(
                    "\nIf you have not synced yet: Google Sheet → Medico → Sync to App, "
                    "then re-run:\n  python3 scripts/validate_phase2_2_sheet_sync.py --expect-synced"
                )
                return 1
            print("\n✅ Post-sync content checks passed (sample rows found)")
        else:
            print(
                "\nNext: In Google Sheet → Medico → Check configuration, then Sync to App.\n"
                "After a successful sync, run:\n"
                "  python3 scripts/validate_phase2_2_sheet_sync.py --expect-synced"
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
