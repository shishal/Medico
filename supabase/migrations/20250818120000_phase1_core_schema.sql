-- Phase 1.1: Core schema (docs/02_DATABASE_SCHEMA.md sections 1–5)

-- ---------------------------------------------------------------------------
-- 1. Enums
-- ---------------------------------------------------------------------------

create type plan_tier as enum ('free', 'pro', 'elite');
create type test_type as enum ('mini', 'subject', 'mock', 'grand');
create type attempt_status as enum ('in_progress', 'submitted', 'abandoned');
create type question_difficulty as enum ('easy', 'medium', 'hard');

-- ---------------------------------------------------------------------------
-- 2. Core tables
-- ---------------------------------------------------------------------------

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  plan plan_tier not null default 'free',
  plan_started_at timestamptz,
  plan_expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  display_order int not null default 0
);

create table topics (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid not null references subjects(id) on delete cascade,
  name text not null,
  display_order int not null default 0
);
create index idx_topics_subject on topics(subject_id);

create table questions (
  id uuid primary key default gen_random_uuid(),
  topic_id uuid not null references topics(id) on delete restrict,
  question_text text not null,
  option_a text not null,
  option_b text not null,
  option_c text not null,
  option_d text not null,
  correct_option char(1) not null check (correct_option in ('A','B','C','D')),
  explanation_text text,
  explanation_video_url text,
  image_url text,
  difficulty question_difficulty not null default 'medium',
  source text,
  required_plan plan_tier not null default 'free',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
create index idx_questions_topic on questions(topic_id);
create index idx_questions_active on questions(is_active) where is_active;

create table tests (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  test_type test_type not null,
  subject_id uuid references subjects(id),
  required_plan plan_tier not null default 'free',
  is_sectional boolean not null default false,
  section_count int not null default 1,
  questions_per_section int,
  section_duration_minutes int,
  total_duration_minutes int not null,
  total_questions int not null,
  correct_marks numeric not null default 4,
  incorrect_marks numeric not null default -1,
  unattempted_marks numeric not null default 0,
  is_live boolean not null default false,
  live_start_at timestamptz,
  live_end_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table test_questions (
  test_id uuid not null references tests(id) on delete cascade,
  question_id uuid not null references questions(id) on delete restrict,
  section_number int not null default 1,
  order_index int not null,
  primary key (test_id, question_id)
);
create index idx_test_questions_test on test_questions(test_id);

create table attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  test_id uuid not null references tests(id) on delete restrict,
  status attempt_status not null default 'in_progress',
  started_at timestamptz not null default now(),
  submitted_at timestamptz,
  total_score numeric,
  correct_count int,
  incorrect_count int,
  unattempted_count int,
  percentile numeric,
  created_at timestamptz not null default now()
);
create index idx_attempts_user on attempts(user_id);
create index idx_attempts_test on attempts(test_id);

create table attempt_answers (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references attempts(id) on delete cascade,
  question_id uuid not null references questions(id) on delete restrict,
  selected_option char(1) check (selected_option in ('A','B','C','D')),
  is_marked_for_review boolean not null default false,
  time_spent_seconds int not null default 0,
  answered_at timestamptz,
  unique (attempt_id, question_id)
);
create index idx_attempt_answers_attempt on attempt_answers(attempt_id);

create table bookmarks (
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references questions(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, question_id)
);

-- ---------------------------------------------------------------------------
-- 3. New-user trigger (auto-create a profile row on signup)
-- ---------------------------------------------------------------------------

create function handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, plan)
  values (new.id, 'free');
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- ---------------------------------------------------------------------------
-- 4. Plan-comparison helper (used by RLS)
-- ---------------------------------------------------------------------------

create function plan_rank(p plan_tier) returns int
language sql immutable as $$
  select case p when 'free' then 0 when 'pro' then 1 when 'elite' then 2 end;
$$;

create function current_plan(p_user_id uuid) returns plan_tier
language sql stable as $$
  select case
    when plan_expires_at is not null and plan_expires_at < now() then 'free'::plan_tier
    else plan
  end
  from profiles where id = p_user_id;
$$;

-- ---------------------------------------------------------------------------
-- 5. Row-Level Security
-- ---------------------------------------------------------------------------

alter table profiles enable row level security;
alter table subjects enable row level security;
alter table topics enable row level security;
alter table questions enable row level security;
alter table tests enable row level security;
alter table test_questions enable row level security;
alter table attempts enable row level security;
alter table attempt_answers enable row level security;
alter table bookmarks enable row level security;

create policy "own profile select" on profiles for select using (auth.uid() = id);
create policy "own profile update" on profiles for update using (auth.uid() = id);

create policy "subjects readable" on subjects for select using (auth.role() = 'authenticated');
create policy "topics readable" on topics for select using (auth.role() = 'authenticated');

create policy "questions plan-gated select" on questions for select using (
  is_active
  and plan_rank(current_plan(auth.uid())) >= plan_rank(required_plan)
);

create policy "tests plan-gated select" on tests for select using (
  is_active
  and plan_rank(current_plan(auth.uid())) >= plan_rank(required_plan)
);

create policy "test_questions via test" on test_questions for select using (
  exists (
    select 1 from tests t
    where t.id = test_questions.test_id
    and t.is_active
    and plan_rank(current_plan(auth.uid())) >= plan_rank(t.required_plan)
  )
);

create policy "own attempts select" on attempts for select using (auth.uid() = user_id);
create policy "own attempts insert" on attempts for insert with check (auth.uid() = user_id);
create policy "own attempts update" on attempts for update using (auth.uid() = user_id);

create policy "own answers select" on attempt_answers for select using (
  exists (select 1 from attempts a where a.id = attempt_answers.attempt_id and a.user_id = auth.uid())
);
create policy "own answers insert" on attempt_answers for insert with check (
  exists (select 1 from attempts a where a.id = attempt_answers.attempt_id and a.user_id = auth.uid())
);
create policy "own answers update" on attempt_answers for update using (
  exists (select 1 from attempts a where a.id = attempt_answers.attempt_id and a.user_id = auth.uid())
);

create policy "own bookmarks all" on bookmarks for all using (auth.uid() = user_id);
