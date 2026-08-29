#!/usr/bin/env python3
"""
Phase 4B.1 — validate create_practice_session() plan clamping.

As a free-tier user, request 999 questions and full explanations; confirm the
created session has at most plan_limits.max_practice_session_questions (10)
and show_explanation_level was downgraded to 'answer_only'.

Requires in .env: SUPABASE_URL, SUPABASE_ANON_KEY, DATABASE_URL.

For Supabase pooler URLs, username must be `postgres.<project_ref>` (not bare
`postgres`) — see scripts/db_url.py.
"""

from __future__ import annotations

import os
import subprocess
import sys
import uuid
from pathlib import Path

# Allow `python scripts/validate_....py` without installing a package.
sys.path.insert(0, str(Path(__file__).resolve().parent))
from db_url import normalize_database_url  # noqa: E402


ROOT = Path(__file__).resolve().parents[1]
ENV_PATH = ROOT / ".env"
TEST_PASSWORD = "Phase4B1Practice!pass"


def load_env() -> None:
    if not ENV_PATH.exists():
        sys.exit(f"Missing {ENV_PATH}. Copy .env.example and fill in keys.")
    for line in ENV_PATH.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip())


def ensure_deps():
    try:
        import bcrypt  # noqa: F401
        from supabase import create_client  # noqa: F401

        return
    except ImportError:
        pass

    venv_dir = ROOT / "scripts" / ".venv"
    py = venv_dir / "bin" / "python"
    if not py.exists():
        subprocess.check_call([sys.executable, "-m", "venv", str(venv_dir)])
    subprocess.check_call(
        [
            str(py),
            "-m",
            "pip",
            "install",
            "--quiet",
            "psycopg[binary]",
            "supabase",
            "bcrypt",
        ],
    )
    os.execv(str(py), [str(py), str(Path(__file__).resolve()), *sys.argv[1:]])


def bcrypt_hash(password: str) -> str:
    import bcrypt

    return bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=10)).decode()


