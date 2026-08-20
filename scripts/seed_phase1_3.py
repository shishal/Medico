#!/usr/bin/env python3
"""
Phase 1.3 — seed placeholder content for testing.

Inserts subjects, topics, ~200 questions (free/pro/elite mix), and one test
of each type — including a sectional grand test (5 × 36 = 180, NEET-PG shape).

Uses DATABASE_URL from .env (scripts only; never commit .env). Prefer this over
putting the service_role key in the Flutter app — same privilege boundary as
docs/03_BUILD_PLAN.md notes for seed/sync tooling.

Idempotent: re-running deletes prior seed rows (source = 'seed:phase1.3' and
titles prefixed with '[SEED]') then re-inserts.
"""

from __future__ import annotations

import os
import random
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENV_PATH = ROOT / ".env"
SEED_SOURCE = "seed:phase1.3"
SEED_TITLE_PREFIX = "[SEED]"

SUBJECTS = [
    "Medicine",
    "Surgery",
    "Obstetrics & Gynaecology",
    "Pediatrics",
    "Pharmacology",
    "Pathology",
]

TOPICS_BY_SUBJECT = {
    "Medicine": ["Cardiology", "Pulmonology", "Gastroenterology", "Neurology"],
    "Surgery": ["General Surgery", "Orthopedics", "Urology", "Neurosurgery"],
    "Obstetrics & Gynaecology": ["Antenatal Care", "Labour", "Gynaecology", "Infertility"],
    "Pediatrics": ["Neonatology", "Growth & Development", "Infectious Disease", "Nutrition"],
    "Pharmacology": ["Autonomics", "Antibiotics", "CNS Drugs", "Chemotherapy"],
    "Pathology": ["General Pathology", "Hematology", "Systemic Pathology", "Neoplasia"],
}

TAG_NAMES = ["PYQ", "HighYield", "RecentUpdate", "OneLiner", "ClinicalVignette"]

QUESTION_COUNT = 200
# ~80% free, remainder split pro/elite for plan-gating UI tests
FREE_COUNT = 160
PRO_COUNT = 30
ELITE_COUNT = 10

OPTIONS = ("A", "B", "C", "D")
DIFFICULTIES = ("easy", "medium", "hard")


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
    """Use a local venv under scripts/.venv so we don't touch system Python."""
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


def table_exists(conn, name: str) -> bool:
    row = conn.execute(
        """
        select 1
        from information_schema.tables
        where table_schema = 'public' and table_name = %s
        """,
        (name,),
    ).fetchone()
    return row is not None


def clear_prior_seed(conn) -> None:
    """Remove previous Phase 1.3 seed so re-runs stay idempotent."""
    # test_questions cascade when tests are deleted; questions referenced by
    # non-seed tests would block delete — we only delete seed-sourced questions.
    conn.execute(
        """
        delete from public.test_questions
        where test_id in (
          select id from public.tests where title like %s
        )
        """,
        (f"{SEED_TITLE_PREFIX}%",),
    )
    conn.execute(
        "delete from public.tests where title like %s",
        (f"{SEED_TITLE_PREFIX}%",),
    )

    if table_exists(conn, "question_tags"):
        conn.execute(
            """
            delete from public.question_tags
            where question_id in (
              select id from public.questions where source = %s
            )
            """,
            (SEED_SOURCE,),
        )

    conn.execute(
        "delete from public.questions where source = %s",
        (SEED_SOURCE,),
    )

    # Topics/subjects may be shared with future real content — only wipe
    # topics that have no remaining questions, then subjects with no topics.
    conn.execute(
        """
        delete from public.topics t
        where not exists (
          select 1 from public.questions q where q.topic_id = t.id
        )
        and t.name = any(%s)
        """,
        ([t for topics in TOPICS_BY_SUBJECT.values() for t in topics],),
    )
    conn.execute(
        """
        delete from public.subjects s
        where not exists (
          select 1 from public.topics t where t.subject_id = s.id
        )
        and s.name = any(%s)
        """,
        (SUBJECTS,),
    )


