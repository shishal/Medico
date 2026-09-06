-- GeckoMed UX: multi-university picker, KUHS fallback bank, MCQ teasers.

alter table public.universities
  add column if not exists is_fallback boolean not null default false;

update public.universities
set is_fallback = true
where code = 'KUHS';

create unique index if not exists universities_one_fallback
  on public.universities (is_fallback)
  where is_fallback;

-- Teasers include theory + MCQ stems. Never expose options or sample answers.
-- CREATE OR REPLACE VIEW cannot insert/rename columns, so drop first.
-- (Postgres would treat `kind` as a rename of `appearance_count`.)
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
  q.kind
from public.questions q
where q.is_active;

comment on view public.pyq_teasers is
  'Theory + MCQ stems + frequency. No sample answers, no MCQ keys.';

grant select on public.pyq_teasers to authenticated, service_role;
