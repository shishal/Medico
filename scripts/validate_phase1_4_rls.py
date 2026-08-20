#!/usr/bin/env python3
"""
Phase 1.4 — verify questions RLS end-to-end via the Supabase client.

Creates a free-tier auth user, signs in with the *anon* key (same privilege
boundary as the Flutter app), queries `questions`, and asserts the row count
matches `select count(*) from questions where required_plan = 'free' and is_active`
(the RLS policy also requires is_active).

Requires in .env: SUPABASE_URL, SUPABASE_ANON_KEY, DATABASE_URL.
"""

from __future__ import annotations

import os
import subprocess
import sys
import uuid
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ENV_PATH = ROOT / ".env"
# Fixed password for the ephemeral test user — never a real account.
TEST_PASSWORD = "Phase14RlsTest!pass"


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
    """Use scripts/.venv; install supabase + bcrypt if missing."""
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

    # GoTrue accepts standard bcrypt hashes ($2a$ / $2b$).
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

    ensure_deps()
    import psycopg
    from supabase import create_client

    user_id = str(uuid.uuid4())
    email = f"phase1_4_{user_id[:8]}@medico.test"
    password_hash = bcrypt_hash(TEST_PASSWORD)

    print("Phase 1.4 — RLS end-to-end (free-tier user → questions)")
    print(f"  temp user: {email}")

    created_user = False
    client = None

    try:
        # --- Ground truth via direct DB (bypasses RLS) ---
        with psycopg.connect(database_url) as conn:
            conn.execute("set search_path to public")

            plan_counts = dict(
                conn.execute(
                    """
                    select required_plan::text, count(*)
                    from questions
                    where is_active
                    group by required_plan
                    """
                ).fetchall()
            )
            free_active = plan_counts.get("free", 0)
            pro_active = plan_counts.get("pro", 0)
            elite_active = plan_counts.get("elite", 0)
            total_active = free_active + pro_active + elite_active

            print(
                f"  DB active questions: free={free_active} "
                f"pro={pro_active} elite={elite_active} total={total_active}"
            )

            if free_active == 0:
                print(
                    "FAIL: no active free questions — run scripts/seed_phase1_3.py first"
                )
                return 1
            if pro_active + elite_active == 0:
                print(
                    "FAIL: no pro/elite questions — RLS gating can't be proven "
                    "(seed should include a free/pro/elite mix)"
                )
                return 1

            # Create auth user + ensure free profile (trigger may already insert).
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
            # identities row required for email/password sign-in in newer GoTrue.
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

        # --- Authenticate + query as the Flutter app would (anon key + session) ---
        client = create_client(url, anon)
        auth_resp = client.auth.sign_in_with_password(
            {"email": email, "password": TEST_PASSWORD}
        )
        if not auth_resp.session:
            print("FAIL: sign-in returned no session")
            return 1
        print("  signed in via Supabase anon client")

        # Paginate in case PostgREST max-rows is below our free count.
        page_size = 1000
        offset = 0
        rows: list[dict] = []
        while True:
            page = (
                client.table("questions")
                .select("id, required_plan")
                .range(offset, offset + page_size - 1)
                .execute()
            )
            batch = page.data or []
            rows.extend(batch)
            if len(batch) < page_size:
                break
            offset += page_size

        returned = len(rows)
        plans_seen = sorted({r["required_plan"] for r in rows})
        print(f"  client returned {returned} question(s)")
        print(f"  required_plan values seen: {plans_seen}")

        # Build-plan validation: match free count exactly.
        # Policy also filters is_active — we already counted free+active above.
        if returned != free_active:
            print(
                f"FAIL: client count {returned} != DB free+active count {free_active}"
            )
            return 1
        if plans_seen != ["free"]:
            print(f"FAIL: expected only 'free' plans, got {plans_seen}")
            return 1

        print(
            f"PASS: free-tier session sees exactly {returned} free questions "
            f"(pro/elite hidden by RLS)"
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
