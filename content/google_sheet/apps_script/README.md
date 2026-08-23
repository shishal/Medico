# Phase 2.2 — Apps Script sync

Bound this project to your Google Sheet (from Phase 2.1). A **Medico → Sync to App** menu validates every tab, then upserts into Supabase via the REST API using the **service_role** key from Script Properties (never hardcoded).

## Prerequisites

1. Phase 2.1 sheet tabs exist with the headers in `../tabs/`.
2. Apply the migration `supabase/migrations/20260820133000_phase2_2_sheet_upsert_keys.sql` on your Supabase project (SQL editor or CLI). This adds:
   - `questions.external_id` (unique)
   - `topics (subject_id, name)` unique
   - `tests.title` unique
3. Supabase **Project URL** and **service_role** key (Settings → API). Treat service_role like a root password.

## Install into the Sheet

1. Open the Google Sheet → **Extensions → Apps Script**.
2. Delete any default `Code.gs` stub content.
3. Create files matching this folder and paste each file’s contents:
   - `Code.gs`
   - `SheetReader.gs`
   - `Validate.gs`
   - `SupabaseClient.gs`
   - `Sync.gs`
4. (Optional) Project Settings → update timezone; `appsscript.json` uses `Asia/Kolkata`.
5. **Project Settings → Script properties** (or older UI: File → Project properties → Script properties) add:

   | Property | Value |
   |---|---|
   | `SUPABASE_URL` | `https://YOUR_PROJECT.supabase.co` |
   | `SUPABASE_SERVICE_ROLE_KEY` | service_role secret |

6. Save → reload the Sheet → confirm the **Medico** menu appears.
7. **Medico → Check configuration** (should say OK without showing the key).

## What Sync does

1. Reads `Subjects`, `Topics`, `Questions`, `Tests`, `TestQuestions`.
2. Validates **all** rows (collects every error — does not stop at the first).
3. If any error: popup lists them with **tab + row number**; **writes nothing**.
4. If clean: upserts in order Subjects → Topics → Questions → Tests, then replaces `test_questions` for affected tests.

### Validation (includes Phase 2.2 required checks)

- `correct_option` ∈ A/B/C/D
- all four options non-empty
- `required_plan` ∈ free/pro/elite
- `topic_name` must match a Topics tab row (**trim + case-insensitive**; fails loudly with row number)
- plus header presence, enums, cross-links (`subject_name`, `test_title`, `question_external_id`), and `total_questions` vs link count

### Upsert keys (re-run safe)

| Table | Conflict target |
|---|---|
| subjects | `name` |
| topics | `subject_id,name` |
| questions | `external_id` |
| tests | `title` |
| test_questions | delete-by-test then insert (so removals/reorder apply) |

## Your validation

1. Sync once with sample rows → confirm rows appear in Supabase Table Editor.
2. Sync again unchanged → same row counts, no duplicates.
3. Set one `correct_option` to `E` → Sync → popup error, **no** Supabase changes for that run → fix and sync again.

## Security

- Never put service_role in the Flutter app, git-tracked `.env` committed to the repo, or cell formulas.
- Script Properties stay in the Apps Script project; restrict who can edit the Sheet / script.
