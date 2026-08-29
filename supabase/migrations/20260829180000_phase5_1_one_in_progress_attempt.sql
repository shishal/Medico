-- Phase 5.1: at most one in-progress attempt per (user, test).
--
-- Submitted / abandoned rows are excluded so a later retake can insert a
-- new in_progress row. The Flutter client still queries-then-inserts;
-- this index is the server-side guarantee against a race.

create unique index if not exists idx_attempts_one_in_progress
  on public.attempts (user_id, test_id)
  where status = 'in_progress';
