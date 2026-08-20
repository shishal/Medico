-- Phase 1.4 fix: table/function privileges for PostgREST roles.
-- RLS policies alone are not enough — without GRANT, authenticated gets
-- "permission denied" before policies run (caught by validate_phase1_4_rls.py).

grant usage on schema public to anon, authenticated, service_role;

grant select, update on table public.profiles to authenticated;
grant select on table public.subjects to authenticated;
grant select on table public.topics to authenticated;
grant select on table public.questions to authenticated;
grant select on table public.tests to authenticated;
grant select on table public.test_questions to authenticated;
grant select, insert, update on table public.attempts to authenticated;
grant select, insert, update on table public.attempt_answers to authenticated;
grant select, insert, update, delete on table public.bookmarks to authenticated;

-- service_role: full access for seed/sync tooling via the API (bypasses RLS).
grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;

grant execute on function public.plan_rank(public.plan_tier) to authenticated, service_role;
grant execute on function public.current_plan(uuid) to authenticated, service_role;

-- Sequences used by identity columns (if any appear later).
grant usage, select on all sequences in schema public to authenticated, service_role;
