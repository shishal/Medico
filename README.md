# NEET-PG Prep App — Build Plan Index

This is the planning package for a Flutter-based NEET-PG test-prep app (Phase 1 scope: authentication, plan-gated content, a full test engine, results/analytics, and content sync from a Google Sheet CMS). It's written to be fed into an AI coding agent (Cursor) phase by phase, not all at once.

## Files in this package

| File | What it's for | When to load it into Cursor |
|---|---|---|
| `01_PROJECT_FOUNDATION.md` | Tech stack decisions + why, folder structure, coding conventions, environment setup checklist | Once, at project start — this should live in your repo permanently (e.g. as `docs/FOUNDATION.md`) so every future session can reference it |
| `02_DATABASE_SCHEMA.md` | Full Supabase Postgres schema (SQL), RLS policies, seed data strategy | When doing Phase 1 (backend) work, or whenever a task touches the database |
| `03_BUILD_PLAN.md` | Phased task list with acceptance criteria and QA steps — the actual work breakdown | Load the **current phase's section only** into Cursor context, not the whole file |
| `04_TEST_ENGINE_SPEC.md` | Detailed functional spec for the test-taking engine (timer, sections, scoring, palette states) | When building/reviewing anything in Phase 5–6 |
| `05_PRACTICE_MODE_SPEC.md` | Practice Mode: filter-based custom sessions, Tutor vs. Exam feedback timing, tier-gated limits — builds on `04` rather than duplicating it | When building/reviewing Phase 4B, or anything touching `plan_limits`/tags |

## How to work through this with Cursor

1. **Put `01_PROJECT_FOUNDATION.md` and `02_DATABASE_SCHEMA.md` in your repo as permanent docs** (e.g. `docs/`). Reference them explicitly in your first prompt of every session ("read docs/FOUNDATION.md before starting") — don't rely on Cursor remembering across sessions.
2. **Work one phase at a time from `03_BUILD_PLAN.md`.** Paste only that phase's tasks into the chat, not the whole file — keeps the model focused and the diffs reviewable.
3. **After each task, run the "Validation" steps yourself before moving on.** Don't let the agent mark its own homework — you're new to Flutter, so treat these validation steps as your checklist for what "done" actually looks like, since you won't yet have the instinct for what a broken Flutter screen looks like at a glance.
4. **Commit after every completed task**, not every completed phase. Small commits = easy rollback when an AI-written change breaks something two tasks later.

## Model routing (since you're mixing Anthropic models by cost)

Rough guide for what deserves the stronger model vs. what doesn't:

| Use a stronger/frontier model for | A cheaper/faster model is fine for |
|---|---|
| RLS policies and anything touching auth or plan-gating (security-critical, subtle bugs are invisible until exploited) | Repetitive screen scaffolding once a pattern is established (e.g. the 5th settings-style screen) |
| The test engine's timer/sectional-lock/scoring logic (`04_TEST_ENGINE_SPEC.md`) — lots of edge cases, easy to get subtly wrong | Styling tweaks, spacing, copy changes |
| The Google Sheet → Supabase sync script (silent data corruption here is hard to notice later) | Writing unit tests for logic the stronger model already wrote and you've reviewed |
| Debugging anything where the bug report is vague ("it feels laggy", "sometimes wrong") | Straightforward CRUD screens (list a table, show a detail view) |

A cheap sanity rule: if getting it wrong would leak paid content to free users, lose a user's test progress, or misscore an exam attempt — pay for the better model on that task. If getting it wrong just looks slightly off, let the cheap model take a swing first.

## What's *not* covered here yet

This package covers Phase 1 (the scope you asked for: test-taking + solutions + plan gating). Video lectures, live classes, notes/high-yield charts, and spaced-repetition scheduling are intentionally out of scope — build the habit-forming test loop first, validate people actually use it, then decide if those are worth the production cost.
