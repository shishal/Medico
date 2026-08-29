// Phase 7.2 stub: acknowledge Razorpay events so a test payment can
// "trigger a webhook". Phase 7.3 replaces this with signature verification
// and the profiles.plan update. Do not grant plans from this file.

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const raw = await req.text();
  let event = 'unknown';
  try {
    const parsed = JSON.parse(raw) as { event?: string };
    if (typeof parsed.event === 'string') {
      event = parsed.event;
    }
  } catch {
    // Razorpay sends JSON; if it isn't, still 200 so test deliveries show
    // as received. 7.3 will reject unsigned / malformed bodies.
  }

  console.log(`razorpay-webhook stub received event=${event}`);

  return new Response(JSON.stringify({ received: true, event }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
