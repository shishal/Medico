# Google Sheet content CMS

This folder is the **source of truth for the content CMS layout**. Import the
CSVs under `tabs/` into a Google Sheet (one CSV → one tab, tab names must
match exactly). Apps Script validates the sheet and upserts **normalized**
Supabase tables.

A non-technical editor should only fill cells — **names, not UUIDs**.

## Create the Sheet (one-time)

1. Open [Google Sheets](https://sheets.google.com) → **Blank spreadsheet**.
2. Rename the file to something like `Medico Content`.
3. For each file in `tabs/`:
   - File → Import → Upload → select the CSV.
   - Import location: **Insert new sheet(s)**.
   - Separator: Detect automatically.
4. Rename each imported sheet tab to the CSV stem exactly:
   - `Universities`, `Colleges`, `Phases`, `Textbooks`, `Questions`,
     `LessonResources`
5. Delete the unused default `Sheet1` if it is empty.
6. (Optional) Add a non-synced `ReadMe` tab and paste the “Editor rules”
   section below.

The CSVs in `tabs/` are a **full KUHS seed** written as a wide `Questions`
tab. Hierarchy (subjects, topics, lessons, exam papers, appearances, textbook
refs) is **created on sync**. Import as-is, then edit in the Sheet. To
regenerate from the Python catalog:

```bash
python3 scripts/generate_ug_seed_csvs.py
```

**Retired editor tabs** (do not recreate): `Subjects`, `Topics`, `Lessons`,
`ExamPapers`, `Appearances`, `TextbookRefs`, `QuestionResources`, `Tests`,
`TestQuestions`. An older sheet that still has those tabs can keep using the
legacy validator until you switch the Questions header to the wide columns.

Trackers were never a sheet tab (in-app rows + SQL seed only). Drop leftover
DB objects with `supabase/migrations/20260912120000_drop_trackers.sql`.
University `is_fallback` is retired; drop with
`supabase/migrations/20260913120000_drop_university_fallback.sql`.

## Editor tabs

### `Universities` → `universities`

| Column | Required | Notes |
|---|---|---|
| `code` | yes | e.g. `KUHS`. Natural upsert key. |
| `name` | yes | Full university name. |
| `state` | yes | Stored with the university. |

`universities.slug` is **not a sheet column**. Sync writes `lower(code)` (so `KUHS` → `kuhs`) for website URLs. An old `slug` or `is_fallback` column is ignored. If a university has no papers, the app shows empty PYQs — it does not substitute another bank.

### `Colleges` → `colleges`

`university_code`, `name`. Include **Other / not listed** per university so
onboarding never blocks.

### `Phases` → `mbbs_phases`

Optional. Migration already seeds the four MBBS years. Re-import this tab
only if you need to rename them. Sync reads `mbbs_phases` from Supabase;
it does not require this sheet.

### `Textbooks` → `textbooks`

`sheet_key`, `title`, `authors`, `edition`. Citation metadata only — never PDFs.
`sheet_key` stops title typos on the Questions tab.

### `Questions` → normalized tables

**One row = one question appearance** (or one textbook page). Repeat the same
`external_id` for extra papers or extra textbook pages. Sync upserts
`subjects`, `topics`, `lessons`, `questions`, `exam_papers`,
`question_appearances`, `question_textbook_refs`, and
`question_sample_answers`.

Headers with a default are named like `kind(Default-MCQ)` so the sheet itself
shows the fallback. Sync strips the `(Default-…)` suffix.

| Column | Required | Notes |
|---|---|---|
| `university_code` | if paper filled | Must match `Universities.code`. |
| `phase_code` | no | `year1` / `year2` / `year3` / `year4`. |
| `subject_name` | yes | Created on sync if new. |
| `topic_name` | no | Created on sync if new. Blank leaves the question untagged. |
| `lesson_name` | no | Created on sync if new. Needs `topic_name` if filled. |
| `external_id` | yes | Stable ID you invent (e.g. `Q-ANAT-PYQ-001`). |
| `kind(Default-MCQ)` | no | `mcq` or `pyq_theory`. Blank: theory if all options + `correct_option` are empty, else MCQ. |
| `marks` | no | Theory paper marks. Essay ≥10, short 4–9, VSA ≤3. |
| `question_text` | yes | Stem. |
| `option_a` … `option_d` | if `mcq` | All four non-empty for MCQ. Blank on theory. |
| `correct_option` | if `mcq` | Exactly `A`, `B`, `C`, or `D`. |
| `explanation_text` | no | **EX** for any kind (theory or MCQ). Tutor write-up; not the direct answer. |
| `sample_answer_text` | no | **DA** for any kind. Model / short answer. Stored in `question_sample_answers`. |
| `difficulty(Default-medium)` | no | `easy` / `medium` / `hard`. |
| `required_plan(Default-free)` | no | `free` / `pro` / `elite`. |
| `is_active(Default-TRUE)` | no | `TRUE` / `FALSE`. |
| `exam_year` | no | Blank OK for bank MCQs. |
| `paper_name` | no | e.g. `Paper I`. Blank skips the appearance. |
| `exam_type(Default-university)` | no | `university` / `internal`. |
| `textbook_key` | no | Must match `Textbooks.sheet_key`. |
| `page` | no | Integer page citation. |
| `section_heading` | no | |

### `LessonResources` → `lesson_resources` (optional)

`subject_name`, `topic_name`, `lesson_name` must match a Questions lesson
(sync derives the internal `L-…` id). Then `title`, `url` (`https`),
`source_label`, `display_order(Default-1)`, `is_free(Default-TRUE)`. Do not
link copyrighted textbook PDFs.

## What you can leave blank

Sync already invents subjects, topics, lessons, exam papers, appearances, and
textbook refs from the wide Questions row. Extra blanks it now fills:

| Sheet cell | If blank, sync writes |
|---|---|
| Universities `slug` | *(column removed)* `lower(code)` |
| Questions `kind(Default-MCQ)` | `pyq_theory` if no MCQ options; else `mcq` |
| Questions `difficulty(Default-medium)` | `medium` |
| Questions `required_plan(Default-free)` | `free` |
| Questions `is_active(Default-TRUE)` | `TRUE` |
| Questions `topic_name` | no topic row; `questions.topic_id` stays null |
| Questions `lesson_name` | no lesson row; `questions.lesson_id` stays null |
| Questions `exam_type(Default-university)` | `university` |
| LessonResources `display_order(Default-1)` | 1, then 2, … per lesson |
| LessonResources `is_free(Default-TRUE)` | `TRUE` |

**Still type these** — they are content, not metadata: `code` / `name` /
`state` on Universities; college names; textbook `sheet_key` + title (join
key for `textbook_key`); question `external_id`, `subject_name`, stem, MCQ
options, paper year + paper name, page citations. `topic_name` / `lesson_name`
can wait until the chapter is known. LessonResources still need
subject/topic/lesson names plus title and https URL.

**Not worth dropping yet:** `state` is unused in the app UI today but NOT
NULL in Postgres. `phase_code` tags a new subject to an MBBS year (cannot
guess a new subject). `external_id` must be stable when the same stem
repeats on another paper.

## Editor rules (short)

1. Fill **Universities → Colleges → Textbooks → Questions**. Optional:
   LessonResources. Phases is optional (already seeded in Supabase).
2. Never invent UUIDs. Repeat `external_id` when the same stem appeared in
   another paper or has another textbook page.
3. Booleans: `TRUE` / `FALSE` (Google Sheets checkboxes are fine). Blank
   `is_active` means TRUE.
4. Enums must match the allowed values exactly (lowercase for plans / types /
   difficulty / kind; uppercase A–D for MCQ answers).
5. Empty optional cells stay blank; do not write `null` or `N/A`.
6. Theory PYQs do **not** need options or `kind`. MCQ rows still need options.
   Sample answers are optional — a stem + paper columns is enough to ship.
7. Bank MCQs can leave `exam_year` / `paper_name` blank.

## Phase 2.2 — Sync

Install and run instructions: [`apps_script/README.md`](apps_script/README.md).
Paste `WideSheet.gs` into the bound project along with the other `.gs` files.

## Validation checklist (you, not the agent)

- [ ] Sheet has the editor tabs listed above (names match).
- [ ] Questions header includes `university_code` and `subject_name` (wide).
- [ ] Sample rows include at least one `pyq_theory` (no options) and one `mcq`.
- [ ] A theory row missing `correct_option` still validates; an MCQ row missing
      options fails.
- [ ] Two rows can share `external_id` with different papers.
- [ ] A content person can fill a new PYQ without knowing Postgres.
