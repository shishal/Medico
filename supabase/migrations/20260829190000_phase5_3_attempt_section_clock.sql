-- Phase 5.3: wall-clock timer + sectional lock (docs/04_TEST_ENGINE_SPEC.md §3).
--
-- section_started_at lives on attempts so a force-quit cannot pause a section
-- by wiping local files. server_now() is the anti-cheat clock: remaining time
-- is duration - (now - started_at), never a saved "seconds left" value.

alter table public.attempts
  add column if not exists section_started_at jsonb not null default '{}'::jsonb;

comment on column public.attempts.section_started_at is
  'Map of section_number → timestamptz ISO string. Written when the student enters that section.';

create or replace function public.server_now()
returns timestamptz
language sql
stable
security invoker
as $$
  select now();
$$;

comment on function public.server_now() is
  'Postgres wall-clock for the test timer. If the device clock disagrees by more than a couple of minutes, the client trusts this value.';

grant execute on function public.server_now() to authenticated;
