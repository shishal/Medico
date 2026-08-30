-- UG university-exam catalog (docs/02_DATABASE_SCHEMA.md §10).
-- Additive: NEET-PG tables stay. Home IA hides the old test catalog.

-- ---------------------------------------------------------------------------
-- 9.1 Enums
-- ---------------------------------------------------------------------------

do $$ begin
  create type public.question_kind as enum ('pyq_theory', 'mcq');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.mbbs_phase_code as enum (
    'phase1', 'phase2', 'phase3_part1', 'phase3_part2'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.tracker_kind as enum ('university_window', 'custom');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.study_event_kind as enum (
    'opened_lesson', 'opened_pyq', 'marked_learnt', 'answered_mcq', 'opened_resource'
  );
exception when duplicate_object then null;
end $$;

-- ---------------------------------------------------------------------------
-- Universities, phases, colleges
-- ---------------------------------------------------------------------------

create table if not exists public.universities (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  state text not null,
  slug text not null unique
);

create table if not exists public.mbbs_phases (
  id uuid primary key default gen_random_uuid(),
  code public.mbbs_phase_code not null unique,
  name text not null,
  display_order int not null default 0
);

create table if not exists public.colleges (
  id uuid primary key default gen_random_uuid(),
  university_id uuid not null references public.universities(id) on delete cascade,
  name text not null,
  unique (university_id, name)
);

insert into public.universities (code, name, state, slug)
values (
  'KUHS',
  'Kerala University of Health Sciences',
  'Kerala',
  'kuhs'
)
on conflict (code) do nothing;

insert into public.mbbs_phases (code, name, display_order) values
  ('phase1', '1st year', 1),
  ('phase2', '2nd year', 2),
  ('phase3_part1', '3rd year', 3),
  ('phase3_part2', 'Final year', 4)
on conflict (code) do nothing;

insert into public.colleges (university_id, name)
select u.id, c.name
from public.universities u
cross join (values
  ('Government Medical College, Thiruvananthapuram'),
  ('Government Medical College, Kozhikode'),
  ('Government Medical College, Kottayam'),
  ('Government Medical College, Thrissur'),
  ('Amrita School of Medicine, Kochi'),
  ('Jubilee Mission Medical College, Thrissur'),
  ('Malankara Orthodox Syrian Church Medical College, Kolenchery'),
  ('Pushpagiri Institute of Medical Sciences, Thiruvalla')
) as c(name)
where u.code = 'KUHS'
on conflict (university_id, name) do nothing;

-- ---------------------------------------------------------------------------
-- Subjects + lessons
-- ---------------------------------------------------------------------------

alter table public.subjects
  add column if not exists mbbs_phase_id uuid references public.mbbs_phases(id);

alter table public.subjects
  add column if not exists required_plan public.plan_tier not null default 'free';

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references public.topics(id) on delete cascade,
  external_id text not null unique,
  name text not null,
  display_order int not null default 0,
  required_plan public.plan_tier not null default 'free',
  is_active boolean not null default true,
  unique (topic_id, name)
);
create index if not exists idx_lessons_topic on public.lessons(topic_id);

create table if not exists public.textbooks (
  id uuid primary key default gen_random_uuid(),
  sheet_key text not null unique,
  title text not null,
  authors text,
  edition text
);

create table if not exists public.exam_papers (
  id uuid primary key default gen_random_uuid(),
  external_id text not null unique,
  university_id uuid not null references public.universities(id),
  subject_id uuid not null references public.subjects(id),
  exam_year int not null,
  paper_name text not null,
  exam_type text not null default 'university'
    check (exam_type in ('university', 'internal'))
);

create table if not exists public.lesson_resources (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  title text not null,
  url text not null,
  source_label text,
  display_order int not null default 0,
  is_free boolean not null default false,
  unique (lesson_id, url)
);

