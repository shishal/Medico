-- Single-device login (new login kicks the old) + lifetime 3rd-device plan
-- suspension. Enforcement is server-side via claim_active_device /
-- assert_active_device and current_plan(); students cannot write these columns.

-- ---------------------------------------------------------------------------
-- profiles: active device + suspension
-- ---------------------------------------------------------------------------

alter table public.profiles
  add column if not exists active_device_id text,
  add column if not exists active_device_claimed_at timestamptz,
  add column if not exists plan_suspended_at timestamptz,
  add column if not exists plan_suspend_reason text;

comment on column public.profiles.active_device_id is
  'Install id of the device that last successfully claimed this account.';
comment on column public.profiles.plan_suspended_at is
  'When set, current_plan() returns free until support clears it.';

-- Column grants stay academic-only; device/suspend fields are RPC-only.
revoke update on table public.profiles from authenticated;
grant update (
  full_name,
  phone,
  university_id,
  college_id,
  batch_year,
  mbbs_phase_id,
  onboarding_completed_at
) on table public.profiles to authenticated;

-- ---------------------------------------------------------------------------
-- device_claims: lifetime unique installs per user
-- ---------------------------------------------------------------------------

create table if not exists public.device_claims (
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id text not null,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  primary key (user_id, device_id),
  constraint device_claims_device_id_len check (
    char_length(device_id) between 1 and 128
  )
);

create index if not exists idx_device_claims_user
  on public.device_claims (user_id);

alter table public.device_claims enable row level security;

-- No policies for authenticated: only SECURITY DEFINER RPCs touch this table.
-- service_role bypasses RLS for support SQL.

revoke all on table public.device_claims from public, anon, authenticated;
grant select on table public.device_claims to service_role;

-- ---------------------------------------------------------------------------
-- current_plan: free when expired OR suspended
-- ---------------------------------------------------------------------------

create or replace function public.current_plan(p_user_id uuid)
returns public.plan_tier
language sql
stable
set search_path = public
as $$
  select case
    when plan_suspended_at is not null then 'free'::public.plan_tier
    when plan_expires_at is not null and plan_expires_at < now()
      then 'free'::public.plan_tier
    else plan
  end
  from public.profiles
  where id = p_user_id;
$$;

comment on function public.current_plan(uuid) is
  'Effective plan: free if suspended or plan_expires_at is past; else profiles.plan.';

-- ---------------------------------------------------------------------------
-- claim_active_device: register install, maybe suspend, kick other sessions
-- ---------------------------------------------------------------------------

create or replace function public.claim_active_device(p_device_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_device text := nullif(btrim(p_device_id), '');
  v_was_known boolean;
  v_distinct int;
  v_suspended boolean;
  v_was_suspended boolean;
  v_just_suspended boolean := false;
  v_session_id uuid;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED';
  end if;

  if v_device is null or char_length(v_device) > 128 then
    raise exception 'INVALID_DEVICE_ID';
  end if;

  select plan_suspended_at is not null
  into v_was_suspended
  from public.profiles
  where id = v_uid;

  select exists (
    select 1
    from public.device_claims
    where user_id = v_uid
      and device_id = v_device
  )
  into v_was_known;

  if v_was_known then
    update public.device_claims
    set last_seen_at = now()
    where user_id = v_uid
      and device_id = v_device;
  else
    insert into public.device_claims (user_id, device_id, first_seen_at, last_seen_at)
    values (v_uid, v_device, now(), now());
  end if;

  select count(*)::int
  into v_distinct
  from public.device_claims
  where user_id = v_uid;

  -- Lifetime cap: 3rd unique install suspends paid access (leaves plan columns).
  if not v_was_known and v_distinct > 2 then
    update public.profiles
    set
      plan_suspended_at = coalesce(plan_suspended_at, now()),
      plan_suspend_reason = coalesce(plan_suspend_reason, 'multi_device'),
      active_device_id = v_device,
      active_device_claimed_at = now()
    where id = v_uid;

    v_just_suspended := not coalesce(v_was_suspended, false);
  else
    update public.profiles
    set
      active_device_id = v_device,
      active_device_claimed_at = now()
    where id = v_uid;
  end if;

  select plan_suspended_at is not null
  into v_suspended
  from public.profiles
  where id = v_uid;

  -- Revoke other Auth sessions so the previous phone cannot refresh.
  begin
    v_session_id := nullif(auth.jwt() ->> 'session_id', '')::uuid;
  exception
    when others then
      v_session_id := null;
  end;

  if v_session_id is not null then
    delete from auth.sessions
    where user_id = v_uid
      and id is distinct from v_session_id;
  end if;

  return jsonb_build_object(
    'ok', true,
    'suspended', coalesce(v_suspended, false),
    'just_suspended', v_just_suspended,
    'distinct_device_count', v_distinct
  );
end;
$$;

comment on function public.claim_active_device(text) is
  'Binds this install as the sole active device; suspends plan on 3rd unique device.';

revoke all on function public.claim_active_device(text) from public;
grant execute on function public.claim_active_device(text) to authenticated;

-- ---------------------------------------------------------------------------
-- assert_active_device: true only if this install still owns the account
-- ---------------------------------------------------------------------------

create or replace function public.assert_active_device(p_device_id text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_device text := nullif(btrim(p_device_id), '');
  v_active text;
begin
  if v_uid is null then
    return false;
  end if;

  if v_device is null or char_length(v_device) > 128 then
    return false;
  end if;

  select active_device_id
  into v_active
  from public.profiles
  where id = v_uid;

  -- No claim yet (legacy session before first claim): allow until claim runs.
  if v_active is null then
    return true;
  end if;

  return v_active = v_device;
end;
$$;

comment on function public.assert_active_device(text) is
  'Returns true if profiles.active_device_id matches this install (or is unset).';

revoke all on function public.assert_active_device(text) from public;
grant execute on function public.assert_active_device(text) to authenticated;
