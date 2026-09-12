-- PYQs are university-owned. Do not substitute another bank when a
-- university has zero papers. Apply after geckomed_ux.sql.

drop index if exists public.universities_one_fallback;

alter table public.universities
  drop column if exists is_fallback;
