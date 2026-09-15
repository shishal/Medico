# Admin catalog seeds (not routine content sync)

These CSVs are reference copies of data that lives in Supabase. They are
**not** read by `sync_content_csv` / the Questions Google Sheet.

Apply `supabase/migrations/20260915200000_content_admin_seed_and_cleanup.sql`
to seed universities, colleges, and the subject → MBBS-year map.

| File | Table |
|---|---|
| `Universities.csv` | `universities` |
| `Colleges.csv` | `colleges` |

MBBS year for each subject is **not** a CSV column. It comes from
`subject_phase_defaults` in Postgres (Anatomy → year1, etc.).
