-- Phase 8.1: screenshot / screen-recording audit log.
--
-- iOS cannot block screenshots. The app still detects them and writes a row
-- here so repeat capture can be reviewed later. Android FLAG_SECURE already
-- blocks the capture; we log there too when the OS reports an attempt.
--
-- Authenticated users may INSERT their own rows only. No SELECT/UPDATE/
-- DELETE for students — this is an audit table, not a user-facing list.

create table if not exists public.screenshot_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  screen text not null,
  event_type text not null check (event_type in ('screenshot', 'screen_recording')),
  created_at timestamptz not null default now()
);

create index if not exists idx_screenshot_events_user_created
  on public.screenshot_events (user_id, created_at desc);

comment on table public.screenshot_events is
  'Phase 8.1 audit of screenshot / screen-recording attempts on content screens.';

alter table public.screenshot_events enable row level security;

drop policy if exists "own screenshot events insert" on public.screenshot_events;
create policy "own screenshot events insert" on public.screenshot_events
  for insert
  with check (auth.uid() = user_id);

grant insert on table public.screenshot_events to authenticated;
grant all on table public.screenshot_events to service_role;
