-- Sheet Phases.code is year1–year4 (1st / 2nd / 3rd / final).
-- Rename the Postgres enum labels; mbbs_phases.code values follow automatically.

do $$
begin
  if exists (
    select 1
    from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'mbbs_phase_code'
      and e.enumlabel = 'phase1'
  ) then
    execute 'alter type public.mbbs_phase_code rename value ''phase1'' to ''year1''';
  end if;
  if exists (
    select 1
    from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'mbbs_phase_code'
      and e.enumlabel = 'phase2'
  ) then
    execute 'alter type public.mbbs_phase_code rename value ''phase2'' to ''year2''';
  end if;
  if exists (
    select 1
    from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'mbbs_phase_code'
      and e.enumlabel = 'phase3_part1'
  ) then
    execute 'alter type public.mbbs_phase_code rename value ''phase3_part1'' to ''year3''';
  end if;
  if exists (
    select 1
    from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'public'
      and t.typname = 'mbbs_phase_code'
      and e.enumlabel = 'phase3_part2'
  ) then
    execute 'alter type public.mbbs_phase_code rename value ''phase3_part2'' to ''year4''';
  end if;
end $$;
