# Admin catalog seeds (not routine content sync)

These files are the affiliating-university + college catalog used at onboarding
(state → university → college). They are **not** read by `sync_content_csv` /
the Questions Google Sheet.

| File | Role |
|---|---|
| `MBBS_Colleges_by_State.xlsx` | Source workbook (State, University name, short form, College) |
| `Universities.csv` | Generated → `universities` (`code`, `name`, `state`, `slug`) |
| `Colleges.csv` | Generated → `colleges` (`university_code`, `name`) |

There is no separate `states` table — state is the `universities.state` column.

## Apply / refresh

```bash
# Rewrite CSVs from the Excel (dry-run; no DB writes)
python3 scripts/seed_universities_colleges.py

# Also replace the catalog in Supabase (needs DATABASE_URL in .env)
python3 scripts/seed_universities_colleges.py --apply
```

`--apply` clears every `profiles.college_id`, clears `profiles.university_id`
when the university code is not in the new list, deletes all colleges, deletes
universities absent from the seed (blocked if they still have `exam_papers`),
then upserts universities by `code` and re-inserts colleges.

Known legacy renames (exam papers / profiles stay attached):
- `IPU` → `GGSIPU`

Each university also gets an `Other / not listed` college row so students can
finish onboarding when their campus is missing from the sheet.

Colliding short forms (same code, different state/name) are disambiguated to
`{CODE}-{state-slug}` so `universities.code` stays unique — see script output.

MBBS year for each subject is **not** in this catalog. It comes from
`subject_phase_defaults` in Postgres (Anatomy → year1, etc.).