create table if not exists public.question_resources (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  title text not null,
  url text not null,
  source_label text,
  display_order int not null default 0,
  is_free boolean not null default false,
  unique (question_id, url)
);

-- ---------------------------------------------------------------------------
-- Dual-kind questions
-- ---------------------------------------------------------------------------

alter table public.questions
  add column if not exists kind public.question_kind not null default 'mcq';

alter table public.questions
  add column if not exists lesson_id uuid references public.lessons(id) on delete restrict;

alter table public.questions
  add column if not exists marks numeric;

alter table public.questions alter column option_a drop not null;
alter table public.questions alter column option_b drop not null;
alter table public.questions alter column option_c drop not null;
alter table public.questions alter column option_d drop not null;
alter table public.questions alter column correct_option drop not null;
-- Phase 1 CHECK only allowed A–D. Theory PYQs send NULL; keep that CHECK from
-- rejecting them (SQL CHECK treats NULL as pass, but '' is not in A–D).
alter table public.questions drop constraint if exists questions_correct_option_check;
alter table public.questions add constraint questions_correct_option_check
  check (correct_option is null or correct_option in ('A', 'B', 'C', 'D'));

alter table public.questions drop constraint if exists questions_kind_shape;
alter table public.questions add constraint questions_kind_shape check (
  (
    kind = 'mcq'
    and option_a is not null
    and option_b is not null
    and option_c is not null
    and option_d is not null
    and correct_option is not null
  )
  or kind = 'pyq_theory'
);

create table if not exists public.question_sample_answers (
  question_id uuid primary key references public.questions(id) on delete cascade,
  body text not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.question_appearances (
  question_id uuid not null references public.questions(id) on delete cascade,
  exam_paper_id uuid not null references public.exam_papers(id) on delete cascade,
  primary key (question_id, exam_paper_id)
);

create table if not exists public.question_textbook_refs (
  question_id uuid not null references public.questions(id) on delete cascade,
  textbook_id uuid not null references public.textbooks(id) on delete restrict,
  page int not null,
  section_heading text,
  primary key (question_id, textbook_id, page)
);

-- security_invoker = true: the caller's questions RLS still applies, so a
-- free user never receives Pro stems through this view.
create or replace view public.pyq_teasers
with (security_invoker = true) as
select
  q.id,
  q.lesson_id,
  q.topic_id,
  q.question_text,
  q.marks,
  q.required_plan,
  q.is_active,
  (
    select count(*)::int
    from public.question_appearances a
    where a.question_id = q.id
  ) as appearance_count
from public.questions q
where q.kind = 'pyq_theory'
  and q.is_active;

comment on view public.pyq_teasers is
  'Theory PYQ stems + frequency. No sample answers, no MCQ keys.';

-- ---------------------------------------------------------------------------
-- Profile academic fields + 4-day Pro trial for new signups
-- ---------------------------------------------------------------------------

alter table public.profiles
  add column if not exists university_id uuid references public.universities(id);

alter table public.profiles
  add column if not exists college_id uuid references public.colleges(id);

alter table public.profiles
  add column if not exists batch_year int;

alter table public.profiles
  add column if not exists mbbs_phase_id uuid references public.mbbs_phases(id);

alter table public.profiles
  add column if not exists onboarding_completed_at timestamptz;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, plan, plan_started_at, plan_expires_at)
  values (new.id, 'pro', now(), now() + interval '4 days');
  return new;
end;
$$;

revoke update on table public.profiles from authenticated;
grant update (
  full_name,
  phone,
  university_id,
  college_id,
  batch_year,
  mbbs_phase_id,
  onboarding_completed_at
) on table public.profiles to authenticated;

-- ---------------------------------------------------------------------------
-- Progress, bookmarks, events, trackers
-- ---------------------------------------------------------------------------

create table if not exists public.lesson_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  learnt_at timestamptz,
  last_viewed_at timestamptz not null default now(),
  primary key (user_id, lesson_id)
);