def main() -> int:
    load_env()
    url = os.environ.get("SUPABASE_URL", "")
    anon = os.environ.get("SUPABASE_ANON_KEY", "")
    database_url = os.environ.get("DATABASE_URL", "")

    if not url or "YOUR_" in url:
        sys.exit("SUPABASE_URL is missing or still a placeholder in .env")
    if not anon or anon.startswith("your_"):
        sys.exit("SUPABASE_ANON_KEY is missing or still a placeholder in .env")
    if not database_url or "YOUR_" in database_url:
        sys.exit("DATABASE_URL is missing or still a placeholder in .env")

    try:
        database_url = normalize_database_url(database_url)
    except ValueError as exc:
        sys.exit(f"DATABASE_URL: {exc}")
    os.environ["DATABASE_URL"] = database_url

    ensure_deps()
    import psycopg
    from supabase import create_client

    user_id = str(uuid.uuid4())
    email = f"phase4b1_{user_id[:8]}@medico.test"
    created_user = False
    client = None
    test_id = None

    print("Phase 4B.1 — create_practice_session plan clamp (free tier)")
    print(f"  temp user: {email}")

    try:
        with psycopg.connect(database_url) as conn:
            conn.execute("set search_path to public")

            # Confirm migration landed.
            fn = conn.execute(
                """
                select 1 from pg_proc p
                join pg_namespace n on n.oid = p.pronamespace
                where n.nspname = 'public' and p.proname = 'create_practice_session'
                """
            ).fetchone()
            if not fn:
                print("FAIL: create_practice_session() missing — push migrations first")
                return 1

            free_limits = conn.execute(
                """
                select max_practice_session_questions, allow_full_explanation
                from plan_limits where plan = 'free'
                """
            ).fetchone()
            if not free_limits:
                print("FAIL: plan_limits missing free row")
                return 1
            max_q, allow_full = free_limits
            print(
                f"  free plan_limits: max_session={max_q}, "
                f"allow_full_explanation={allow_full}"
            )
            if max_q != 10 or allow_full is not False:
                print(
                    "FAIL: unexpected free plan_limits "
                    f"(expected max=10, allow_full=false; got {max_q}, {allow_full})"
                )
                return 1

            free_active = conn.execute(
                """
                select count(*) from questions
                where is_active and required_plan = 'free'
                """
            ).fetchone()[0]
            if free_active < 1:
                print("FAIL: no free questions — run scripts/seed_phase1_3.py first")
                return 1
            print(f"  DB free+active questions: {free_active}")

            password_hash = bcrypt_hash(TEST_PASSWORD)
            conn.execute(
                """
                insert into auth.users (
                  id, instance_id, aud, role, email,
                  encrypted_password, email_confirmed_at,
                  raw_app_meta_data, raw_user_meta_data,
                  created_at, updated_at,
                  confirmation_token, email_change,
                  email_change_token_new, recovery_token
                ) values (
                  %s::uuid,
                  '00000000-0000-0000-0000-000000000000',
                  'authenticated',
                  'authenticated',
                  %s,
                  %s,
                  now(),
                  '{"provider":"email","providers":["email"]}'::jsonb,
                  '{}'::jsonb,
                  now(),
                  now(),
                  '',
                  '',
                  '',
                  ''
                )
                """,
                (user_id, email, password_hash),
            )
            conn.execute(
                """
                insert into auth.identities (
                  id, user_id, identity_data, provider, provider_id,
                  last_sign_in_at, created_at, updated_at
                ) values (
                  %s::uuid,
                  %s::uuid,
                  jsonb_build_object('sub', (%s::uuid)::text, 'email', %s::text),
                  'email',
                  %s::text,
                  now(),
                  now(),
                  now()
                )
                """,
                (user_id, user_id, user_id, email, user_id),
            )
            conn.execute(
                """
                insert into public.profiles (id, plan, plan_started_at, plan_expires_at)
                values (%s::uuid, 'free', now(), null)
                on conflict (id) do update set
                  plan = 'free',
                  plan_expires_at = null
                """,
                (user_id,),
            )
            conn.commit()
            created_user = True
            print("  created free-tier auth user + profile")

        client = create_client(url, anon)
        auth_resp = client.auth.sign_in_with_password(
            {"email": email, "password": TEST_PASSWORD}
        )
        if not auth_resp.session:
            print("FAIL: sign-in returned no session")
            return 1
        print("  signed in via Supabase anon client")

        # Schema §7.6 validation: ask for far more than free allows + full explanations.
        rpc = client.rpc(
            "create_practice_session",
            {
                "p_topic_ids": None,
                "p_tag_ids": None,
                "p_difficulties": None,
                "p_source_filter": "all",
                "p_question_count": 999,
                "p_feedback_timing": "on_submit",
                "p_explanation_level": "full",
                "p_timer_minutes": None,
                "p_negative_marking": True,
            },
        ).execute()
        test_id = rpc.data
        if not test_id:
            print(f"FAIL: RPC returned empty data: {rpc}")
            return 1
        print(f"  create_practice_session → test_id={test_id}")

        # Owner can read own ephemeral practice row (RLS 7.5).
        session = (
            client.table("tests")
            .select(
                "id, total_questions, show_explanation_level, "
                "is_ephemeral_practice, owner_user_id, timer_enabled, "
                "correct_marks, incorrect_marks"
            )
            .eq("id", test_id)
            .maybe_single()
            .execute()
        )
        row = session.data
        if not row:
            print("FAIL: owner cannot SELECT own practice tests row")
            return 1

        tq = (
            client.table("test_questions")
            .select("question_id")
            .eq("test_id", test_id)
            .execute()
        )
        tq_count = len(tq.data or [])

        print(
            f"  session: total_questions={row['total_questions']}, "
            f"test_questions={tq_count}, "
            f"show_explanation_level={row['show_explanation_level']}, "
            f"timer_enabled={row['timer_enabled']}, "
            f"marks={row['correct_marks']}/{row['incorrect_marks']}"
        )

        ok = True
        if not row.get("is_ephemeral_practice"):
            print("FAIL: is_ephemeral_practice is not true")
            ok = False
        if row.get("owner_user_id") != user_id:
            print(f"FAIL: owner_user_id={row.get('owner_user_id')} != {user_id}")
            ok = False
        if row["total_questions"] > max_q:
            print(
                f"FAIL: total_questions {row['total_questions']} > free max {max_q}"
            )
            ok = False
        if tq_count > max_q:
            print(f"FAIL: attached {tq_count} questions > free max {max_q}")
            ok = False
        if row["total_questions"] != tq_count:
            print(
                f"FAIL: total_questions {row['total_questions']} "
                f"!= test_questions count {tq_count}"
            )
            ok = False
        if row["show_explanation_level"] != "answer_only":
            print(
                "FAIL: expected show_explanation_level='answer_only' "
                f"(got {row['show_explanation_level']!r}) — full must be clamped"
            )
            ok = False
        # Free: timer forced on, negative marking forced off.
        if row["timer_enabled"] is not True:
            print("FAIL: expected timer_enabled=true for free (toggle not allowed)")
            ok = False
        if float(row["correct_marks"]) != 1.0 or float(row["incorrect_marks"]) != 0.0:
            print(
                "FAIL: expected +1/0 marking for free "
                f"(got {row['correct_marks']}/{row['incorrect_marks']})"
            )
            ok = False

        if not ok:
            return 1

        print(
            f"PASS: free-tier request of 999/full clamped to "
            f"{tq_count} questions + answer_only"
        )
        return 0
    finally:
        if client is not None:
            try:
                client.auth.sign_out()
            except Exception:
                pass
        if created_user:
            with psycopg.connect(database_url) as conn:
                try:
                    # Cascades: daily_practice_usage, profiles; tests.owner_user_id
                    # is ON DELETE no action — delete practice tests first.
                    conn.execute(
                        "delete from public.tests where owner_user_id = %s::uuid",
                        (user_id,),
                    )
                    conn.execute(
                        "delete from auth.users where id = %s::uuid",
                        (user_id,),
                    )
                    conn.commit()
                    print("  cleaned up temp user + practice session")
                except Exception as cleanup_err:
                    conn.rollback()
                    print(f"  cleanup failed: {cleanup_err}")


if __name__ == "__main__":
    raise SystemExit(main())
