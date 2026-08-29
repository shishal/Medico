/// Server-side source of truth for what we charge.
///
/// The checkout page shows the same numbers for display only. The Edge
/// Function never reads amount from the browser — only the plan name.
///
/// Must stay in sync with `checkout/paid_plans.js` (the validator script
/// checks both files).

export type PaidPlanId = 'pro' | 'elite';

export interface PaidPlan {
  amountPaise: number;
  currency: 'INR';
  durationDays: number;
  periodLabel: string;
  label: string;
  description: string;
}

export const PAID_PLANS: Record<PaidPlanId, PaidPlan> = {
  pro: {
    amountPaise: 149900,
    currency: 'INR',
    durationDays: 180,
    periodLabel: '6 months',
    label: 'Pro',
    description: '6 months of Pro',
  },
  elite: {
    amountPaise: 299900,
    currency: 'INR',
    durationDays: 365,
    periodLabel: '12 months',
    label: 'Elite',
    description: '12 months of Elite',
  },
};

export function getPaidPlan(plan: string): PaidPlan | null {
  if (plan === 'pro' || plan === 'elite') {
    return PAID_PLANS[plan];
  }
  return null;
}
