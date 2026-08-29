// Creates a Razorpay Order for the signed-in user.
// Amount comes from paid_plans.ts — never from the request body.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { getPaidPlan } from '../_shared/paid_plans.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonResponse({ error: 'Sign in to continue.' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
  if (!supabaseUrl || !supabaseAnonKey) {
    return jsonResponse({ error: 'Server is missing Supabase config.' }, 500);
  }

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user },
    error: userError,
  } = await supabase.auth.getUser();

  if (userError || user == null || user.email == null) {
    return jsonResponse({ error: 'Sign in to continue.' }, 401);
  }

  let planName = '';
  try {
    const body = await req.json();
    planName = typeof body?.plan === 'string' ? body.plan.trim().toLowerCase() : '';
  } catch {
    return jsonResponse({ error: 'Send JSON with a plan field.' }, 400);
  }

  const plan = getPaidPlan(planName);
  if (plan == null) {
    return jsonResponse({ error: 'Choose Pro or Elite.' }, 400);
  }

  const keyId = Deno.env.get('RAZORPAY_KEY_ID');
  const keySecret = Deno.env.get('RAZORPAY_KEY_SECRET');
  if (!keyId || !keySecret) {
    return jsonResponse(
      { error: 'Checkout is not configured yet. Try again later.' },
      500,
    );
  }

  // receipt max 40 chars. Date.now() in base36 stays well under that.
  const receipt = `m_${planName}_${Date.now().toString(36)}`;

  const razorpayResponse = await fetch('https://api.razorpay.com/v1/orders', {
    method: 'POST',
    headers: {
      Authorization: `Basic ${btoa(`${keyId}:${keySecret}`)}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      amount: plan.amountPaise,
      currency: plan.currency,
      receipt,
      notes: {
        user_id: user.id,
        plan: planName,
        email: user.email,
      },
    }),
  });

  const razorpayBody = await razorpayResponse.json();
  if (!razorpayResponse.ok) {
    console.error('Razorpay Orders API error', razorpayBody);
    return jsonResponse(
      { error: 'Could not start checkout. Please try again.' },
      502,
    );
  }

  return jsonResponse({
    keyId,
    orderId: razorpayBody.id,
    amount: plan.amountPaise,
    currency: plan.currency,
    plan: planName,
    label: plan.label,
    description: plan.description,
    name: 'Medico',
    prefillEmail: user.email,
  });
});
