# NEET-PG Prep App

Flutter app for NEET-PG test prep. Full planning docs live in `docs/` — read the
relevant one before starting any task:
- docs/01_PROJECT_FOUNDATION.md — tech stack, architecture, conventions (read this always)
- docs/02_DATABASE_SCHEMA.md — Supabase schema, RLS policies, practice-mode generator
- docs/03_BUILD_PLAN.md — phased tasks with acceptance criteria (work one phase at a time)
- docs/04_TEST_ENGINE_SPEC.md — test-taking engine behavior
- docs/05_PRACTICE_MODE_SPEC.md — practice mode behavior

## Non-negotiable rules
- Stack is locked: Flutter + Riverpod (codegen) + go_router + Supabase. Don't suggest
  alternatives — if something feels awkward in this stack, say so and ask, don't swap it.
- Feature-first folder structure under lib/features/. A feature's presentation/ layer
  never calls Supabase directly — always through that feature's data/ repository.
- No magic strings for Supabase table/column names — use the constants in
  core/supabase/tables.dart.
- Anything enforcing a plan limit, computing a score, or touching money must run as a
  Postgres function (RPC) or Supabase Edge Function — never trust a value the client
  computed and sent. If you're about to write scoring or limit-checking logic in Dart,
  stop and flag it instead.
- I'm new to Flutter/Dart. Prefer clear, idiomatic code over clever code, and briefly
  explain non-obvious Dart/Flutter idioms in comments the first time they appear.

## Working style
- One task from docs/03_BUILD_PLAN.md at a time. After finishing a task, stop and
  summarize what changed and how to validate it — don't chain into the next task
  unasked.
- Small diffs. Don't refactor unrelated code while doing a task.