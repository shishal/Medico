-- Phase 6.2: results summary payload (docs/03_BUILD_PLAN.md).
--
-- Overall score/counts come from the submitted attempts row (written by
-- submit_attempt). Subject-wise correct/incorrect/unattempted uses the same
-- classification as scoring so the rows sum to those stored totals.
-- SECURITY DEFINER so a user can still read their own results if their plan
-- later drops below a question's required_plan (questions RLS would hide
-- correct_option from a plain client join).

create or replace function public.get_attempt_results(p_attempt_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_attempt public.attempts%rowtype;
  v_title text;
  v_is_practice boolean;
  v_correct_marks numeric;
  v_incorrect_marks numeric;
  v_unattempted_marks numeric;
  v_duration int;
  v_question_time int;
  v_subjects jsonb;
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
  where id = p_attempt_id;

  if not found then
    raise exception 'ATTEMPT_NOT_FOUND';
  end if;

  if v_attempt.user_id is distinct from auth.uid() then
    raise exception 'ATTEMPT_NOT_OWNED';
  end if;

  if v_attempt.status is distinct from 'submitted' then
    raise exception 'ATTEMPT_NOT_SUBMITTED';
  end if;

  select
    t.title,
    coalesce(t.is_ephemeral_practice, false),
    t.correct_marks,
    t.incorrect_marks,
    t.unattempted_marks
  into
    v_title,
    v_is_practice,
    v_correct_marks,
    v_incorrect_marks,
    v_unattempted_marks
  from public.tests t
  where t.id = v_attempt.test_id;

  v_duration := greatest(
    0,
    extract(
      epoch from (
        coalesce(v_attempt.submitted_at, now()) - v_attempt.started_at
      )
    )::int
  );

  select coalesce(sum(aa.time_spent_seconds), 0)::int
    into v_question_time
  from public.attempt_answers aa
  where aa.attempt_id = p_attempt_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'subject_id', grouped.subject_id,
        'subject_name', grouped.subject_name,
        'correct_count', grouped.correct_count,
        'incorrect_count', grouped.incorrect_count,
        'unattempted_count', grouped.unattempted_count
      )
      order by grouped.display_order, grouped.subject_name
    ),
    '[]'::jsonb
  )
  into v_subjects
  from (
    select
      s.id as subject_id,
      s.name as subject_name,
      s.display_order,
      count(*) filter (
        where aa.selected_option is not null
          and aa.selected_option = q.correct_option
      )::int as correct_count,
      count(*) filter (
        where aa.selected_option is not null
          and aa.selected_option is distinct from q.correct_option
      )::int as incorrect_count,
      count(*) filter (
        where aa.selected_option is null
      )::int as unattempted_count
    from public.test_questions tq
    join public.questions q on q.id = tq.question_id
    join public.topics tp on tp.id = q.topic_id
    join public.subjects s on s.id = tp.subject_id
    left join public.attempt_answers aa
      on aa.attempt_id = p_attempt_id
     and aa.question_id = tq.question_id
    where tq.test_id = v_attempt.test_id
    group by s.id, s.name, s.display_order
  ) grouped;

  return jsonb_build_object(
    'id', v_attempt.id,
    'test_id', v_attempt.test_id,
    'test_title', v_title,
    'status', v_attempt.status,
    'total_score', v_attempt.total_score,
    'correct_count', v_attempt.correct_count,
    'incorrect_count', v_attempt.incorrect_count,
    'unattempted_count', v_attempt.unattempted_count,
    'percentile', v_attempt.percentile,
    'started_at', v_attempt.started_at,
    'submitted_at', v_attempt.submitted_at,
    'duration_seconds', v_duration,
    'question_time_seconds', coalesce(v_question_time, 0),
    'is_ephemeral_practice', coalesce(v_is_practice, false),
    'correct_marks', coalesce(v_correct_marks, 0),
    'incorrect_marks', coalesce(v_incorrect_marks, 0),
    'unattempted_marks', coalesce(v_unattempted_marks, 0),
    'subjects', coalesce(v_subjects, '[]'::jsonb)
  );
end;
$$;

comment on function public.get_attempt_results(uuid) is
  'Submitted attempt summary: stored score/counts/percentile plus subject-wise tallies. Client must not recompute the score.';

revoke all on function public.get_attempt_results(uuid) from public;
grant execute on function public.get_attempt_results(uuid) to authenticated;
