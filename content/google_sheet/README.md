# Google Sheet content CMS

Routine content entry uses **one file/tab**: `tabs/Questions.csv` → `Questions`.
Apps Script and `scripts/sync_content_csv.py` both call the same Supabase RPC.

Editors fill names only — never UUIDs. MBBS year (year1–year4) comes from
`subject_phase_defaults` in Postgres, not from the CSV.

Admin catalogs (universities / colleges) live in [`content/admin/`](../admin/)
and are seeded by migration, not by content sync.

## Create the Sheet (one-time)

1. Open [Google Sheets](https://sheets.google.com) → blank spreadsheet.
2. Import `tabs/Questions.csv` and name the tab exactly `Questions`.
3. Optional: add a non-synced ReadMe tab with the editor rules below.

## Lean `Questions` columns

| Column | Required | Notes |
|---|---|---|
| `subject_name` | yes | Must exist in `subject_phase_defaults` (e.g. Anatomy → year1). |
| `question_text` | yes | Stem. |
| `option_a` … `option_d` | if MCQ | Blank on theory. Any option/key cell ⇒ MCQ. |
| `correct_option` | if MCQ | `A` / `B` / `C` / `D`. |
| `topic_name` | no | Syllabus tag; created on sync. |
| `lesson_name` | no | Needs `topic_name` if filled. |
| `marks` | no | Theory format: ≥10 essay, 4–9 short, ≤3 VSA. |
| `exam_year` + `paper_name` | no | Fill both or neither. Defaults university = KUHS. |
| `textbook_title` + `page` | no | Fill both or neither. |
| `explanation_text` | no | EX. |
| `sample_answer_text` | no | DA (Pro-gated table). |
| `resource_title` + `resource_url` | no | Fill both or neither; `https` only. |

Optional advanced columns (allowed by sync, omitted from the lean template):
`kind`, `university_code`, `exam_type`, `textbook_authors`, `textbook_edition`,
`section_heading`, `difficulty`, `required_plan`, `is_active`,
`resource_source_label`, `resource_is_free`.

## Defaults

| Blank cell | Sync uses |
|---|---|
| kind | theory if no MCQ cells; else MCQ |
| university_code (when paper filled) | KUHS |
| exam_type | university |
| difficulty | medium |
| required_plan | free |
| is_active | TRUE |
| resource_is_free | TRUE |

## Editor rules

1. Only edit `Questions`. Never invent IDs.
2. Repeat the same subject + stem for another paper/page/resource.
3. Theory: leave options blank. MCQ: fill all four options + key.
4. Bank MCQs can omit paper fields (they will not appear in year browsing).
5. Preview shows destructive removals; type `APPLY` to confirm.

## Sync

See [`apps_script/README.md`](apps_script/README.md).

```bash
python3 scripts/sync_content_csv.py             # preview
python3 scripts/sync_content_csv.py --apply     # type APPLY to write
```

Apply migrations through
`supabase/migrations/20260915200000_content_admin_seed_and_cleanup.sql`
before the first sync.
