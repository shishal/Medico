-- Include difficulty so PYQ teasers/reader can show Must / Should / Could
-- without an extra questions round-trip. Enum values stay easy/medium/hard.

drop view if exists public.pyq_teasers;

create view public.pyq_teasers
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
  ) as appearance_count,
  q.kind,
  q.difficulty
from public.questions q
where q.is_active;

comment on view public.pyq_teasers is
  'Theory + MCQ stems + frequency + difficulty. No sample answers, no MCQ keys.';

grant select on public.pyq_teasers to authenticated, service_role;
