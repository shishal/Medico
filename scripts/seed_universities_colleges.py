#!/usr/bin/env python3
"""Replace universities + colleges in Supabase from the MBBS catalog Excel.

There is no separate `states` table — state is `universities.state`. Students
pick state first in onboarding, then university, then college.

Source of truth:
  content/admin/MBBS_Colleges_by_State.xlsx

This script:
  1. Parses the Excel (State, University name, University short form, College)
  2. Disambiguates colliding short forms so `universities.code` stays unique
  3. Rewrites content/admin/Universities.csv and Colleges.csv
  4. Clears profile academic FKs that would break, deletes old colleges /
     universities not in the new list, upserts the catalog

Usage (from repo root):
  python3 scripts/seed_universities_colleges.py            # dry-run (default)
  python3 scripts/seed_universities_colleges.py --apply    # write to Supabase
  python3 scripts/seed_universities_colleges.py --apply --xlsx /path/to/file.xlsx

Requires DATABASE_URL in .env.
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENV_PATH = ROOT / ".env"
ADMIN_DIR = ROOT / "content" / "admin"
DEFAULT_XLSX = ADMIN_DIR / "MBBS_Colleges_by_State.xlsx"
UNIVERSITIES_CSV = ADMIN_DIR / "Universities.csv"
COLLEGES_CSV = ADMIN_DIR / "Colleges.csv"

# Appended to every university so onboarding never dead-ends on a missing campus.
OTHER_COLLEGE_NAME = "Other / not listed"

# Old DB codes → new sheet codes (same affiliating university, renamed short form).
CODE_RENAMES: dict[str, str] = {
    "IPU": "GGSIPU",
}


@dataclass(frozen=True)
class University:
    code: str
    name: str
    state: str
    slug: str


@dataclass(frozen=True)
class College:
    university_code: str
    name: str


def load_env() -> None:
    if not ENV_PATH.exists():
        sys.exit(f"Missing {ENV_PATH}. Copy .env.example and fill in DATABASE_URL.")
    for raw in ENV_PATH.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        os.environ.setdefault(key.strip(), value.strip())


def ensure_deps() -> None:
    """Local venv under scripts/.venv — same pattern as other scripts/ tools."""
    missing: list[str] = []
    try:
        import openpyxl  # noqa: F401
    except ImportError:
        missing.append("openpyxl")
    try:
        import psycopg  # noqa: F401
    except ImportError:
        missing.append("psycopg[binary]")
    if not missing:
        return

    venv_dir = ROOT / "scripts" / ".venv"
    py = venv_dir / "bin" / "python"
    if not py.exists():
        subprocess.check_call([sys.executable, "-m", "venv", str(venv_dir)])
    subprocess.check_call(
        [str(py), "-m", "pip", "install", "--quiet", *missing],
    )
    os.execv(str(py), [str(py), str(Path(__file__).resolve()), *sys.argv[1:]])


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.strip().lower())
    return slug.strip("-")


def normalize_code(raw: str) -> str:
    """Keep short forms readable; collapse internal whitespace."""
    return re.sub(r"\s+", " ", raw.strip())


def is_placeholder_code(raw: str) -> bool:
    cleaned = raw.strip().casefold()
    return cleaned in {"", "-", "—", "–", "n/a", "na", "tbd", "?"}


def code_from_name(name: str) -> str:
    """Fallback when the sheet has no usable short form."""
    words = re.findall(r"[A-Za-z0-9]+", name)
    if not words:
        raise ValueError(f"Cannot derive university code from name {name!r}")
    # Prefer an acronym when the name has several words; else the first token.
    if len(words) >= 2:
        acronym = "".join(w[0] for w in words).upper()
        if len(acronym) >= 2:
            return acronym
    return words[0].upper()


def read_xlsx(path: Path) -> tuple[list[University], list[College], list[str]]:
    import openpyxl

    if not path.exists():
        raise FileNotFoundError(f"Excel not found: {path}")

    wb = openpyxl.load_workbook(path, read_only=True, data_only=True)
    ws = wb.active
    rows = list(ws.iter_rows(values_only=True))
    if not rows:
        raise ValueError("Excel is empty")

    header = [str(c or "").strip().lower() for c in rows[0]]
    expected = [
        "state",
        "university name",
        "university short form",
        "college name",
    ]
    if header[:4] != expected:
        raise ValueError(
            f"Unexpected header {header[:4]!r}; expected {expected!r}"
        )

    warnings: list[str] = []

    # (state, name, short_form) → colleges
    raw_unis: dict[tuple[str, str, str], list[str]] = defaultdict(list)
    for row_number, row in enumerate(rows[1:], start=2):
        if row is None or not any(row):
            continue
        cells = [(str(c).strip() if c is not None else "") for c in row[:4]]
        if len(cells) < 4 or not cells[0] or not cells[1] or not cells[3]:
            raise ValueError(
                f"Row {row_number}: missing State/University name/College name"
            )
        state, uni_name, short_form, college = cells
        short_form = normalize_code(short_form)
        if is_placeholder_code(short_form):
            short_form = code_from_name(uni_name)
            warnings.append(
                f"Row {row_number}: missing short form for {uni_name!r}; "
                f"using derived code {short_form!r}"
            )
        key = (state, uni_name, short_form)
        if college in raw_unis[key]:
            raise ValueError(
                f"Row {row_number}: duplicate college {college!r} under {short_form}"
            )
        raw_unis[key].append(college)

    # Short forms that map to more than one (state, name) need unique codes.
    by_short: dict[str, list[tuple[str, str, str]]] = defaultdict(list)
    for state, name, short in raw_unis:
        by_short[short].append((state, name, short))

    code_for_key: dict[tuple[str, str, str], str] = {}
    used_codes: set[str] = set()

    for short, keys in sorted(by_short.items()):
        unique_keys = sorted(set(keys))
        if len(unique_keys) == 1:
            code = short
            if code in used_codes:
                raise ValueError(f"Internal code clash for {code!r}")
            code_for_key[unique_keys[0]] = code
            used_codes.add(code)
            continue

        warnings.append(
            f"Short form {short!r} maps to {len(unique_keys)} universities; "
            "codes will be disambiguated with state:"
        )
        for state, name, _ in unique_keys:
            state_slug = slugify(state)
            code = f"{short}-{state_slug}"
            if code in used_codes:
                raise ValueError(f"Disambiguated code still clashes: {code!r}")
            code_for_key[(state, name, short)] = code
            used_codes.add(code)
            warnings.append(f"  {short} + {state} → {code} ({name})")

    universities: list[University] = []
    colleges: list[College] = []
    seen_slugs: set[str] = set()

    for (state, name, short), college_names in sorted(
        raw_unis.items(), key=lambda item: (item[0][0], item[0][1])
    ):
        code = code_for_key[(state, name, short)]
        slug = slugify(code)
        if not slug:
            raise ValueError(f"Empty slug for university code {code!r}")
        if slug in seen_slugs:
            raise ValueError(f"Duplicate slug {slug!r}")
        seen_slugs.add(slug)
        universities.append(University(code=code, name=name, state=state, slug=slug))
        for college_name in college_names:
            colleges.append(College(university_code=code, name=college_name))
        # Escape hatch for campuses missing from the sheet.
        colleges.append(College(university_code=code, name=OTHER_COLLEGE_NAME))

    return universities, colleges, warnings


def write_admin_csvs(
    universities: list[University], colleges: list[College]
) -> None:
    ADMIN_DIR.mkdir(parents=True, exist_ok=True)
    with UNIVERSITIES_CSV.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["code", "name", "state", "slug"])
        writer.writeheader()
        for uni in universities:
            writer.writerow(
                {
                    "code": uni.code,
                    "name": uni.name,
                    "state": uni.state,
                    "slug": uni.slug,
                }
            )

    with COLLEGES_CSV.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["university_code", "name"])
        writer.writeheader()
        for college in colleges:
            writer.writerow(
                {
                    "university_code": college.university_code,
                    "name": college.name,
                }
            )


def apply_code_renames(conn, seed_codes: list[str]) -> list[str]:
    """Rewrite legacy university codes onto the sheet's short forms.

    Keeps exam_papers / profile FKs intact by renaming in place when possible,
    or by re-pointing rows when both old and new codes already exist.
    """
    notes: list[str] = []
    for old_code, new_code in CODE_RENAMES.items():
        if new_code not in seed_codes:
            continue
        old = conn.execute(
            "select id, code from public.universities where code = %s",
            (old_code,),
        ).fetchone()
        if old is None:
            continue
        new = conn.execute(
            "select id, code from public.universities where code = %s",
            (new_code,),
        ).fetchone()
        if new is None:
            conn.execute(
                "update public.universities set code = %s where id = %s",
                (new_code, old["id"]),
            )
            notes.append(f"renamed university code {old_code} → {new_code}")
            continue

        # Both rows exist: move dependents onto the new code, drop the old one.
        moved_papers = conn.execute(
            """
            update public.exam_papers
            set university_id = %s
            where university_id = %s
            """,
            (new["id"], old["id"]),
        ).rowcount
        moved_profiles = conn.execute(
            """
            update public.profiles
            set university_id = %s
            where university_id = %s
            """,
            (new["id"], old["id"]),
        ).rowcount
        conn.execute("delete from public.universities where id = %s", (old["id"],))
        notes.append(
            f"merged {old_code} → {new_code} "
            f"(papers={moved_papers}, profiles={moved_profiles})"
        )
    return notes


def apply_to_database(
    universities: list[University], colleges: list[College]
) -> dict[str, int]:
    sys.path.insert(0, str(ROOT / "scripts"))
    from db_url import normalize_database_url

    import psycopg
    from psycopg.rows import dict_row

    database_url = os.environ.get("DATABASE_URL", "")
    if not database_url or "YOUR_" in database_url:
        raise RuntimeError("DATABASE_URL is missing or still a placeholder in .env")
    database_url = normalize_database_url(database_url)

    seed_codes = [u.code for u in universities]
    uni_rows = [(u.code, u.name, u.state, u.slug) for u in universities]
    college_rows = [(c.university_code, c.name) for c in colleges]

    with psycopg.connect(database_url, row_factory=dict_row) as conn:
        conn.execute("set search_path to public")
        with conn.transaction():
            before_uni = conn.execute(
                "select count(*)::int as n from public.universities"
            ).fetchone()["n"]
            before_colleges = conn.execute(
                "select count(*)::int as n from public.colleges"
            ).fetchone()["n"]

            # Profiles must not hold FKs to college rows we are about to delete.
            cleared_colleges = conn.execute(
                """
                update public.profiles
                set college_id = null
                where college_id is not null
                """
            ).rowcount

            # Remove every college; we re-insert the final list below.
            conn.execute("delete from public.colleges")

            rename_notes = apply_code_renames(conn, seed_codes)
            for note in rename_notes:
                print(f"  {note}")

            cleared_unis = conn.execute(
                """
                update public.profiles p
                set university_id = null
                where p.university_id is not null
                  and not exists (
                    select 1
                    from public.universities u
                    where u.id = p.university_id
                      and u.code = any(%s)
                  )
                """,
                (seed_codes,),
            ).rowcount

            blocked = conn.execute(
                """
                select u.code, count(ep.id)::int as paper_count
                from public.universities u
                join public.exam_papers ep on ep.university_id = u.id
                where u.code <> all(%s)
                group by u.code
                order by u.code
                """,
                (seed_codes,),
            ).fetchall()
            if blocked:
                details = ", ".join(
                    f"{row['code']} ({row['paper_count']} papers)" for row in blocked
                )
                raise RuntimeError(
                    "Cannot delete universities that still have exam_papers: "
                    f"{details}. Move or delete those papers first, or add a "
                    "CODE_RENAMES entry in this script."
                )

            deleted_unis = conn.execute(
                """
                delete from public.universities
                where code <> all(%s)
                """,
                (seed_codes,),
            ).rowcount

            with conn.cursor() as cur:
                cur.executemany(
                    """
                    insert into public.universities (code, name, state, slug)
                    values (%s, %s, %s, %s)
                    on conflict (code) do update
                      set name = excluded.name,
                          state = excluded.state,
                          slug = excluded.slug
                    """,
                    uni_rows,
                )
                cur.executemany(
                    """
                    insert into public.colleges (university_id, name)
                    select u.id, v.name
                    from public.universities u
                    join (values (%s, %s)) as v(code, name)
                      on lower(u.code) = lower(v.code)
                    on conflict (university_id, name) do nothing
                    """,
                    college_rows,
                )

            after_uni = conn.execute(
                "select count(*)::int as n from public.universities"
            ).fetchone()["n"]
            after_colleges = conn.execute(
                "select count(*)::int as n from public.colleges"
            ).fetchone()["n"]

            missing = conn.execute(
                """
                select v.code
                from unnest(%s::text[]) as v(code)
                left join public.universities u on lower(u.code) = lower(v.code)
                where u.id is null
                order by v.code
                """,
                (seed_codes,),
            ).fetchall()
            if missing:
                raise RuntimeError(
                    "Universities failed to upsert: "
                    + ", ".join(row["code"] for row in missing)
                )

            orphan_colleges = conn.execute(
                """
                select count(*)::int as n
                from public.colleges c
                where not exists (
                  select 1 from public.universities u where u.id = c.university_id
                )
                """
            ).fetchone()["n"]
            if orphan_colleges:
                raise RuntimeError(f"{orphan_colleges} orphan colleges after seed")

            # Slug uniqueness: renamed rows may still hold the old slug until upsert.
            dup_slugs = conn.execute(
                """
                select slug, count(*)::int as n
                from public.universities
                group by slug
                having count(*) > 1
                """
            ).fetchall()
            if dup_slugs:
                raise RuntimeError(
                    "Duplicate university slugs: "
                    + ", ".join(f"{r['slug']}×{r['n']}" for r in dup_slugs)
                )

        return {
            "universities_before": before_uni,
            "universities_after": after_uni,
            "universities_deleted": deleted_unis,
            "colleges_before": before_colleges,
            "colleges_after": after_colleges,
            "profiles_college_cleared": cleared_colleges,
            "profiles_university_cleared": cleared_unis,
            "code_renames": len(rename_notes),
        }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Seed universities + colleges into Supabase from Excel."
    )
    parser.add_argument(
        "--xlsx",
        type=Path,
        default=DEFAULT_XLSX,
        help=f"Path to workbook (default: {DEFAULT_XLSX})",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write to Supabase (default is dry-run: CSVs only)",
    )
    parser.add_argument(
        "--skip-csv",
        action="store_true",
        help="Do not rewrite content/admin/*.csv",
    )
    args = parser.parse_args()

    load_env()
    ensure_deps()

    universities, colleges, warnings = read_xlsx(args.xlsx)
    states = sorted({u.state for u in universities})

    print(f"Source: {args.xlsx}")
    print(f"  states:        {len(states)}")
    print(f"  universities:  {len(universities)}")
    print(
        f"  colleges:      {len(colleges)} "
        f"(includes '{OTHER_COLLEGE_NAME}' × {len(universities)})"
    )
    for warning in warnings:
        print(f"  WARN: {warning}")

    if not args.skip_csv:
        write_admin_csvs(universities, colleges)
        print(f"Wrote {UNIVERSITIES_CSV.relative_to(ROOT)}")
        print(f"Wrote {COLLEGES_CSV.relative_to(ROOT)}")

    if not args.apply:
        print("Dry-run only (CSVs updated). Pass --apply to write to Supabase.")
        return 0

    stats = apply_to_database(universities, colleges)
    print("Applied to Supabase:")
    for key, value in stats.items():
        print(f"  {key}: {value}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001 — CLI surface
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
