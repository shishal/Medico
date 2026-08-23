# Phase 2.1 — Google Sheet content structure

This folder is the **source of truth for the content CMS layout**. Import the CSVs under `tabs/` into a new Google Sheet (one CSV → one tab, tab names must match exactly). Phase 2.2 will bind Apps Script to that sheet and sync into Supabase.

A non-technical editor should only fill cells — no UUIDs, no SQL.

## Create the Sheet (one-time)

1. Open [Google Sheets](https://sheets.google.com) → **Blank spreadsheet**.
2. Rename the file to something like `Medico Content`.
3. For each file in `tabs/`:
   - File → Import → Upload → select the CSV.
   - Import location: **Insert new sheet(s)**.
   - Separator: Detect automatically.
4. Rename each imported sheet tab to the CSV stem exactly:
   - `Subjects`
   - `Topics`
   - `Questions`
   - `Tests`
   - `TestQuestions`
5. Delete the unused default `Sheet1` if it is empty.
6. (Optional) Add a non-synced `ReadMe` tab and paste the “Editor rules” section below for your content team.

Leave the sample rows in place until you have confirmed every required DB field has a column (Phase 2.1 validation). Replace them with real content when you start authoring.

## Tabs and columns

Human-friendly lookup columns replace UUID foreign keys. Names match the DB where possible (`snake_case`).

### `Subjects` → `subjects`

| Column | Required | Allowed / notes |
|---|---|---|
| `name` | yes | Unique. Natural upsert key. |
| `display_order` | yes | Integer. Lower = earlier in lists. |

### `Topics` → `topics`

| Column | Required | Allowed / notes |
|---|---|---|
| `subject_name` | yes | Must match a `Subjects.name` row (sync matches trim + case-insensitive). |
| `name` | yes | Topic title. Natural key with `subject_name`. |
| `display_order` | yes | Integer within that subject. |

**Editor rule:** every `topic_name` used on `Questions` must appear here under exactly one subject. Prefer globally unique topic names so `Questions.topic_name` lookups stay unambiguous.

### `Questions` → `questions`

| Column | Required | Allowed / notes |
|---|---|---|
| `external_id` | yes | Stable ID you invent (e.g. `Q-MED-CARD-001`). Natural upsert key; stored on `questions.external_id` (Phase 2.2 migration). Referenced by `TestQuestions`. |
| `topic_name` | yes | Must match a `Topics.name` (trim + case-insensitive; sync fails loudly with row number on miss). |
| `question_text` | yes | Stem / vignette. |
| `option_a` … `option_d` | yes | All four non-empty. |
| `correct_option` | yes | Exactly `A`, `B`, `C`, or `D`. |
| `explanation_text` | no | Solution write-up. |
| `explanation_video_url` | no | Full URL or blank. |
| `image_url` | no | Full URL or blank. |
| `difficulty` | yes | `easy` / `medium` / `hard`. |
| `source` | no | e.g. `PYQ 2024`, `Custom`. |
| `required_plan` | yes | `free` / `pro` / `elite`. |
| `is_active` | yes | `TRUE` / `FALSE`. |

### `Tests` → `tests`

| Column | Required | Allowed / notes |
|---|---|---|
| `title` | yes | Unique among catalog tests. Natural upsert key. |
| `description` | no | Shown on instructions screen later. |
| `test_type` | yes | `mini` / `subject` / `mock` / `grand`. |
| `subject_name` | no | Blank = mixed-subject. Else must match `Subjects.name`. |
| `required_plan` | yes | `free` / `pro` / `elite`. |
| `is_sectional` | yes | `TRUE` / `FALSE`. |
| `section_count` | yes | Integer ≥ 1. Use `1` when not sectional. |
| `questions_per_section` | no | Required when `is_sectional` is TRUE. |
| `section_duration_minutes` | no | Required when `is_sectional` is TRUE. |
| `total_duration_minutes` | yes | Whole-test timer (or sum of sections). |
| `total_questions` | yes | Must match how many `TestQuestions` rows you attach. |
| `correct_marks` | yes | e.g. `4`. |
| `incorrect_marks` | yes | e.g. `-1`. |
| `unattempted_marks` | yes | Usually `0`. |
| `is_live` | yes | `TRUE` / `FALSE`. |
| `live_start_at` | no | ISO-8601 timestamptz or blank. |
| `live_end_at` | no | ISO-8601 timestamptz or blank. |
| `is_active` | yes | `TRUE` / `FALSE`. |

### `TestQuestions` → `test_questions`

| Column | Required | Allowed / notes |
|---|---|---|
| `test_title` | yes | Must match a `Tests.title`. |
| `question_external_id` | yes | Must match a `Questions.external_id`. |
| `section_number` | yes | `1`…`section_count`. Use `1` when not sectional. |
| `order_index` | yes | 0-based or 1-based is fine — pick one and stay consistent (samples use **1-based**). |

## Editor rules (short)

1. Fill tabs in dependency order: **Subjects → Topics → Questions → Tests → TestQuestions**.
2. Never invent UUIDs; the sync script resolves names / `external_id`s.
3. Booleans: `TRUE` / `FALSE` (Google Sheets checkbox format is fine).
4. Enums must match the allowed values above exactly (lowercase for plans/types/difficulty; uppercase A–D for answers).
5. Prefer no trailing spaces in name / id cells; sync trims and matches case-insensitively, but canonical casing still comes from the Subjects/Topics tabs.
6. Empty optional cells stay blank; do not write `null` or `N/A`.

## Phase 2.2 — Sync

Install and run instructions: [`apps_script/README.md`](apps_script/README.md).

## Deferred

- **`Tags` / comma-separated tags on Questions** — schema §7 / Practice Mode (Phase 4B). Add when that phase starts; do not invent a Tags tab yet.

## Validation checklist (you, not the agent)

- [ ] Sheet has exactly these five sync tabs (names match).
- [ ] Each tab’s header row matches the CSV header order.
- [ ] 2–3 sample rows per tab are filled and cross-link (subjects ↔ topics ↔ questions ↔ tests ↔ test_questions).
- [ ] Every required DB field for content tables has a column (UUIDs replaced by name/`external_id` lookups as above).
- [ ] A content person can fill a new question without knowing Postgres.
