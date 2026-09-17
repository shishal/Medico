#!/usr/bin/env python3
"""Validate the one-file Questions CSV migration and optional live sync."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import uuid
from pathlib import Path

from sync_content_csv import DEFAULT_CSV, read_rows


ROOT = Path(__file__).resolve().parents[1]
ENV_PATH = ROOT / ".env"


def load_env() -> None:
    if not ENV_PATH.exists():
        sys.exit(f"Missing {ENV_PATH}. Copy .env.example and fill in DATABASE_URL.")
    for raw in ENV_PATH.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip())


def ensure_psycopg() -> None:
    try:
        import psycopg  # noqa: F401

        return
    except ImportError:
        pass
    venv_dir = ROOT / "scripts" / ".venv"
    py = venv_dir / "bin" / "python"
    if not py.exists():
        subprocess.check_call([sys.executable, "-m", "venv", str(venv_dir)])
    subprocess.check_call([str(py), "-m", "pip", "install", "--quiet", "psycopg[binary]"])
    os.execv(str(py), [str(py), str(Path(__file__).resolve()), *sys.argv[1:]])


def generated_id(row: dict[str, str]) -> str:
    options = "".join(row.get(key, "").strip() for key in (
        "option_a", "option_b", "option_c", "option_d", "correct_option"
    ))
    kind = row.get("kind", "").strip().lower() or ("mcq" if options else "pyq_theory")
    normalized = "|".join((
        " ".join(row["subject_name"].lower().split()),
        kind,
        " ".join(row["question_text"].lower().split()),
    ))
    return "CSV-" + hashlib.md5(normalized.encode()).hexdigest()[:24].upper()  # noqa: S324


def check_migration(conn) -> list[str]:
    errors: list[str] = []
    column = conn.execute(
        """
        select 1 from information_schema.columns
        where table_schema = 'public' and table_name = 'questions'
          and column_name = 'content_sync_source'
        """
    ).fetchone()
    if not column:
        errors.append("questions.content_sync_source is missing")
    function = conn.execute(
        "select to_regprocedure('public.sync_content_csv(jsonb,boolean)')"
    ).fetchone()[0]
    if function is None:
        errors.append("sync_content_csv(jsonb, boolean) is missing")
    return errors


def check_sample_csv() -> tuple[list[dict[str, str]], list[str]]:
    try:
        rows = read_rows(DEFAULT_CSV)
    except (OSError, ValueError) as error:
        return [], [str(error)]
    errors: list[str] = []
    if not rows:
        errors.append("Questions.csv has no content rows")
    mcq_fields = ("option_a", "option_b", "option_c", "option_d", "correct_option")
    if not any(not any(row.get(field) for field in mcq_fields) for row in rows):
        errors.append("Questions.csv needs a minimal theory example")
    if not any(row.get("option_a") and row.get("correct_option") for row in rows):
        errors.append("Questions.csv needs an MCQ example")
    for index, row in enumerate(rows, start=2):
        year = row.get("exam_year", "")
        paper = row.get("paper_name", "")
        uni = row.get("university_code", "")
        filled = sum(1 for value in (year, paper, uni) if value)
        if filled not in (0, 3):
            errors.append(
                f"Questions.csv row {index}: university_code, exam_year, and "
                "paper_name must be filled together"
            )
    if not any(
        row.get("university_code") and row.get("exam_year") and row.get("paper_name")
        for row in rows
    ):
        errors.append("Questions.csv needs a paper-linked example with university_code")
    return rows, errors


def check_synced_content(conn, rows: list[dict[str, str]]) -> list[str]:
    ids = [generated_id(row) for row in rows]
    found = {
        row[0]
        for row in conn.execute(
            "select external_id from public.questions where external_id = any(%s)",
            (ids,),
        ).fetchall()
    }
    return [f"synced question missing: {external_id}" for external_id in ids if external_id not in found]


def rpc(conn, rows: list[dict[str, str]], apply: bool) -> dict:
    return conn.execute(
        "select public.sync_content_csv(%s::jsonb, %s)",
        (json.dumps(rows), apply),
    ).fetchone()[0]


def exercise_sync(conn) -> list[str]:
    """Exercise apply inside a transaction that is always rolled back."""
    errors: list[str] = []
    suffix = uuid.uuid4().hex[:8]
    valid = [
        {"subject_name": f"CSV Test A {suffix}", "question_text": "Minimal theory"},
        {
            "subject_name": f"CSV Test A {suffix}",
            "question_text": "Complete MCQ",
            "option_a": "A", "option_b": "B", "option_c": "C", "option_d": "D",
            "correct_option": "A",
            "topic_name": "Shared topic",
        },
        {
            "subject_name": f"CSV Test B {suffix}",
            "question_text": "Same-named topic in another subject",
            "topic_name": "Shared topic",
        },
    ]
    invalid_cases = [
        ([{"subject_name": "X", "question_text": "Partial MCQ", "option_a": "A"}], "option_b"),
        ([{"subject_name": "X", "question_text": "Partial paper", "exam_year": "2024"}], "paper_name"),
        (
            [{
                "subject_name": "X",
                "question_text": "Paper without university",
                "exam_year": "2024",
                "paper_name": "Paper I",
            }],
            "university_code",
        ),
        ([{"subject_name": "X", "question_text": "Partial book", "textbook_title": "Book"}], "page"),
        ([{"subject_name": "X", "question_text": "Lesson only", "lesson_name": "Lesson"}], "topic_name"),
    ]

    try:
        preview = rpc(conn, valid, False)
        if not preview.get("ok") or preview.get("applied"):
            errors.append("valid preview did not succeed without writes")

        for rows, expected in invalid_cases:
            result = rpc(conn, rows, False)
            messages = " ".join(result.get("errors", []))
            if result.get("ok") or expected not in messages:
                errors.append(f"invalid case did not report {expected}")

        marker = f"VALIDATOR-{suffix}"
        conn.execute(
            """
            insert into public.questions
              (external_id, kind, question_text, difficulty, required_plan, is_active)
            values (%s, 'pyq_theory', 'Non CSV control', 'should', 'free', true)
            """,
            (marker,),
        )
        result = rpc(conn, valid, True)
        if not result.get("ok") or not result.get("applied"):
            errors.append("valid apply failed")

        if not conn.execute(
            "select 1 from public.questions where external_id = %s", (marker,)
        ).fetchone():
            errors.append("snapshot deleted a non-CSV control question")

        topics = conn.execute(
            """
            select s.name, t.name
            from public.topics t join public.subjects s on s.id = t.subject_id
            where s.name in (%s, %s) and t.name = 'Shared topic'
            """,
            (f"CSV Test A {suffix}", f"CSV Test B {suffix}"),
        ).fetchall()
        if len(topics) != 2:
            errors.append("same topic name did not resolve independently per subject")

        second = rpc(conn, valid, False)
        if second.get("counts", {}).get("insert") != 0 or second.get("counts", {}).get("delete") != 0:
            errors.append("unchanged second sync is not idempotent")

        reduced = valid[:1]
        removal = rpc(conn, reduced, False)
        if removal.get("counts", {}).get("delete", 0) < 2:
            errors.append("snapshot preview did not report removed managed questions")
    finally:
        conn.rollback()
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--expect-synced", action="store_true")
    parser.add_argument(
        "--exercise-sync",
        action="store_true",
        help="Run transactional importer tests against DATABASE_URL, then roll everything back",
    )
    args = parser.parse_args()

    rows, csv_errors = check_sample_csv()
    if csv_errors:
        for error in csv_errors:
            print(f"ERROR: {error}")
        return 1
    print(f"Questions.csv: {len(rows)} valid sample row(s)")

    load_env()
    ensure_psycopg()
    import psycopg

    database_url = os.environ.get("DATABASE_URL", "")
    if not database_url:
        sys.exit("DATABASE_URL not set in .env")

    with psycopg.connect(database_url) as conn:
        errors = check_migration(conn)
        if args.expect_synced and not errors:
            errors.extend(check_synced_content(conn, rows))
        if args.exercise_sync and not errors:
            print("Exercising sync in a rollback-only transaction...")
            errors.extend(exercise_sync(conn))
        if errors:
            for error in errors:
                print(f"ERROR: {error}")
            return 1

    print("CSV sync validation passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
