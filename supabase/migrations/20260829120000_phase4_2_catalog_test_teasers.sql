-- Phase 4.2: Locked-content teasers for free/pro users.
--
-- Product need: users should *see that* higher-plan tests exist (title +
-- metadata) without being able to open questions. Loosening SELECT on
-- `tests` would expose marks scheme / description / etc. and must not
-- unlock `test_questions` — so we use a narrow view of safe columns only.
--
-- security_invoker = false: the view runs as its owner (migration role),
-- bypassing plan-gated RLS on `tests`. Only the columns below are exposed.
-- `test_questions` / `questions` policies are unchanged and stay gated.

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
where is_active;

comment on view public.catalog_test_teasers is
  'Non-sensitive catalog test metadata visible to all authenticated users (Phase 4.2 teasers). Does not include questions or marking scheme.';

grant select on public.catalog_test_teasers to authenticated;
grant select on public.catalog_test_teasers to service_role;
