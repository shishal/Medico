"""Normalize DATABASE_URL for Supabase (direct vs pooler).

Pooler hosts require username `postgres.<project_ref>`, not bare `postgres`
— otherwise you get FATAL: no tenant identifier / Tenant or user not found.
"""

from __future__ import annotations

import os
import re
from urllib.parse import quote, unquote, urlparse, urlunparse


_POOLER_HOST_RE = re.compile(r"^aws-\d+-[a-z0-9-]+\.pooler\.supabase\.com$")
_DIRECT_DB_HOST_RE = re.compile(r"^db\.([a-z0-9]+)\.supabase\.co$")


def project_ref_from_env() -> str | None:
    supabase_url = os.environ.get("SUPABASE_URL", "")
    host = urlparse(supabase_url).hostname or ""
    if host.endswith(".supabase.co") and not host.startswith("db."):
        return host.split(".")[0]

    database_url = os.environ.get("DATABASE_URL", "")
    db_host = urlparse(database_url).hostname or ""
    m = _DIRECT_DB_HOST_RE.match(db_host)
    if m:
        return m.group(1)

    user = urlparse(database_url).username or ""
    if user.startswith("postgres."):
        return user[len("postgres.") :]
    return None


def normalize_database_url(url: str, project_ref: str | None = None) -> str:
    """Return a connectable URI; fix pooler username when possible."""
    p = urlparse(url)
    host = p.hostname or ""
    user = unquote(p.username or "")
    password = unquote(p.password or "")
    ref = project_ref or project_ref_from_env()

    if _POOLER_HOST_RE.match(host):
        if user == "postgres" and ref:
            user = f"postgres.{ref}"
        elif user == "postgres" and not ref:
            raise ValueError(
                "Pooler DATABASE_URL uses user 'postgres' but project ref is unknown. "
                "Use user 'postgres.<project_ref>' (from SUPABASE_URL) on "
                "aws-0-<region>.pooler.supabase.com:6543"
            )

    # Rebuild (keeps query like sslmode=require).
    netloc = ""
    if user:
        netloc = quote(user, safe=".")
        if password:
            netloc += ":" + quote(password, safe="")
        netloc += "@"
    if host:
        netloc += host
    if p.port:
        netloc += f":{p.port}"

    return urlunparse((p.scheme, netloc, p.path, p.params, p.query, p.fragment))
