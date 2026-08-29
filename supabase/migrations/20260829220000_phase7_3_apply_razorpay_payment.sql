-- Phase 7.3: Razorpay payment → profiles.plan (docs/03_BUILD_PLAN.md).
--
-- The Edge Function verifies Razorpay's webhook signature, then calls this
-- RPC. Amount and duration are enforced here so a forged or replayed payload
-- cannot grant a plan the catalog does not sell. Authenticated clients cannot
-- execute this function, and cannot UPDATE profiles.plan themselves.

-- ---------------------------------------------------------------------------
-- Students may edit name/phone. Plan columns are webhook/RPC only.
-- ---------------------------------------------------------------------------

revoke update on table public.profiles from authenticated;
grant update (full_name, phone) on table public.profiles to authenticated;

-- ---------------------------------------------------------------------------
-- Audit + idempotency. Unique payment id means Razorpay retries do not stack
-- extra days. No SELECT grant for authenticated — receipts stay server-side.
-- ---------------------------------------------------------------------------

create table if not exists public.payments (
  razorpay_payment_id text primary key,
  razorpay_order_id text not null,
  user_id uuid not null references auth.users (id) on delete cascade,
  plan public.plan_tier not null,
  amount_paise integer not null,
  currency text not null,
  applied_at timestamptz not null default now(),
  constraint payments_plan_paid check (plan in ('pro', 'elite')),
  constraint payments_currency_inr check (currency = 'INR')
);

create index if not exists idx_payments_user on public.payments (user_id);

alter table public.payments enable row level security;

grant all on table public.payments to service_role;

-- ---------------------------------------------------------------------------
-- Apply a captured Razorpay payment. Catalog must match
-- supabase/functions/_shared/paid_plans.ts (scripts/validate_phase7_3_webhook.py).
-- ---------------------------------------------------------------------------

create or replace function public.apply_razorpay_payment(
  p_payment_id text,
  p_order_id text,
  p_user_id uuid,
  p_plan public.plan_tier,
  p_amount_paise integer,
  p_currency text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_amount_paise integer;
  v_duration_days integer;
  v_inserted text;
  v_expires_at timestamptz;
  v_plan public.plan_tier;
begin
  if p_payment_id is null or length(trim(p_payment_id)) = 0 then
    raise exception 'payment id required';
  end if;
  if p_order_id is null or length(trim(p_order_id)) = 0 then
    raise exception 'order id required';
  end if;
  if p_user_id is null then
    raise exception 'user id required';
  end if;

  -- Must stay in sync with PAID_PLANS in paid_plans.ts.
  if p_plan = 'pro' then
    v_amount_paise := 149900;
    v_duration_days := 180;
  elsif p_plan = 'elite' then
    v_amount_paise := 299900;
    v_duration_days := 365;
  else
    raise exception 'unsupported plan';
  end if;

  if p_amount_paise is distinct from v_amount_paise then
    raise exception 'amount does not match catalog';
  end if;
  if p_currency is distinct from 'INR' then
    raise exception 'currency does not match catalog';
  end if;

  insert into public.payments (
    razorpay_payment_id,
    razorpay_order_id,
    user_id,
    plan,
    amount_paise,
    currency
  ) values (
    p_payment_id,
    p_order_id,
    p_user_id,
    p_plan,
    p_amount_paise,
    p_currency
  )
  on conflict (razorpay_payment_id) do nothing
  returning razorpay_payment_id into v_inserted;

  if v_inserted is null then
    select pr.plan, pr.plan_expires_at
      into v_plan, v_expires_at
    from public.payments pay
    join public.profiles pr on pr.id = pay.user_id
    where pay.razorpay_payment_id = p_payment_id;

    return jsonb_build_object(
      'applied', false,
      'duplicate', true,
      'plan', v_plan,
      'plan_expires_at', v_expires_at
    );
  end if;

  update public.profiles
  set
    plan = p_plan,
    plan_started_at = now(),
    plan_expires_at = now() + (v_duration_days * interval '1 day')
  where id = p_user_id
  returning plan, plan_expires_at into v_plan, v_expires_at;

  if v_plan is null then
    raise exception 'profile not found';
  end if;

  return jsonb_build_object(
    'applied', true,
    'duplicate', false,
    'plan', v_plan,
    'plan_expires_at', v_expires_at
  );
end;
$$;

comment on function public.apply_razorpay_payment(text, text, uuid, public.plan_tier, integer, text) is
  'Idempotent plan grant after a verified Razorpay payment.captured webhook. Not for clients.';

revoke all on function public.apply_razorpay_payment(text, text, uuid, public.plan_tier, integer, text) from public;
revoke all on function public.apply_razorpay_payment(text, text, uuid, public.plan_tier, integer, text) from anon, authenticated;
grant execute on function public.apply_razorpay_payment(text, text, uuid, public.plan_tier, integer, text) to service_role;
