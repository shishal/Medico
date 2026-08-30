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
   - `Universities`, `Colleges`, `Phases`, `Subjects`, `Topics`, `Lessons`,
     `LessonResources`, `Textbooks`, `ExamPapers`, `Questions`, `Appearances`,
     `TextbookRefs`, `QuestionResources`
   - Optional legacy: `Tests`, `TestQuestions`
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
| `phase_code` | no | `phase1` / `phase2` / `phase3_part1` / `phase3_part2` (KUHS year). |

Questions: `kind` is `mcq` (default) or `pyq_theory`. Theory rows skip options.
Optional: `lesson_external_id`, `marks`, `sample_answer_text` (~250 words).
See `docs/00_PRODUCT.md` and `docs/02_DATABASE_SCHEMA.md` §10.

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
| `external_id` | yes | Stable ID you invent (e.g. `Q-ANAT-PYQ-001`). Natural upsert key. |
| `topic_name` | yes | Must match a `Topics.name`. |
| `question_text` | yes | Stem. |
| `kind` | no | `mcq` (default) or `pyq_theory`. |
| `option_a` … `option_d` | if `mcq` | All four non-empty for MCQ. Leave blank on theory PYQs. |
| `correct_option` | if `mcq` | Exactly `A`, `B`, `C`, or `D`. |
| `explanation_text` | no | MCQ tutor write-up. **Not** the theory sample answer. |
| `explanation_video_url` | no | Full URL or blank. |
| `image_url` | no | Full URL or blank. |
| `difficulty` | yes | `easy` / `medium` / `hard`. |
| `source` | no | e.g. `KUHS PYQ`. |
| `required_plan` | yes | `free` / `pro` / `elite`. |
| `is_active` | yes | `TRUE` / `FALSE`. |
| `lesson_external_id` | no | Must match a `Lessons.external_id`. |
| `marks` | no | Theory paper marks (e.g. `10`). |
| `sample_answer_text` | no | ~250-word model answer. Optional. Sync warns above ~400 words and does not reject. Stored in `question_sample_answers`, never as a column on `questions`. |

### `Universities` → `universities`

`code`, `name`, `state`, `slug`. v1: one KUHS row.

### `Colleges` → `colleges`

`university_code`, `name`.

### `Phases` → `mbbs_phases`

`code` (`phase1` / `phase2` / `phase3_part1` / `phase3_part2`), `name`, `display_order`. Seeded by migration; sheet is the human list.

### `Lessons` → `lessons`

`external_id`, `topic_name`, `name`, `display_order`, `required_plan`, `is_active`.

### `LessonResources` → `lesson_resources`

`lesson_external_id`, `title`, `url` (must be `https`), `source_label`, `display_order`, `is_free`. Optional. Do not link copyrighted textbook PDFs.

### `Textbooks` → `textbooks`

`sheet_key`, `title`, `authors`, `edition`. Citation metadata only.

### `ExamPapers` → `exam_papers`

`external_id`, `university_code`, `subject_name`, `exam_year`, `paper_name`, `exam_type` (`university` / `internal`).

### `Appearances` → `question_appearances`

`question_external_id`, `paper_external_id`. Every `pyq_theory` row needs at least one appearance.

### `TextbookRefs` → `question_textbook_refs`

`question_external_id`, `textbook_key`, `page`, `section_heading`. Page citation only.

### `QuestionResources` → `question_resources`

Same shape as LessonResources, keyed by `question_external_id`. Optional extras that do not belong to the whole lesson.

### `Tests` → `tests`

| Column | Required | Allowed / notes |
|---|---|---|
| `title` | yes | Unique among catalog tests. Sync stores this on `tests.sheet_key` for upserts (PostgREST cannot upsert on the partial unique index on `title`). |
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

1. Fill tabs in dependency order: **Universities → Colleges → Phases → Subjects → Topics → Lessons → Questions → Appearances → TextbookRefs**. Optional: LessonResources, QuestionResources, Tests.
2. Never invent UUIDs; the sync script resolves names / `external_id`s.
3. Booleans: `TRUE` / `FALSE` (Google Sheets checkbox format is fine).
4. Enums must match the allowed values above exactly (lowercase for plans/types/difficulty/kind; uppercase A–D for MCQ answers).
5. Prefer no trailing spaces in name / id cells; sync trims and matches case-insensitively, but canonical casing still comes from the Subjects/Topics tabs.
6. Empty optional cells stay blank; do not write `null` or `N/A`.
7. Theory PYQs do **not** need options. MCQ rows still do. Sample answers and topic links are optional — a stem + appearances is enough to ship.

## Phase 2.2 — Sync

Install and run instructions: [`apps_script/README.md`](apps_script/README.md).

## Deferred

- **`Tags` / comma-separated tags on Questions** — schema §7 / Practice Mode (Phase 4B). Add when that phase starts; do not invent a Tags tab yet.

## Validation checklist (you, not the agent)

- [ ] Sheet has the UG tabs listed above (names match). Tests/TestQuestions may stay for historical MCQ banks.
- [ ] Each tab’s header row matches the CSV header order.
- [ ] Sample rows include at least one `pyq_theory` (no options) and one `mcq`.
- [ ] A theory row missing `correct_option` still validates; an MCQ row missing options fails.
- [ ] Every `pyq_theory` row has ≥1 Appearances row.
- [ ] A content person can fill a new PYQ without knowing Postgres.