create table if not exists public.question_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  learnt_at timestamptz,
  last_viewed_at timestamptz not null default now(),
  primary key (user_id, question_id)
);

create table if not exists public.lesson_bookmarks (
  user_id uuid not null references auth.users(id) on delete cascade,
  lesson_id uuid not null references public.lessons(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, lesson_id)
);

create table if not exists public.study_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind public.study_event_kind not null,
  lesson_id uuid references public.lessons(id) on delete set null,
  question_id uuid references public.questions(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists idx_study_events_user_created
  on public.study_events (user_id, created_at desc);

create table if not exists public.trackers (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid references auth.users(id) on delete cascade,
  university_id uuid references public.universities(id),
  kind public.tracker_kind not null,
  title text not null,
  starts_on date,
  ends_on date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint trackers_owner_matches_kind check (
    (kind = 'custom' and owner_user_id is not null)
    or (kind = 'university_window' and owner_user_id is null)
  )
);

create table if not exists public.tracker_items (
  id uuid primary key default gen_random_uuid(),
  tracker_id uuid not null references public.trackers(id) on delete cascade,
  lesson_id uuid references public.lessons(id) on delete cascade,
  question_id uuid references public.questions(id) on delete cascade,
  display_order int not null default 0,
  constraint tracker_items_has_target check (
    lesson_id is not null or question_id is not null
  )
);
create index if not exists idx_tracker_items_tracker on public.tracker_items(tracker_id);

create table if not exists public.user_tracker_item_done (
  user_id uuid not null references auth.users(id) on delete cascade,
  tracker_item_id uuid not null references public.tracker_items(id) on delete cascade,
  done_at timestamptz not null default now(),
  primary key (user_id, tracker_item_id)
);

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------

alter table public.universities enable row level security;
alter table public.mbbs_phases enable row level security;
alter table public.colleges enable row level security;
alter table public.lessons enable row level security;
alter table public.textbooks enable row level security;
alter table public.exam_papers enable row level security;
alter table public.lesson_resources enable row level security;
alter table public.question_resources enable row level security;
alter table public.question_sample_answers enable row level security;
alter table public.question_appearances enable row level security;
alter table public.question_textbook_refs enable row level security;
alter table public.lesson_progress enable row level security;
alter table public.question_progress enable row level security;
alter table public.lesson_bookmarks enable row level security;
alter table public.study_events enable row level security;
alter table public.trackers enable row level security;
alter table public.tracker_items enable row level security;
alter table public.user_tracker_item_done enable row level security;

drop policy if exists "universities readable" on public.universities;
create policy "universities readable" on public.universities
  for select using (auth.role() = 'authenticated');

drop policy if exists "mbbs_phases readable" on public.mbbs_phases;
create policy "mbbs_phases readable" on public.mbbs_phases
  for select using (auth.role() = 'authenticated');

drop policy if exists "colleges readable" on public.colleges;
create policy "colleges readable" on public.colleges
  for select using (auth.role() = 'authenticated');

drop policy if exists "lessons readable" on public.lessons;
create policy "lessons readable" on public.lessons
  for select using (auth.role() = 'authenticated');

drop policy if exists "textbooks readable" on public.textbooks;
create policy "textbooks readable" on public.textbooks
  for select using (auth.role() = 'authenticated');

drop policy if exists "exam_papers readable" on public.exam_papers;
create policy "exam_papers readable" on public.exam_papers
  for select using (auth.role() = 'authenticated');

drop policy if exists "lesson resources select" on public.lesson_resources;
create policy "lesson resources select" on public.lesson_resources
  for select using (
    is_free
    or exists (
      select 1 from public.lessons l
      where l.id = lesson_resources.lesson_id
        and public.plan_rank(public.current_plan(auth.uid()))
            >= public.plan_rank(l.required_plan)
    )
  );

drop policy if exists "question resources select" on public.question_resources;
create policy "question resources select" on public.question_resources
  for select using (
    is_free
    or exists (
      select 1 from public.questions q
      where q.id = question_resources.question_id
        and public.plan_rank(public.current_plan(auth.uid()))
            >= public.plan_rank(q.required_plan)
    )
  );

drop policy if exists "sample answers pro" on public.question_sample_answers;
create policy "sample answers pro" on public.question_sample_answers
  for select using (
    public.plan_rank(public.current_plan(auth.uid()))
      >= public.plan_rank('pro'::public.plan_tier)
  );

drop policy if exists "appearances readable" on public.question_appearances;
create policy "appearances readable" on public.question_appearances
  for select using (auth.role() = 'authenticated');

drop policy if exists "textbook refs readable" on public.question_textbook_refs;
create policy "textbook refs readable" on public.question_textbook_refs
  for select using (auth.role() = 'authenticated');

drop policy if exists "own lesson_progress" on public.lesson_progress;
create policy "own lesson_progress" on public.lesson_progress
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own question_progress" on public.question_progress;
create policy "own question_progress" on public.question_progress
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own lesson_bookmarks" on public.lesson_bookmarks;
create policy "own lesson_bookmarks" on public.lesson_bookmarks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own study_events insert" on public.study_events;
create policy "own study_events insert" on public.study_events
  for insert with check (auth.uid() = user_id);

drop policy if exists "own study_events select" on public.study_events;
create policy "own study_events select" on public.study_events
  for select using (auth.uid() = user_id);

drop policy if exists "trackers select" on public.trackers;
create policy "trackers select" on public.trackers
  for select using (
    (kind = 'university_window' and is_active)
    or owner_user_id = auth.uid()
  );

drop policy if exists "own custom trackers insert" on public.trackers;
create policy "own custom trackers insert" on public.trackers
  for insert with check (
    kind = 'custom' and owner_user_id = auth.uid()
  );

drop policy if exists "own custom trackers update" on public.trackers;
create policy "own custom trackers update" on public.trackers
  for update using (owner_user_id = auth.uid());

drop policy if exists "own custom trackers delete" on public.trackers;
create policy "own custom trackers delete" on public.trackers
  for delete using (owner_user_id = auth.uid());

drop policy if exists "tracker_items select" on public.tracker_items;
create policy "tracker_items select" on public.tracker_items
  for select using (
    exists (
      select 1 from public.trackers t
      where t.id = tracker_items.tracker_id
        and (
          (t.kind = 'university_window' and t.is_active)
          or t.owner_user_id = auth.uid()
        )
    )
  );

drop policy if exists "own tracker_items write" on public.tracker_items;
create policy "own tracker_items write" on public.tracker_items
  for all using (
    exists (
      select 1 from public.trackers t
      where t.id = tracker_items.tracker_id and t.owner_user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1 from public.trackers t
      where t.id = tracker_items.tracker_id and t.owner_user_id = auth.uid()
    )
  );

drop policy if exists "own tracker done" on public.user_tracker_item_done;
create policy "own tracker done" on public.user_tracker_item_done
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select on table public.universities to authenticated;
grant select on table public.mbbs_phases to authenticated;
grant select on table public.colleges to authenticated;
grant select on table public.lessons to authenticated;
grant select on table public.textbooks to authenticated;
grant select on table public.exam_papers to authenticated;
grant select on table public.lesson_resources to authenticated;
grant select on table public.question_resources to authenticated;
grant select on table public.question_sample_answers to authenticated;
grant select on table public.question_appearances to authenticated;
grant select on table public.question_textbook_refs to authenticated;
grant select on public.pyq_teasers to authenticated, service_role;

grant select, insert, update, delete on table public.lesson_progress to authenticated;
grant select, insert, update, delete on table public.question_progress to authenticated;
grant select, insert, update, delete on table public.lesson_bookmarks to authenticated;
grant select, insert on table public.study_events to authenticated;
grant select, insert, update, delete on table public.trackers to authenticated;
grant select, insert, update, delete on table public.tracker_items to authenticated;
grant select, insert, update, delete on table public.user_tracker_item_done to authenticated;

grant all on all tables in schema public to service_role;

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------

create or replace function public.mark_lesson_learnt(p_lesson_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  insert into public.lesson_progress (user_id, lesson_id, learnt_at, last_viewed_at)
  values (auth.uid(), p_lesson_id, now(), now())
  on conflict (user_id, lesson_id) do update
    set learnt_at = coalesce(public.lesson_progress.learnt_at, now()),
        last_viewed_at = now();

  insert into public.study_events (user_id, kind, lesson_id)
  values (auth.uid(), 'marked_learnt', p_lesson_id);
end;
$$;

create or replace function public.mark_question_learnt(p_question_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  insert into public.question_progress (user_id, question_id, learnt_at, last_viewed_at)
  values (auth.uid(), p_question_id, now(), now())
  on conflict (user_id, question_id) do update
    set learnt_at = coalesce(public.question_progress.learnt_at, now()),
        last_viewed_at = now();

  insert into public.study_events (user_id, kind, question_id)
  values (auth.uid(), 'marked_learnt', p_question_id);
end;
$$;

create or replace function public.record_study_event(
  p_kind public.study_event_kind,
  p_lesson_id uuid default null,
  p_question_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  insert into public.study_events (user_id, kind, lesson_id, question_id)
  values (auth.uid(), p_kind, p_lesson_id, p_question_id);

  if p_lesson_id is not null then
    insert into public.lesson_progress (user_id, lesson_id, last_viewed_at)
    values (auth.uid(), p_lesson_id, now())
    on conflict (user_id, lesson_id) do update
      set last_viewed_at = now();
  end if;

  if p_question_id is not null then
    insert into public.question_progress (user_id, question_id, last_viewed_at)
    values (auth.uid(), p_question_id, now())
    on conflict (user_id, question_id) do update
      set last_viewed_at = now();
  end if;
end;
$$;

create or replace function public.get_study_progress()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_phase uuid;
  v_streak int := 0;
  v_cursor date := current_date;
  v_has boolean;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  select mbbs_phase_id into v_phase from public.profiles where id = v_uid;

  -- Streak: consecutive days with ≥1 event, allowing yesterday if nothing today.
  loop
    select exists (
      select 1 from public.study_events e
      where e.user_id = v_uid
        and e.created_at::date = v_cursor
    ) into v_has;

    if not v_has then
      if v_cursor = current_date then
        v_cursor := v_cursor - 1;
        continue;
      end if;
      exit;
    end if;

    v_streak := v_streak + 1;
    v_cursor := v_cursor - 1;
  end loop;

  return jsonb_build_object(
    'streak', v_streak,
    'days7', coalesce((
      select jsonb_agg(jsonb_build_object('date', d::text, 'count', c) order by d)
      from (
        select gs::date as d, count(e.id) as c
        from generate_series(current_date - 6, current_date, interval '1 day') gs
        left join public.study_events e
          on e.user_id = v_uid and e.created_at::date = gs::date
        group by gs::date
      ) t
    ), '[]'::jsonb),
    'days30', coalesce((
      select jsonb_agg(jsonb_build_object('date', d::text, 'count', c) order by d)
      from (
        select gs::date as d, count(e.id) as c
        from generate_series(current_date - 29, current_date, interval '1 day') gs
        left join public.study_events e
          on e.user_id = v_uid and e.created_at::date = gs::date
        group by gs::date
      ) t
    ), '[]'::jsonb),
    'subjects', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'learnt_lessons', (
          select count(*) from public.lessons l
          join public.topics tp on tp.id = l.topic_id
          join public.lesson_progress lp
            on lp.lesson_id = l.id and lp.user_id = v_uid and lp.learnt_at is not null
          where tp.subject_id = s.id and l.is_active
        ),
        'total_lessons', (
          select count(*) from public.lessons l
          join public.topics tp on tp.id = l.topic_id
          where tp.subject_id = s.id and l.is_active
        )
      ) order by s.display_order)
      from public.subjects s
      where v_phase is null or s.mbbs_phase_id = v_phase
    ), '[]'::jsonb)
  );
