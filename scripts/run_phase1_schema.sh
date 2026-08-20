#!/usr/bin/env bash
# Apply Phase 1.1 core schema to a linked Supabase project.
# Prerequisites: npx supabase login && npx supabase link --project-ref YOUR_REF
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "Pushing migrations to linked Supabase project..."
npx supabase db push

echo ""
echo "Done. Validate in Supabase Dashboard:"
echo "  1. Table Editor — confirm tables: profiles, subjects, topics, questions,"
echo "     tests, test_questions, attempts, attempt_answers, bookmarks"
echo "  2. SQL Editor — run:"
echo "     select tablename, policyname from pg_policies where schemaname = 'public' order by tablename;"
