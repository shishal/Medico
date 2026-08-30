# Medico

Flutter app for **KUHS MBBS university exams**: previous-year theory questions
(with optional sample answers and textbook page citations), lesson-scoped MCQ
practice, and exam trackers.

Planning docs: `docs/00_PRODUCT.md` (read first), then `docs/01`–`03`.

NEET-PG catalog tests are hidden from the home screen; the MCQ player remains
for practice sessions only.

## Apply the UG schema

```bash
# against your Supabase project
supabase db push
# or paste supabase/migrations/20260830140000_ug_university_pivot.sql
```

Then bind the Google Sheet tabs in `content/google_sheet/tabs/` (including
Universities, Lessons, Appearances, TextbookRefs) and run **Medico → Sync to App**.

Replace the WhatsApp number in `lib/core/support.dart` before a public listing.