end;
$$;

create or replace function public.tracker_completion(p_tracker_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_total int;
  v_done int;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if not exists (
    select 1 from public.trackers t
    where t.id = p_tracker_id
      and (
        (t.kind = 'university_window' and t.is_active)
        or t.owner_user_id = v_uid
      )
  ) then
    raise exception 'TRACKER_NOT_FOUND';
  end if;

  select count(*) into v_total
  from public.tracker_items
  where tracker_id = p_tracker_id;

  -- Done = explicit tick OR learnt progress on the linked lesson/question.
  select count(*) into v_done
  from public.tracker_items i
  where i.tracker_id = p_tracker_id
    and (
      exists (
        select 1 from public.user_tracker_item_done d
        where d.tracker_item_id = i.id and d.user_id = v_uid
      )
      or (
        i.lesson_id is not null
        and exists (
          select 1 from public.lesson_progress lp
          where lp.lesson_id = i.lesson_id
            and lp.user_id = v_uid
            and lp.learnt_at is not null
        )
      )
      or (
        i.question_id is not null
        and exists (
          select 1 from public.question_progress qp
          where qp.question_id = i.question_id
            and qp.user_id = v_uid
            and qp.learnt_at is not null
        )
      )
    );

  return jsonb_build_object(
    'done', v_done,
    'total', v_total,
    'percent', case when v_total = 0 then 0
      else round(100.0 * v_done / v_total, 1) end
  );
end;
$$;

create or replace function public.search_catalog(p_query text)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_q text := '%' || coalesce(trim(p_query), '') || '%';
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if char_length(trim(coalesce(p_query, ''))) < 2 then
    return jsonb_build_object('subjects', '[]'::jsonb, 'lessons', '[]'::jsonb, 'questions', '[]'::jsonb);
  end if;

  return jsonb_build_object(
    'subjects', coalesce((
      select jsonb_agg(jsonb_build_object('id', s.id, 'name', s.name))
      from public.subjects s
      where s.name ilike v_q
        and public.plan_rank(public.current_plan(auth.uid()))
            >= public.plan_rank(coalesce(s.required_plan, 'free'::public.plan_tier))
    ), '[]'::jsonb),
    'lessons', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', l.id, 'name', l.name, 'required_plan', l.required_plan
      ))
      from public.lessons l
      where l.is_active and l.name ilike v_q
        and public.plan_rank(public.current_plan(auth.uid()))
            >= public.plan_rank(l.required_plan)
      limit 20
    ), '[]'::jsonb),
    'questions', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', t.id,
        'question_text', t.question_text,
        'lesson_id', t.lesson_id,
        'required_plan', t.required_plan,
        'appearance_count', t.appearance_count
      ))
      from public.pyq_teasers t
      where t.question_text ilike v_q
        and public.plan_rank(public.current_plan(auth.uid()))
            >= public.plan_rank(t.required_plan)
      limit 20
    ), '[]'::jsonb)
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- Practice: MCQ-only + optional lesson filter
-- ---------------------------------------------------------------------------

