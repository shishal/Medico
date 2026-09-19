#!/usr/bin/env bash
# Dump the remote Supabase Postgres DB into backups/.
#
# Why not `supabase db dump`?
#   The `supabase` binary is often missing (`command not found`). This project
#   already keeps DATABASE_URL in .env for scripts/ — we use that + pg_dump.
#
# Prerequisites:
#   1. .env with DATABASE_URL (see .env.example)
#   2. pg_dump — install with:
#        brew install libpq && brew link --force libpq
#      Or install Docker; the script can run pg_dump via postgres:16-alpine.
#
# Usage:
#   ./scripts/backup_database.sh
#   ./scripts/backup_database.sh --schema-only
#   ./scripts/backup_database.sh --data-only
#   ./scripts/backup_database.sh --outdir ~/Desktop/medico-backups
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OUTDIR="$ROOT/backups"
SCHEMA_ONLY=0
DATA_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --outdir)
      OUTDIR="${2:?--outdir needs a path}"
      shift 2
      ;;
    --schema-only)
      SCHEMA_ONLY=1
      shift
      ;;
    --data-only)
      DATA_ONLY=1
      shift
      ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "$SCHEMA_ONLY" -eq 1 && "$DATA_ONLY" -eq 1 ]]; then
  echo "Use only one of --schema-only / --data-only" >&2
  exit 1
fi

# Resolve a dump-ready URL (normalize pooler user; 6543 → 5432 for pg_dump).
DUMP_URL="$(
  python3 - "$ROOT" <<'PY'
import os
import sys
from pathlib import Path
from urllib.parse import urlparse, urlunparse

root = Path(sys.argv[1])
sys.path.insert(0, str(root / "scripts"))
from db_url import normalize_database_url  # noqa: E402

env_path = root / ".env"
if not env_path.exists():
    sys.exit("Missing .env — copy .env.example and fill in DATABASE_URL.")

for raw in env_path.read_text().splitlines():
    line = raw.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    key, _, value = line.partition("=")
    os.environ.setdefault(key.strip(), value.strip())

url = os.environ.get("DATABASE_URL", "")
if not url or "YOUR_" in url:
    sys.exit("DATABASE_URL is missing or still a placeholder in .env")

url = normalize_database_url(url)
parsed = urlparse(url)
host = parsed.hostname or ""
if "pooler.supabase.com" in host and parsed.port == 6543:
    netloc = parsed.netloc.rsplit(":", 1)[0] + ":5432"
    url = urlunparse(
        (parsed.scheme, netloc, parsed.path, parsed.params, parsed.query, parsed.fragment)
    )
    print(
        "Note: switched pooler port 6543 → 5432 (session mode) for pg_dump.",
        file=sys.stderr,
    )
print(url)
PY
)"

find_pg_dump() {
  if command -v pg_dump >/dev/null 2>&1; then
    command -v pg_dump
    return 0
  fi
  for candidate in \
    /opt/homebrew/opt/libpq/bin/pg_dump \
    /usr/local/opt/libpq/bin/pg_dump; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

PG_DUMP_BIN=""
USE_DOCKER=0
if PG_DUMP_BIN="$(find_pg_dump)"; then
  :
elif command -v docker >/dev/null 2>&1; then
  USE_DOCKER=1
else
  cat >&2 <<'EOF'
pg_dump not found, and Docker is not available.

Install Postgres client tools:

  brew install libpq
  brew link --force libpq

Then re-run: ./scripts/backup_database.sh
EOF
  exit 1
fi

mkdir -p "$OUTDIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
SUFFIX="full"
[[ "$SCHEMA_ONLY" -eq 1 ]] && SUFFIX="schema"
[[ "$DATA_ONLY" -eq 1 ]] && SUFFIX="data"
OUT_FILE="$OUTDIR/medico_${SUFFIX}_${STAMP}.sql.gz"

# Public app schema + auth users. Extend --schema list if you need more.
DUMP_ARGS=(--no-owner --no-acl --schema=public --schema=auth)
[[ "$SCHEMA_ONLY" -eq 1 ]] && DUMP_ARGS+=(--schema-only)
[[ "$DATA_ONLY" -eq 1 ]] && DUMP_ARGS+=(--data-only)

echo "Backing up to: $OUT_FILE"

if [[ "$USE_DOCKER" -eq 1 ]]; then
  docker run --rm postgres:16-alpine \
    pg_dump "$DUMP_URL" "${DUMP_ARGS[@]}" \
    | gzip -c > "$OUT_FILE"
else
  "$PG_DUMP_BIN" "$DUMP_URL" "${DUMP_ARGS[@]}" \
    | gzip -c > "$OUT_FILE"
fi

BYTES="$(wc -c < "$OUT_FILE" | tr -d ' ')"
if [[ "$BYTES" -lt 100 ]]; then
  echo "Backup looks empty (${BYTES} bytes) — check DATABASE_URL / network." >&2
  rm -f "$OUT_FILE"
  exit 1
fi

echo "Done (${BYTES} bytes)."
echo "Restore later with:"
echo "  gunzip -c \"$OUT_FILE\" | psql \"\$DATABASE_URL\""