def seed_subjects_and_topics(conn) -> dict[str, list[str]]:
    """Returns {subject_name: [topic_id, ...]}."""
    topic_ids_by_subject: dict[str, list[str]] = {}

    for order, name in enumerate(SUBJECTS):
        row = conn.execute(
            """
            insert into public.subjects (name, display_order)
            values (%s, %s)
            on conflict (name) do update set display_order = excluded.display_order
            returning id
            """,
            (name, order),
        ).fetchone()
        subject_id = str(row[0])

        topic_ids: list[str] = []
        for t_order, topic_name in enumerate(TOPICS_BY_SUBJECT[name]):
            existing = conn.execute(
                """
                select id from public.topics
                where subject_id = %s::uuid and name = %s
                """,
                (subject_id, topic_name),
            ).fetchone()
            if existing:
                topic_id = str(existing[0])
            else:
                inserted = conn.execute(
                    """
                    insert into public.topics (subject_id, name, display_order)
                    values (%s::uuid, %s, %s)
                    returning id
                    """,
                    (subject_id, topic_name, t_order),
                ).fetchone()
                topic_id = str(inserted[0])
            topic_ids.append(topic_id)

        topic_ids_by_subject[name] = topic_ids

    return topic_ids_by_subject


def plan_for_index(i: int) -> str:
    if i < FREE_COUNT:
        return "free"
    if i < FREE_COUNT + PRO_COUNT:
        return "pro"
    return "elite"


def seed_questions(conn, topic_ids_by_subject: dict[str, list[str]]) -> list[str]:
    # Flatten (subject, topic_name, topic_id) for readable question text.
    labeled: list[tuple[str, str, str]] = []
    for subject, topic_names in TOPICS_BY_SUBJECT.items():
        for topic_name, topic_id in zip(topic_names, topic_ids_by_subject[subject]):
            labeled.append((subject, topic_name, topic_id))
    if not labeled:
        raise RuntimeError("no topics available to attach questions to")

    question_ids: list[str] = []
    for i in range(QUESTION_COUNT):
        subject, topic_name, topic_id = labeled[i % len(labeled)]
        correct = OPTIONS[i % 4]
        difficulty = DIFFICULTIES[i % 3]
        plan = plan_for_index(i)
        n = i + 1
        row = conn.execute(
            """
            insert into public.questions (
              topic_id, question_text,
              option_a, option_b, option_c, option_d,
              correct_option, explanation_text, difficulty,
              source, required_plan, is_active
            ) values (
              %s::uuid,
              %s,
              %s, %s, %s, %s,
              %s, %s, %s::question_difficulty,
              %s, %s::plan_tier, true
            )
            returning id
            """,
            (
                topic_id,
                f"Sample question {n} about {topic_name} ({subject})",
                f"Sample question {n} about {topic_name} — option A",
                f"Sample question {n} about {topic_name} — option B",
                f"Sample question {n} about {topic_name} — option C",
                f"Sample question {n} about {topic_name} — option D",
                correct,
                f"Explanation for sample question {n}: correct is {correct}.",
                difficulty,
                SEED_SOURCE,
                plan,
            ),
        ).fetchone()
        question_ids.append(str(row[0]))

    return question_ids


def seed_tags(conn, question_ids: list[str], rng: random.Random) -> None:
    if not table_exists(conn, "tags") or not table_exists(conn, "question_tags"):
        print("  tags/question_tags: skipped (tables not in schema yet — Phase 4B)")
        return

    tag_ids: list[str] = []
    for name in TAG_NAMES:
        row = conn.execute(
            """
            insert into public.tags (name) values (%s)
            on conflict (name) do update set name = excluded.name
            returning id
            """,
            (name,),
        ).fetchone()
        tag_ids.append(str(row[0]))

    for qid in question_ids:
        chosen = rng.sample(tag_ids, k=rng.randint(1, 2))
        for tid in chosen:
            conn.execute(
                """
                insert into public.question_tags (question_id, tag_id)
                values (%s::uuid, %s::uuid)
                on conflict do nothing
                """,
                (qid, tid),
            )
    print(f"  tags: OK ({len(TAG_NAMES)} tags, 1–2 per question)")


