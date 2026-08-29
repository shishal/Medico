-- Catalog sheet sync (Apps Script) upserts tests via PostgREST
--   POST /rest/v1/tests?on_conflict=sheet_key
--   Prefer: resolution=merge-duplicates
--
-- Phase 4B dropped tests_title_key (UNIQUE on title) so practice sessions can
-- all be titled 'Practice Session', and replaced it with a *partial* unique
-- index (title WHERE owner_user_id IS NULL).
--
-- Postgres error 42P10: PostgREST emits ON CONFLICT (title) with no WHERE
-- clause, so it cannot use a partial unique index. A non-partial UNIQUE
-- constraint is required. sheet_key is that constraint: catalog rows store
-- the sheet title; practice rows leave it NULL (UNIQUE allows multiple NULLs).

alter table public.tests
  add column if not exists sheet_key text;

comment on column public.tests.sheet_key is
  'Google Sheet catalog upsert key (usually the test title). NULL on practice sessions. Unique so PostgREST ON CONFLICT works after Phase 4B dropped tests_title_key.';

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'tests_sheet_key_key'
  ) then
    alter table public.tests
      add constraint tests_sheet_key_key unique (sheet_key);
  end if;
end $$;

-- Existing catalog tests (synced before this column existed).
update public.tests
set sheet_key = title
where owner_user_id is null
  and not is_ephemeral_practice
  and sheet_key is null;
