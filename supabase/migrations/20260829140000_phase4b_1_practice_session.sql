-- Phase 4B.1: Practice session generator (docs/02_DATABASE_SCHEMA.md §7).
--
-- Adds tags, plan_limits, daily_practice_usage; extends tests for ephemeral
-- practice sessions; updates tests/test_questions RLS so owners can read their
-- own practice rows; creates create_practice_session() (security definer).
--
-- Also replaces tests_title_key with a partial unique index on catalog titles
-- only — practice sessions all use title 'Practice Session' and must not collide
-- (flagged in Phase 2.2 / schema §2).

-- ---------------------------------------------------------------------------
-- 7.1 Tags
-- ---------------------------------------------------------------------------

create table public.tags (
  id uuid primary key default gen_random_uuid(),
  name text not null unique
);

create table public.question_tags (
  question_id uuid not null references public.questions(id) on delete cascade,
  tag_id uuid not null references public.tags(id) on delete cascade,
  primary key (question_id, tag_id)
);
create index idx_question_tags_tag on public.question_tags(tag_id);

-- ---------------------------------------------------------------------------
-- 7.2 Plan limits (data-driven, not hardcoded)
-- ---------------------------------------------------------------------------

create table public.plan_limits (
  plan public.plan_tier primary key,
  max_practice_session_questions int not null,
  daily_practice_question_quota int,              -- null = unlimited
  allow_full_explanation boolean not null default true,
  allow_timer_toggle boolean not null default true,
  allow_tag_filter boolean not null default true,
  allow_difficulty_filter boolean not null default true,
  allow_negative_marking_toggle boolean not null default true
);

insert into public.plan_limits (
  plan,
  max_practice_session_questions,
  daily_practice_question_quota,
  allow_full_explanation,
  allow_timer_toggle,
  allow_tag_filter,
  allow_difficulty_filter,
  allow_negative_marking_toggle
) values
  ('free',  10,  20,   false, false, false, true,  false),
  ('pro',   50,  null, true,  true,  true,  true,  true),
  ('elite', 100, null, true,  true,  true,  true,  true);

-- ---------------------------------------------------------------------------
-- 7.3 Daily usage tracking
-- ---------------------------------------------------------------------------

create table public.daily_practice_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_date date not null default current_date,
  questions_used int not null default 0,
  primary key (user_id, usage_date)
);

-- ---------------------------------------------------------------------------
-- 7.4 Extend tests for ephemeral practice sessions
-- ---------------------------------------------------------------------------

alter table public.tests
  add column owner_user_id uuid references auth.users(id),
  add column is_ephemeral_practice boolean not null default false,
  add column feedback_timing text not null default 'on_submit'
    check (feedback_timing in ('immediate', 'on_submit')),
  add column show_explanation_level text not null default 'full'
    check (show_explanation_level in ('none', 'answer_only', 'full')),
  add column timer_enabled boolean not null default true,
  add column practice_filter_criteria jsonb;

-- Catalog titles stay unique for sheet upserts; practice rows may share a title.
alter table public.tests drop constraint if exists tests_title_key;
create unique index tests_catalog_title_key
  on public.tests (title)
  where owner_user_id is null;

-- Teasers stay catalog-only (never list someone's private practice session).
create or replace view public.catalog_test_teasers
with (security_invoker = false) as
select
  id,
  title,
  test_type,
  required_plan,
  total_questions,
  total_duration_minutes,
  is_sectional,
  is_active,
  created_at
from public.tests
where is_active
  and not is_ephemeral_practice;

comment on view public.catalog_test_teasers is
  'Non-sensitive catalog test metadata visible to all authenticated users (Phase 4.2 teasers). Does not include questions or marking scheme.';

grant select on public.catalog_test_teasers to authenticated;
grant select on public.catalog_test_teasers to service_role;

-- ---------------------------------------------------------------------------
-- 7.5 RLS updates (owner can see own practice session)
-- ---------------------------------------------------------------------------

drop policy if exists "tests plan-gated select" on public.tests;
create policy "tests select" on public.tests for select using (
  (is_active and public.plan_rank(public.current_plan(auth.uid())) >= public.plan_rank(required_plan))
  or owner_user_id = auth.uid()
);

drop policy if exists "test_questions via test" on public.test_questions;
create policy "test_questions select" on public.test_questions for select using (
  exists (
    select 1 from public.tests t
    where t.id = test_questions.test_id
    and (
      (t.is_active and public.plan_rank(public.current_plan(auth.uid())) >= public.plan_rank(t.required_plan))
      or t.owner_user_id = auth.uid()
    )
  )
);

-- New tables: readable by clients where needed; writes only via RPC / service_role.
alter table public.tags enable row level security;
alter table public.question_tags enable row level security;
alter table public.plan_limits enable row level security;
alter table public.daily_practice_usage enable row level security;

create policy "tags readable" on public.tags
  for select using (auth.role() = 'authenticated');

create policy "question_tags readable" on public.question_tags
  for select using (auth.role() = 'authenticated');

create policy "plan_limits readable" on public.plan_limits
  for select using (auth.role() = 'authenticated');

create policy "own daily_practice_usage select" on public.daily_practice_usage
  for select using (auth.uid() = user_id);

grant select on table public.tags to authenticated;
grant select on table public.question_tags to authenticated;
grant select on table public.plan_limits to authenticated;
grant select on table public.daily_practice_usage to authenticated;

grant all on table public.tags to service_role;
grant all on table public.question_tags to service_role;
grant all on table public.plan_limits to service_role;
grant all on table public.daily_practice_usage to service_role;

-- ---------------------------------------------------------------------------
-- 7.6 Practice session generator
-- ---------------------------------------------------------------------------
-- security definer: must re-check plan_rank on questions (bypasses RLS).
-- Clamps session size + explanation level from plan_limits; also ignores
-- filters the plan doesn't allow so a modified client can't bypass UI gates.

create or replace function public.create_practice_session(
  p_topic_ids uuid[],
  p_tag_ids uuid[],
  p_difficulties public.question_difficulty[],
  p_source_filter text,        -- 'unattempted' | 'incorrect' | 'bookmarked' | 'all'
  p_question_count int,
  p_feedback_timing text,      -- 'immediate' | 'on_submit'
  p_explanation_level text,    -- 'none' | 'answer_only' | 'full'
  p_timer_minutes int,         -- null if the student turned the timer off
  p_negative_marking boolean
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

  -- Empty arrays mean "no filter" (same as null) — `= any('{}')` matches nothing.
  v_topic_ids := case
    when p_topic_ids is null or cardinality(p_topic_ids) = 0 then null
    else p_topic_ids
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

  -- Free plan: timer forced on, negative marking forced off (spec §1 / plan_limits).
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
    -- security definer bypasses RLS — re-check plan gating here
    and public.plan_rank(v_plan) >= public.plan_rank(q.required_plan)
    and (v_topic_ids is null or q.topic_id = any(v_topic_ids))
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

  -- Align stored count + daily quota with what was actually attached.
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
  uuid[],
  uuid[],
  public.question_difficulty[],
  text,
  int,
  text,
  text,
  int,
  boolean
) from public;

grant execute on function public.create_practice_session(
  uuid[],
  uuid[],
  public.question_difficulty[],
  text,
  int,
  text,
  text,
  int,
  boolean
) to authenticated;

grant execute on function public.create_practice_session(
  uuid[],
  uuid[],
  public.question_difficulty[],
  text,
  int,
  text,
  text,
  int,
  boolean
) to service_role;

comment on function public.create_practice_session is
  'Creates an ephemeral practice tests row for the caller, clamped to plan_limits.';
