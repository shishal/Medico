# Phase 7.2 — External web checkout

A small static site (not part of the Flutter app) where a student signs in
with their Medico email and pays through **Razorpay Checkout**. The app
only opens this page in the system browser.

Payment success makes Razorpay POST to the `razorpay-webhook` Edge Function.
Phase 7.3 is what verifies that webhook and updates `profiles.plan`.

## What lives where

| Piece | Role |
|---|---|
| This folder | HTML/JS page: email login, plan pick, Razorpay modal |
| `supabase/functions/create-razorpay-order` | Creates the Razorpay **Order** (amount is chosen here, not in the browser) |
| `supabase/functions/razorpay-webhook` | 7.2 stub: accepts the webhook so a test payment can fire one. **Does not change the plan.** |

## One-time setup

1. Create a [Razorpay](https://dashboard.razorpay.com/) account and switch the
   Dashboard to **Test Mode**.
2. **Account & Settings → API Keys** → generate Test keys (`rzp_test_…`).
3. Put them in the repo `.env` (never commit that file):

   ```
   RAZORPAY_KEY_ID=rzp_test_...
   RAZORPAY_KEY_SECRET=...
   CHECKOUT_URL=http://127.0.0.1:4173
   ```

   On an Android emulator, use `http://10.0.2.2:4173` so the device reaches
   your laptop.

4. Push the secrets to Supabase (hosted project the Flutter app already uses):

   ```bash
   supabase secrets set RAZORPAY_KEY_ID="$RAZORPAY_KEY_ID" RAZORPAY_KEY_SECRET="$RAZORPAY_KEY_SECRET"
   supabase functions deploy create-razorpay-order
   supabase functions deploy razorpay-webhook
   ```

   `razorpay-webhook` must stay `verify_jwt = false` — Razorpay does not send
   a Supabase JWT. Phase 7.3 will check Razorpay's own signature instead.

5. In Razorpay Dashboard → **Account & Settings → Webhooks** (Test Mode),
   add:

   `https://<PROJECT_REF>.supabase.co/functions/v1/razorpay-webhook`

   Subscribe to `payment.captured` and `order.paid`. Set any webhook secret;
   7.2 ignores it, 7.3 will verify it.

## Run the page locally

```bash
python3 checkout/serve.py
```

Open http://127.0.0.1:4173 (optional `?plan=elite&email=you@example.com`).

Sign in with a real Medico test account, pick Pro or Elite, pay.

## Test payment (no real money)

1. Choose **Card**.
2. Number `4111 1111 1111 1111` (Visa) or `5267 3181 8797 5449` (Mastercard).
3. Any future expiry, any CVV.
4. On the mock bank page, click **Success**.

Then in Razorpay Dashboard → **Transactions → Payments**, the payment should
be **Captured**. Under Webhooks, the delivery to `razorpay-webhook` should
show as sent (the stub returns 200 and logs the event; it does **not**
upgrade the user yet).

## Prices

| Plan | Amount | Access window (applied in 7.3) |
|---|---|---|
| Pro | ₹1,499 | 180 days |
| Elite | ₹2,999 | 365 days |

Change both `checkout/paid_plans.js` and
`supabase/functions/_shared/paid_plans.ts`, then run
`python3 scripts/validate_phase7_2_paid_plans.py`.
