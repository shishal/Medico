# Phase 2.2 — Apps Script sync

Bound this project to a Sheet that has a single `Questions` tab. The **Medico**
menu previews one transactional import and requires typing `APPLY` before writes.

## Prerequisites

1. Import `../tabs/Questions.csv` as tab `Questions`.
2. Apply migrations through
   `supabase/migrations/20260915200000_content_admin_seed_and_cleanup.sql`
   (subject → year map, universities/colleges seed, orphan cleanup, sync wiring).
3. Script properties: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.

## Install

Paste these files into Apps Script:

- `Code.gs`
- `SheetReader.gs`
- `SupabaseClient.gs`
- `Sync.gs`

## What Sync does

1. Reads `Questions` rows.
2. Calls `sync_content_csv(..., false)` for validation + counts.
3. Asks you to type `APPLY`.
4. Calls `sync_content_csv(..., true)` in one DB transaction.

Subjects get MBBS year from `subject_phase_defaults` (not from the CSV).
Unknown subject names fail validation.

## Validation

- Required: `subject_name`, `question_text`
- MCQ: options A–D + correct option
- Theory: leave options blank
- `university_code` + `exam_year` + `paper_name` together (no default university);
  `textbook_title` + `page` together; `resource_title` + `resource_url` together
- Resource URL must be `https://`

## Security

Never put the service_role key in the Flutter app or git.
