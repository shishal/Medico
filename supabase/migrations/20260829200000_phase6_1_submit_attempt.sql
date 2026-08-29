-- Phase 6.1: server-side submit + scoring (docs/04_TEST_ENGINE_SPEC.md §5).
--
-- The client sends answers only. total_score / counts / percentile are computed
-- here so a modified app cannot write a fake score. calculate_percentile is
-- definer-only (RLS would otherwise count only the caller's own attempts).
--
-- Worked example for manual validation (marking +4 / -1 / 0):
--   2 correct, 1 incorrect, 1 unattempted → total_score = 8 - 1 + 0 = 7.

-- ---------------------------------------------------------------------------
-- Clients must not write scoring columns, and must not change answers after
-- the attempt is submitted. The RPC below is SECURITY DEFINER so it still can.
-- ---------------------------------------------------------------------------

revoke insert on table public.attempts from authenticated;
grant insert (
  user_id,
  test_id,
  status,
  started_at,
  section_started_at
) on table public.attempts to authenticated;

revoke update on table public.attempts from authenticated;
grant update (section_started_at) on table public.attempts to authenticated;

drop policy if exists "own attempts insert" on public.attempts;
create policy "own attempts insert" on public.attempts
  for insert
  with check (
    auth.uid() = user_id
    and status = 'in_progress'
  );

drop policy if exists "own answers insert" on public.attempt_answers;
create policy "own answers insert" on public.attempt_answers
  for insert
  with check (
    exists (
      select 1
      from public.attempts a
      where a.id = attempt_answers.attempt_id
        and a.user_id = auth.uid()
        and a.status = 'in_progress'
    )
  );

drop policy if exists "own answers update" on public.attempt_answers;
create policy "own answers update" on public.attempt_answers
  for update
  using (
    exists (
      select 1
      from public.attempts a
      where a.id = attempt_answers.attempt_id
        and a.user_id = auth.uid()
        and a.status = 'in_progress'
    )
  );

-- ---------------------------------------------------------------------------
-- Percentile (schema doc §6). Not granted to authenticated — only submit_attempt
-- calls it, as table owner, so it can see every submitted row for the test.
-- ---------------------------------------------------------------------------

create or replace function public.calculate_percentile(
  p_test_id uuid,
  p_score numeric
)
returns numeric
language sql
stable
security definer
set search_path = public
as $$
  select round(
    100.0 * (
      select count(*)
      from public.attempts
      where test_id = p_test_id
        and status = 'submitted'
        and total_score <= p_score
    ) / nullif(
      (
        select count(*)
        from public.attempts
        where test_id = p_test_id
          and status = 'submitted'
      ),
      0
    )
  , 1);
$$;

comment on function public.calculate_percentile(uuid, numeric) is
  'Percentile of p_score among submitted attempts for p_test_id. Called only from submit_attempt.';

revoke all on function public.calculate_percentile(uuid, numeric) from public;

-- ---------------------------------------------------------------------------
-- Submit: upsert answers, score from tests marking scheme, store percentile.
-- Idempotent: a retry on an already-submitted attempt returns stored scores
-- and ignores new answers.
-- ---------------------------------------------------------------------------

create or replace function public.submit_attempt(
  p_attempt_id uuid,
  p_answers jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_attempt public.attempts%rowtype;
  v_correct_marks numeric;
  v_incorrect_marks numeric;
  v_unattempted_marks numeric;
  v_correct int;
  v_incorrect int;
  v_unattempted int;
  v_total numeric;
  v_percentile numeric;
begin
  if auth.uid() is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if p_attempt_id is null then
    raise exception 'ATTEMPT_NOT_FOUND';
  end if;

  select *
    into v_attempt
  from public.attempts
  where id = p_attempt_id
  for update;

  if not found then
    raise exception 'ATTEMPT_NOT_FOUND';
  end if;

  if v_attempt.user_id is distinct from auth.uid() then
    raise exception 'ATTEMPT_NOT_OWNED';
  end if;

  -- Retry after a dropped connection: return what was already stored.
  if v_attempt.status = 'submitted' then
    return jsonb_build_object(
      'id', v_attempt.id,
      'test_id', v_attempt.test_id,
      'status', v_attempt.status,
      'total_score', v_attempt.total_score,
      'correct_count', v_attempt.correct_count,
      'incorrect_count', v_attempt.incorrect_count,
      'unattempted_count', v_attempt.unattempted_count,
      'percentile', v_attempt.percentile,
      'submitted_at', v_attempt.submitted_at
    );
  end if;

  if v_attempt.status is distinct from 'in_progress' then
    raise exception 'ATTEMPT_NOT_IN_PROGRESS';
  end if;

  -- Reject 'E' (or any non-A/B/C/D) before char(1) would silently truncate.
  if exists (
    select 1
    from jsonb_array_elements(coalesce(p_answers, '[]'::jsonb)) elem
    where nullif(btrim(elem->>'selected_option'), '') is not null
      and btrim(elem->>'selected_option') not in ('A', 'B', 'C', 'D')
  ) then
    raise exception 'INVALID_SELECTED_OPTION';
  end if;

  insert into public.attempt_answers (
    attempt_id,
    question_id,
    selected_option,
    is_marked_for_review,
    time_spent_seconds,
    answered_at
  )
  select
    p_attempt_id,
    tq.question_id,
    nullif(btrim(elem->>'selected_option'), '')::char(1),
    coalesce((elem->>'is_marked_for_review')::boolean, false),
    greatest(coalesce((elem->>'time_spent_seconds')::int, 0), 0),
    case
      when nullif(btrim(elem->>'selected_option'), '') is not null then now()
      else null
    end
  from jsonb_array_elements(coalesce(p_answers, '[]'::jsonb)) elem
  join public.test_questions tq
    on tq.test_id = v_attempt.test_id
   and tq.question_id = (elem->>'question_id')::uuid
  on conflict (attempt_id, question_id) do update
    set selected_option = excluded.selected_option,
        is_marked_for_review = excluded.is_marked_for_review,
        time_spent_seconds = excluded.time_spent_seconds,
        answered_at = excluded.answered_at;

  select
    t.correct_marks,
    t.incorrect_marks,
    t.unattempted_marks,
    count(*) filter (
      where aa.selected_option is not null
        and aa.selected_option = q.correct_option
    )::int,
    count(*) filter (
      where aa.selected_option is not null
        and aa.selected_option is distinct from q.correct_option
    )::int,
    count(*) filter (
      where aa.selected_option is null
    )::int
  into
    v_correct_marks,
    v_incorrect_marks,
    v_unattempted_marks,
    v_correct,
    v_incorrect,
    v_unattempted
  from public.tests t
  join public.test_questions tq on tq.test_id = t.id
  join public.questions q on q.id = tq.question_id
  left join public.attempt_answers aa
    on aa.attempt_id = p_attempt_id
   and aa.question_id = tq.question_id
  where t.id = v_attempt.test_id
  group by t.correct_marks, t.incorrect_marks, t.unattempted_marks;

  v_correct := coalesce(v_correct, 0);
  v_incorrect := coalesce(v_incorrect, 0);
  v_unattempted := coalesce(v_unattempted, 0);
  v_total :=
    (v_correct * coalesce(v_correct_marks, 0))
    + (v_incorrect * coalesce(v_incorrect_marks, 0))
    + (v_unattempted * coalesce(v_unattempted_marks, 0));

  update public.attempts
     set status = 'submitted',
         submitted_at = now(),
         total_score = v_total,
         correct_count = v_correct,
         incorrect_count = v_incorrect,
         unattempted_count = v_unattempted
   where id = p_attempt_id;

  v_percentile := public.calculate_percentile(v_attempt.test_id, v_total);

  update public.attempts
     set percentile = v_percentile
   where id = p_attempt_id
  returning * into v_attempt;

  return jsonb_build_object(
    'id', v_attempt.id,
    'test_id', v_attempt.test_id,
    'status', v_attempt.status,
    'total_score', v_attempt.total_score,
    'correct_count', v_attempt.correct_count,
    'incorrect_count', v_attempt.incorrect_count,
    'unattempted_count', v_attempt.unattempted_count,
    'percentile', v_attempt.percentile,
    'submitted_at', v_attempt.submitted_at
  );
end;
$$;

comment on function public.submit_attempt(uuid, jsonb) is
  'Writes attempt_answers, scores from tests.correct/incorrect/unattempted_marks, stores percentile. Client must not send a score.';

revoke all on function public.submit_attempt(uuid, jsonb) from public;
grant execute on function public.submit_attempt(uuid, jsonb) to authenticated;
