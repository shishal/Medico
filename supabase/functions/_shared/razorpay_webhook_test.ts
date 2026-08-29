import {
  hmacSha256Hex,
  isValidRazorpaySignature,
  parseWebhookEvent,
} from './razorpay_webhook.ts';

const SECRET = 'test_webhook_secret';

const capturedBody = JSON.stringify({
  entity: 'event',
  event: 'payment.captured',
  payload: {
    payment: {
      entity: {
        id: 'pay_test123',
        entity: 'payment',
        amount: 149900,
        currency: 'INR',
        status: 'captured',
        order_id: 'order_test123',
        notes: {
          user_id: '11111111-1111-1111-1111-111111111111',
          plan: 'pro',
          email: 'a@b.c',
        },
      },
    },
  },
});

Deno.test('accepts a matching HMAC-SHA256 signature', async () => {
  const signature = await hmacSha256Hex(SECRET, capturedBody);
  const ok = await isValidRazorpaySignature(capturedBody, signature, SECRET);
  if (!ok) throw new Error('expected valid signature');
});

Deno.test('accepts the same signature in uppercase', async () => {
  const signature = (await hmacSha256Hex(SECRET, capturedBody)).toUpperCase();
  const ok = await isValidRazorpaySignature(capturedBody, signature, SECRET);
  if (!ok) throw new Error('expected uppercase signature to match');
});

Deno.test('rejects a missing signature', async () => {
  const ok = await isValidRazorpaySignature(capturedBody, null, SECRET);
  if (ok) throw new Error('missing signature must fail');
});

Deno.test('rejects a wrong signature', async () => {
  const ok = await isValidRazorpaySignature(
    capturedBody,
    '0'.repeat(64),
    SECRET,
  );
  if (ok) throw new Error('wrong signature must fail');
});

Deno.test('rejects a signature for a different body', async () => {
  const signature = await hmacSha256Hex(SECRET, capturedBody);
  const ok = await isValidRazorpaySignature(
    capturedBody + ' ',
    signature,
    SECRET,
  );
  if (ok) throw new Error('tampered body must fail');
});

Deno.test('parses payment.captured when amount matches the catalog', () => {
  const parsed = parseWebhookEvent(JSON.parse(capturedBody));
  if (parsed.kind !== 'captured') {
    throw new Error(`expected captured, got ${JSON.stringify(parsed)}`);
  }
  if (parsed.payment.plan !== 'pro' || parsed.payment.amountPaise !== 149900) {
    throw new Error('pro catalog fields did not match');
  }
});

Deno.test('ignores order.paid so the same payment is not applied twice', () => {
  const parsed = parseWebhookEvent({ event: 'order.paid' });
  if (parsed.kind !== 'ignored' || parsed.event !== 'order.paid') {
    throw new Error(`expected ignored order.paid, got ${JSON.stringify(parsed)}`);
  }
});

Deno.test('rejects elite notes on a pro-priced payment', () => {
  const body = JSON.parse(capturedBody);
  body.payload.payment.entity.notes.plan = 'elite';
  const parsed = parseWebhookEvent(body);
  if (parsed.kind !== 'invalid') {
    throw new Error('elite notes + pro amount must be invalid');
  }
});

Deno.test('rejects a non-uuid user_id', () => {
  const body = JSON.parse(capturedBody);
  body.payload.payment.entity.notes.user_id = 'not-a-uuid';
  const parsed = parseWebhookEvent(body);
  if (parsed.kind !== 'invalid') {
    throw new Error('non-uuid user_id must be invalid');
  }
});
