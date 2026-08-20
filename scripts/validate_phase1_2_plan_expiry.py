#!/usr/bin/env python3
"""
Phase 1.2 — validate current_plan() expiry fallback.

Creates a temporary auth user + profile with plan='pro' and plan_expires_at
in the past, asserts current_plan() returns 'free', then cleans up.
Requires DATABASE_URL in .env (never commit that file).
"""

from __future__ import annotations

import os
import subprocess
import sys
import uuid
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENV_PATH = ROOT / ".env"


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
    # Re-exec under the venv so `import psycopg` works.
    os.execv(str(py), [str(py), str(Path(__file__).resolve()), *sys.argv[1:]])


def main() -> int:
    load_env()
    database_url = os.environ.get("DATABASE_URL")
    if not database_url or "YOUR_" in database_url:
        sys.exit("DATABASE_URL is missing or still a placeholder in .env")

    ensure_psycopg()
    import psycopg

    user_id = str(uuid.uuid4())
    email = f"phase1_2_{user_id[:8]}@medico.test"

    print("Phase 1.2 — testing current_plan() expiry fallback")
    print(f"  temp user id: {user_id}")

    with psycopg.connect(database_url) as conn:
        conn.execute("set search_path to public")

        # --- 1.1 smoke check: tables + policies ---
        tables = conn.execute(
            """
            select table_name
            from information_schema.tables
            where table_schema = 'public'
              and table_name = any(%s)
            order by table_name
            """,
            (
                [
                    "profiles",
                    "subjects",
                    "topics",
                    "questions",
                    "tests",
                    "test_questions",
                    "attempts",
                    "attempt_answers",
                    "bookmarks",
                ],
            ),
        ).fetchall()
        found = [r[0] for r in tables]
        expected = [
            "attempt_answers",
            "attempts",
            "bookmarks",
            "profiles",
            "questions",
            "subjects",
            "test_questions",
            "tests",
            "topics",
        ]
        if found != expected:
            print("FAIL: expected tables missing.")
            print(f"  found: {found}")
            return 1
        print("  tables: OK (9/9)")

        policy_rows = conn.execute(
            """
            select tablename, count(*)
            from pg_policies
            where schemaname = 'public'
            group by tablename
            order by tablename
            """
        ).fetchall()
        policy_map = {r[0]: r[1] for r in policy_rows}
        missing_policy_tables = [t for t in expected if t not in policy_map]
        if missing_policy_tables:
            print(f"FAIL: tables with no RLS policies: {missing_policy_tables}")
            return 1
        total_policies = sum(policy_map.values())
        print(f"  policies: OK ({total_policies} across {len(policy_map)} tables)")

        fn = conn.execute(
            """
            select 1
            from pg_proc p
            join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'current_plan'
            """
        ).fetchone()
        if not fn:
            print("FAIL: current_plan() function not found")
            return 1
        print("  current_plan(): exists")

        # --- 1.2 expiry validation ---
        created_user = False
        try:
            # Dummy bcrypt hash — we never sign in as this user, so pgcrypto
            # (crypt/gen_salt) is not required. Extra token columns match
            # current GoTrue NOT NULL defaults.
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
                  '$2a$06$placeholderplaceholderplaceholderpl.aceholderplaceho',
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
                (user_id, email),
            )
            created_user = True

            conn.execute(
                """
                insert into public.profiles (id, plan, plan_started_at, plan_expires_at)
                values (%s::uuid, 'pro', now() - interval '30 days', now() - interval '1 day')
                on conflict (id) do update set
                  plan = excluded.plan,
                  plan_started_at = excluded.plan_started_at,
                  plan_expires_at = excluded.plan_expires_at
                """,
                (user_id,),
            )

            row = conn.execute(
                """
                select plan, plan_expires_at < now() as expired, current_plan(id) as effective
                from public.profiles
                where id = %s::uuid
                """,
                (user_id,),
            ).fetchone()

            plan, expired, effective = row
            print(f"  profile.plan = {plan}")
            print(f"  plan_expires_at in past = {expired}")
            print(f"  current_plan(id) = {effective}")

            if plan != "pro" or not expired or effective != "free":
                print("FAIL: expected plan='pro', expired=true, current_plan='free'")
                return 1

            print("PASS: expired pro plan correctly falls back to free")
            return 0
        except Exception:
            conn.rollback()
            raise
        finally:
            if created_user:
                try:
                    conn.execute(
                        "delete from auth.users where id = %s::uuid",
                        (user_id,),
                    )
                    conn.commit()
                    print("  cleaned up temp user")
                except Exception as cleanup_err:
                    conn.rollback()
                    print(f"  cleanup failed: {cleanup_err}")


if __name__ == "__main__":
    raise SystemExit(main())
