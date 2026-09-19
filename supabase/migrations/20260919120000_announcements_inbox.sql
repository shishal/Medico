-- In-app notifications inbox (no OS push).
-- Publish rows via Supabase Table Editor; students only SELECT active rows.

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null,
  category text not null default 'general'
    check (category in ('general', 'version', 'offer', 'payment')),
  deep_link text,
  is_active boolean not null default true,
  published_at timestamptz not null default now(),
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_announcements_active_published
  on public.announcements (published_at desc)
  where is_active;

comment on table public.announcements is
  'Broadcast in-app messages (version notes, offers, payment reminders). '
  'Write via Table Editor / service_role; students SELECT active non-expired rows.';

create table if not exists public.announcement_reads (
  user_id uuid not null references auth.users(id) on delete cascade,
  announcement_id uuid not null references public.announcements(id) on delete cascade,
  read_at timestamptz not null default now(),
  primary key (user_id, announcement_id)
);

create index if not exists idx_announcement_reads_user
  on public.announcement_reads (user_id);

comment on table public.announcement_reads is
  'Per-user read receipts for announcements. Students manage own rows only.';

alter table public.announcements enable row level security;
alter table public.announcement_reads enable row level security;

drop policy if exists "active announcements select" on public.announcements;
create policy "active announcements select" on public.announcements
  for select
  to authenticated
  using (
    is_active
    and (expires_at is null or expires_at > now())
  );

drop policy if exists "own announcement reads select" on public.announcement_reads;
create policy "own announcement reads select" on public.announcement_reads
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "own announcement reads insert" on public.announcement_reads;
create policy "own announcement reads insert" on public.announcement_reads
  for insert
  to authenticated
  with check (auth.uid() = user_id);

grant select on table public.announcements to authenticated;
grant select, insert on table public.announcement_reads to authenticated;
grant all on table public.announcements to service_role;
grant all on table public.announcement_reads to service_role;