drop function if exists public.create_practice_session(
  uuid[], uuid[], public.question_difficulty[], text, int, text, text, int, boolean
);

create or replace function public.create_practice_session(
  p_topic_ids uuid[],
  p_tag_ids uuid[],
  p_difficulties public.question_difficulty[],
  p_source_filter text,
  p_question_count int,
  p_feedback_timing text,
  p_explanation_level text,
  p_timer_minutes int,
  p_negative_marking boolean,
  p_lesson_ids uuid[] default null
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_plan public.plan_tier;
  v_limits public.plan_limits%rowtype;
  v_test_id uuid;
  v_effective_count int;
  v_effective_explanation text;
  v_used_today int;
  v_topic_ids uuid[];
  v_lesson_ids uuid[];
  v_tag_ids uuid[];
  v_difficulties public.question_difficulty[];
  v_timer_minutes int;
  v_negative_marking boolean;
  v_actual_count int;
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if p_source_filter is null
     or p_source_filter not in ('unattempted', 'incorrect', 'bookmarked', 'all') then
    raise exception 'INVALID_SOURCE_FILTER';
  end if;

  if p_feedback_timing is null
     or p_feedback_timing not in ('immediate', 'on_submit') then
    raise exception 'INVALID_FEEDBACK_TIMING';
  end if;

  if p_explanation_level is null
     or p_explanation_level not in ('none', 'answer_only', 'full') then
    raise exception 'INVALID_EXPLANATION_LEVEL';
  end if;

  if p_question_count is null or p_question_count < 1 then
    raise exception 'INVALID_QUESTION_COUNT';
  end if;

  v_plan := public.current_plan(auth.uid());
  select * into v_limits from public.plan_limits where plan = v_plan;
  if not found then
    raise exception 'PLAN_LIMITS_MISSING';
  end if;

  v_effective_count := least(p_question_count, v_limits.max_practice_session_questions);

  v_effective_explanation := case
    when p_explanation_level = 'full' and not v_limits.allow_full_explanation then 'answer_only'
    else p_explanation_level
  end;

  v_topic_ids := case
    when p_topic_ids is null or cardinality(p_topic_ids) = 0 then null
    else p_topic_ids
  end;

  v_lesson_ids := case
    when p_lesson_ids is null or cardinality(p_lesson_ids) = 0 then null
    else p_lesson_ids
  end;

  if v_limits.allow_tag_filter then
    v_tag_ids := case
      when p_tag_ids is null or cardinality(p_tag_ids) = 0 then null
      else p_tag_ids
    end;
  else
    v_tag_ids := null;
  end if;

  if v_limits.allow_difficulty_filter then
    v_difficulties := case
      when p_difficulties is null or cardinality(p_difficulties) = 0 then null
      else p_difficulties
    end;
  else
    v_difficulties := null;
  end if;

  if v_limits.allow_timer_toggle then
    v_timer_minutes := p_timer_minutes;
  else
    v_timer_minutes := coalesce(p_timer_minutes, v_effective_count);
  end if;

  if v_limits.allow_negative_marking_toggle then
    v_negative_marking := coalesce(p_negative_marking, false);
  else
    v_negative_marking := false;
  end if;

  if v_limits.daily_practice_question_quota is not null then
    select coalesce(questions_used, 0) into v_used_today
    from public.daily_practice_usage
    where user_id = auth.uid() and usage_date = current_date;

    if coalesce(v_used_today, 0) + v_effective_count > v_limits.daily_practice_question_quota then
      v_effective_count := greatest(
        v_limits.daily_practice_question_quota - coalesce(v_used_today, 0),
        0
      );
    end if;

    if v_effective_count <= 0 then
      raise exception 'DAILY_PRACTICE_QUOTA_EXCEEDED';
    end if;
  end if;

  insert into public.tests (
    title, test_type, required_plan, total_duration_minutes, total_questions,
    correct_marks, incorrect_marks, unattempted_marks, is_active,
    owner_user_id, is_ephemeral_practice, feedback_timing, show_explanation_level,
    timer_enabled, practice_filter_criteria
  ) values (
    'Practice Session', 'mini', 'free',
    coalesce(v_timer_minutes, 0), v_effective_count,
    case when v_negative_marking then 4 else 1 end,
    case when v_negative_marking then -1 else 0 end,
    0, false,
    auth.uid(), true, p_feedback_timing, v_effective_explanation,
    v_timer_minutes is not null,
    jsonb_build_object(
      'topic_ids', to_jsonb(v_topic_ids),
      'lesson_ids', to_jsonb(v_lesson_ids),
      'tag_ids', to_jsonb(v_tag_ids),
      'difficulties', to_jsonb(v_difficulties),
      'source_filter', p_source_filter,
      'requested_question_count', p_question_count,
      'requested_explanation_level', p_explanation_level,
      'negative_marking', v_negative_marking,
      'timer_minutes', v_timer_minutes
    )
  ) returning id into v_test_id;

  insert into public.test_questions (test_id, question_id, section_number, order_index)
  select v_test_id, q.id, 1, row_number() over (order by random())
  from public.questions q
  where q.is_active
    and q.kind = 'mcq'
    and public.plan_rank(v_plan) >= public.plan_rank(q.required_plan)
    and (v_topic_ids is null or q.topic_id = any(v_topic_ids))
    and (v_lesson_ids is null or q.lesson_id = any(v_lesson_ids))
    and (v_difficulties is null or q.difficulty = any(v_difficulties))
    and (v_tag_ids is null or exists (
          select 1 from public.question_tags qt
          where qt.question_id = q.id and qt.tag_id = any(v_tag_ids)))
    and (
      p_source_filter = 'all'
      or (p_source_filter = 'bookmarked' and exists (
            select 1 from public.bookmarks b
            where b.question_id = q.id and b.user_id = auth.uid()))
      or (p_source_filter = 'incorrect' and exists (
            select 1 from public.attempt_answers aa
            join public.attempts a on a.id = aa.attempt_id
            where a.user_id = auth.uid()
              and aa.question_id = q.id
              and aa.selected_option is distinct from q.correct_option))
      or (p_source_filter = 'unattempted' and not exists (
            select 1 from public.attempt_answers aa
            join public.attempts a on a.id = aa.attempt_id
            where a.user_id = auth.uid()
              and aa.question_id = q.id
              and aa.selected_option is not null))
    )
  order by random()
  limit v_effective_count;

  get diagnostics v_actual_count = row_count;

  if v_actual_count = 0 then
    delete from public.tests where id = v_test_id;
    raise exception 'NO_QUESTIONS_MATCH_FILTERS';
  end if;

  if v_actual_count <> v_effective_count then
    update public.tests
    set total_questions = v_actual_count
    where id = v_test_id;
  end if;

  insert into public.daily_practice_usage (user_id, usage_date, questions_used)
  values (auth.uid(), current_date, v_actual_count)
  on conflict (user_id, usage_date) do update
    set questions_used = public.daily_practice_usage.questions_used + v_actual_count;

  return v_test_id;
end;
$$;

revoke all on function public.create_practice_session(
  uuid[], uuid[], public.question_difficulty[], text, int, text, text, int, boolean, uuid[]
) from public;

grant execute on function public.create_practice_session(
  uuid[], uuid[], public.question_difficulty[], text, int, text, text, int, boolean, uuid[]
) to authenticated, service_role;

grant execute on function public.mark_lesson_learnt(uuid) to authenticated;
grant execute on function public.mark_question_learnt(uuid) to authenticated;
grant execute on function public.record_study_event(public.study_event_kind, uuid, uuid) to authenticated;
grant execute on function public.get_study_progress() to authenticated;
grant execute on function public.tracker_completion(uuid) to authenticated;
grant execute on function public.search_catalog(text) to authenticated;

-- Placeholder university calendar (dates filled when you publish a real window).
insert into public.trackers (university_id, kind, title, is_active)
select u.id, 'university_window', 'KUHS exam window', true
from public.universities u
where u.code = 'KUHS'
  and not exists (
    select 1 from public.trackers t
    where t.kind = 'university_window' and t.university_id = u.id
  );
