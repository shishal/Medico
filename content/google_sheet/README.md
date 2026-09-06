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

## Editor tabs

### `Universities` → `universities`

| Column | Required | Notes |
|---|---|---|
| `code` | yes | e.g. `KUHS`. Natural upsert key. |
| `name` | yes | Full university name. |
| `state` | yes | |
| `slug` | yes | URL-safe, lowercase. |
| `is_fallback` | no | `TRUE` on exactly one row (KUHS). Blank defaults to KUHS. |

### `Colleges` → `colleges`

`university_code`, `name`. Include **Other / not listed** per university so
onboarding never blocks.

### `Phases` → `mbbs_phases`

`code` (`phase1` / `phase2` / `phase3_part1` / `phase3_part2`), `name`,
`display_order`. Seeded by migration; the sheet is the human list.

### `Textbooks` → `textbooks`

`sheet_key`, `title`, `authors`, `edition`. Citation metadata only — never PDFs.
`sheet_key` stops title typos on the Questions tab.

### `Questions` → normalized tables

**One row = one question appearance** (or one textbook page). Repeat the same
`external_id` for extra papers or extra textbook pages. Sync upserts
`subjects`, `topics`, `lessons`, `questions`, `exam_papers`,
`question_appearances`, `question_textbook_refs`, and
`question_sample_answers`.

| Column | Required | Notes |
|---|---|---|
| `university_code` | if paper filled | Must match `Universities.code`. |
| `phase_code` | no | `phase1` / `phase2` / `phase3_part1` / `phase3_part2`. |
| `subject_name` | yes | Created on sync if new. |
| `topic_name` | yes | Created on sync if new. |
| `lesson_name` | yes | Created on sync if new. |
| `external_id` | yes | Stable ID you invent (e.g. `Q-ANAT-PYQ-001`). |
| `kind` | no | `mcq` (default) or `pyq_theory`. |
| `marks` | no | Theory paper marks. Essay ≥10, short 4–9, VSA ≤3. |
| `question_text` | yes | Stem. |
| `option_a` … `option_d` | if `mcq` | All four non-empty for MCQ. Blank on theory. |
| `correct_option` | if `mcq` | Exactly `A`, `B`, `C`, or `D`. |
| `explanation_text` | no | MCQ tutor write-up. **Not** the theory sample answer. |
| `sample_answer_text` | no | ~250-word model answer. Stored in `question_sample_answers`. |
| `difficulty` | yes | `easy` / `medium` / `hard`. |
| `required_plan` | yes | `free` / `pro` / `elite`. |
| `is_active` | yes | `TRUE` / `FALSE`. |
| `exam_year` | no | Blank OK for bank MCQs. |
| `paper_name` | no | e.g. `Paper I`. Blank skips the appearance. |
| `exam_type` | no | `university` / `internal`. Default `university`. |
| `textbook_key` | no | Must match `Textbooks.sheet_key`. |
| `page` | no | Integer page citation. |
| `section_heading` | no | |

### `LessonResources` → `lesson_resources` (optional)

URL lists do not fit a question row. `lesson_external_id` must match the id
sync invents from names (`L-SUBJECT-TOPIC-LESSON`, see
`inventLessonExternalId_` in Apps Script). `title`, `url` (`https`),
`source_label`, `display_order`, `is_free`. Do not link copyrighted textbook
PDFs.

## Editor rules (short)

1. Fill **Universities → Colleges → Phases → Textbooks → Questions**. Optional:
   LessonResources.
2. Never invent UUIDs. Repeat `external_id` when the same stem appeared in
   another paper or has another textbook page.
3. Booleans: `TRUE` / `FALSE` (Google Sheets checkboxes are fine).
4. Enums must match the allowed values exactly (lowercase for plans / types /
   difficulty / kind; uppercase A–D for MCQ answers).
5. Empty optional cells stay blank; do not write `null` or `N/A`.
6. Theory PYQs do **not** need options. MCQ rows still do. Sample answers are
   optional — a stem + paper columns is enough to ship.
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
