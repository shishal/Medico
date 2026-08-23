-- Phase 2.2: natural keys for Google Sheet → Supabase upserts.
-- Apps Script syncs via PostgREST Prefer: resolution=merge-duplicates.

-- Stable content ID from the Questions sheet (e.g. Q-MED-CARD-001).
-- UNIQUE allows multiple NULLs, so Phase 1.3 seed rows without an id stay valid.
alter table public.questions
  add column if not exists external_id text;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'questions_external_id_key'
  ) then
    alter table public.questions
      add constraint questions_external_id_key unique (external_id);
  end if;
end $$;

-- Topics: unique per subject so upsert on (subject_id, name) works.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'topics_subject_id_name_key'
  ) then
    alter table public.topics
      add constraint topics_subject_id_name_key unique (subject_id, name);
  end if;
end $$;

-- Catalog tests: unique title for upsert. Phase 4B practice sessions may need
-- a partial unique index (title where owner_user_id is null) instead — revisit then.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'tests_title_key'
  ) then
    alter table public.tests
      add constraint tests_title_key unique (title);
  end if;
end $$;