def insert_test(
    conn,
    *,
    title: str,
    description: str,
    test_type: str,
    subject_id: str | None,
    required_plan: str,
    is_sectional: bool,
    section_count: int,
    questions_per_section: int | None,
    section_duration_minutes: int | None,
    total_duration_minutes: int,
    total_questions: int,
) -> str:
    row = conn.execute(
        """
        insert into public.tests (
          title, description, test_type, subject_id, required_plan,
          is_sectional, section_count, questions_per_section,
          section_duration_minutes, total_duration_minutes, total_questions,
          correct_marks, incorrect_marks, unattempted_marks,
          is_live, is_active
        ) values (
          %s, %s, %s::test_type, %s::uuid, %s::plan_tier,
          %s, %s, %s,
          %s, %s, %s,
          4, -1, 0,
          false, true
        )
        returning id
        """,
        (
            title,
            description,
            test_type,
            subject_id,
            required_plan,
            is_sectional,
            section_count,
            questions_per_section,
            section_duration_minutes,
            total_duration_minutes,
            total_questions,
        ),
    ).fetchone()
    return str(row[0])


def link_questions(
    conn,
    test_id: str,
    question_ids: list[str],
    *,
    section_count: int = 1,
    questions_per_section: int | None = None,
) -> None:
    if questions_per_section is None:
        # Single section: order_index 0..n-1
        for order, qid in enumerate(question_ids):
            conn.execute(
                """
                insert into public.test_questions
                  (test_id, question_id, section_number, order_index)
                values (%s::uuid, %s::uuid, 1, %s)
                """,
                (test_id, qid, order),
            )
        return

    expected = section_count * questions_per_section
    if len(question_ids) != expected:
        raise ValueError(
            f"expected {expected} questions for sectional test, got {len(question_ids)}"
        )

    for i, qid in enumerate(question_ids):
        section = (i // questions_per_section) + 1
        order = i % questions_per_section
        conn.execute(
            """
            insert into public.test_questions
              (test_id, question_id, section_number, order_index)
            values (%s::uuid, %s::uuid, %s, %s)
            """,
            (test_id, qid, section, order),
        )


def seed_tests(conn, question_ids: list[str]) -> None:
    medicine_id = conn.execute(
        "select id from public.subjects where name = %s",
        ("Medicine",),
    ).fetchone()
    medicine_subject_id = str(medicine_id[0]) if medicine_id else None

    # Prefer free questions for free tests so free users can attempt them.
    free_q = question_ids[:FREE_COUNT]
    pro_q = question_ids[FREE_COUNT : FREE_COUNT + PRO_COUNT]

    # --- mini (free, 10 Q) ---
    mini_id = insert_test(
        conn,
        title=f"{SEED_TITLE_PREFIX} Mini Test — Medicine Warm-up",
        description="10-question free mini test for smoke-testing the player.",
        test_type="mini",
        subject_id=medicine_subject_id,
        required_plan="free",
        is_sectional=False,
        section_count=1,
        questions_per_section=None,
        section_duration_minutes=None,
        total_duration_minutes=15,
        total_questions=10,
    )
    link_questions(conn, mini_id, free_q[:10])

    # --- subject (free, 30 Q) ---
    subject_id = insert_test(
        conn,
        title=f"{SEED_TITLE_PREFIX} Subject Test — Medicine",
        description="Single-subject practice block.",
        test_type="subject",
        subject_id=medicine_subject_id,
        required_plan="free",
        is_sectional=False,
        section_count=1,
        questions_per_section=None,
        section_duration_minutes=None,
        total_duration_minutes=45,
        total_questions=30,
    )
    link_questions(conn, subject_id, free_q[10:40])

    # --- mock (pro, 50 Q) ---
    mock_pool = free_q[40:70] + pro_q  # 30 free + 30 pro = 60; take 50
    mock_id = insert_test(
        conn,
        title=f"{SEED_TITLE_PREFIX} Mock Test — Mixed Subjects",
        description="Pro-tier mock; mixed subjects.",
        test_type="mock",
        subject_id=None,
        required_plan="pro",
        is_sectional=False,
        section_count=1,
        questions_per_section=None,
        section_duration_minutes=None,
        total_duration_minutes=75,
        total_questions=50,
    )
    link_questions(conn, mock_id, mock_pool[:50])

    # --- grand (elite, 5 × 36 = 180, NEET-PG shape) ---
    # Need 180 distinct questions; we have 200 — use first 180.
    grand_qs = question_ids[:180]
    grand_id = insert_test(
        conn,
        title=f"{SEED_TITLE_PREFIX} NEET-PG Grand Test 1",
        description=(
            "Sectional grand test matching NEET-PG 2026 shape: "
            "5 sections × 36 questions, 42 min/section, +4/−1."
        ),
        test_type="grand",
        subject_id=None,
        required_plan="elite",
        is_sectional=True,
        section_count=5,
        questions_per_section=36,
        section_duration_minutes=42,
        total_duration_minutes=210,  # 5 × 42
        total_questions=180,
    )
    link_questions(
        conn,
        grand_id,
        grand_qs,
        section_count=5,
        questions_per_section=36,
    )


def confirm_plan_limits(conn) -> None:
    if not table_exists(conn, "plan_limits"):
        print("  plan_limits: skipped (table not in schema yet — Phase 4B)")
        return
    rows = conn.execute(
        "select plan, max_practice_session_questions from public.plan_limits order by plan"
    ).fetchall()
    if len(rows) != 3:
        print(f"  plan_limits: WARN expected 3 rows, found {len(rows)}: {rows}")
    else:
        print(f"  plan_limits: OK ({[r[0] for r in rows]})")


def print_validation(conn) -> None:
    print("\nValidation queries (run these yourself in Supabase SQL editor too):")
    rows = conn.execute(
        """
        select required_plan::text, count(*)
        from public.questions
        where source = %s
        group by required_plan
        order by required_plan
        """,
        (SEED_SOURCE,),
    ).fetchall()
    print("  select required_plan, count(*) from questions where source = 'seed:phase1.3' group by 1;")
    for plan, count in rows:
        print(f"    {plan}: {count}")

    tests = conn.execute(
        """
        select title, test_type::text, required_plan::text,
               is_sectional, section_count, questions_per_section,
               total_questions, total_duration_minutes
        from public.tests
        where title like %s
        order by test_type
        """,
        (f"{SEED_TITLE_PREFIX}%",),
    ).fetchall()
    print("  seeded tests:")
    for t in tests:
        print(
            f"    {t[1]:7} plan={t[2]:5} sectional={t[3]} "
            f"sections={t[4]} q/sec={t[5]} total_q={t[6]} duration={t[7]} — {t[0]}"
        )

    linked = conn.execute(
        """
        select t.test_type::text, t.title, count(tq.question_id)
        from public.tests t
        join public.test_questions tq on tq.test_id = t.id
        where t.title like %s
        group by t.test_type, t.title
        order by t.test_type
        """,
        (f"{SEED_TITLE_PREFIX}%",),
    ).fetchall()
    print("  test_questions counts:")
    for test_type, title, count in linked:
        print(f"    {test_type}: {count} linked — {title}")


def main() -> int:
    load_env()
    database_url = os.environ.get("DATABASE_URL")
    if not database_url or "YOUR_" in database_url:
        sys.exit("DATABASE_URL is missing or still a placeholder in .env")

    ensure_psycopg()
    import psycopg

    rng = random.Random(42)  # deterministic tag assignment

    print("Phase 1.3 — seeding placeholder content")
    with psycopg.connect(database_url, connect_timeout=20) as conn:
        conn.execute("set search_path to public")
        try:
            clear_prior_seed(conn)
            print("  cleared prior seed rows (if any)")

            topic_ids_by_subject = seed_subjects_and_topics(conn)
            print(
                f"  subjects: {len(SUBJECTS)}; "
                f"topics: {sum(len(v) for v in topic_ids_by_subject.values())}"
            )

            question_ids = seed_questions(conn, topic_ids_by_subject)
            print(f"  questions: {len(question_ids)} ({FREE_COUNT} free / {PRO_COUNT} pro / {ELITE_COUNT} elite)")

            seed_tags(conn, question_ids, rng)
            seed_tests(conn, question_ids)
            print("  tests: mini, subject, mock, grand (sectional 5×36)")

            confirm_plan_limits(conn)
            conn.commit()
            print("  commit: OK")

            print_validation(conn)
            print("\nPASS: seed complete")
            return 0
        except Exception:
            conn.rollback()
            raise


if __name__ == "__main__":
    raise SystemExit(main())
