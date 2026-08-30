# Medico public site (medico.shishal.com)

Static marketing + Play Store legal pages. Served by nginx in Docker on your
machine; Cloudflare sits in front.

Nothing in this folder talks to Supabase or Razorpay yet. Checkout is a
placeholder at `/checkout/` so you can drop the existing `checkout/` app
there later without changing the hostname.

## Pages (paste these into Play Console)

| Play / store field | URL |
|---|---|
| Website | https://medico.shishal.com/ |
| Privacy policy | https://medico.shishal.com/privacy/ |
| Manage / cancel a plan | https://medico.shishal.com/account/ |
| Terms (optional extra) | https://medico.shishal.com/terms/ |
| Support email | support@medico.shishal.com |

`/refunds/` redirects to `/account/`.

Create the mailbox `support@medico.shishal.com` (or a forward to your real
inbox) before you submit a public listing.

## Run locally

From this directory:

```bash
docker compose up --build
```

Open http://127.0.0.1:8080

Without Docker:

```bash
python3 -m http.server 8080 --directory public
```

## Deploy on your machine + Cloudflare

### 1. DNS

In Cloudflare, zone `shishal.com`:

- Add a **CNAME** (or the Tunnel hostname) for `medico` → your tunnel, **or**
- If the box already has a public IP and you terminate TLS at Cloudflare:
  **A/AAAA** for `medico` to that IP, orange-cloud proxied.

SSL/TLS mode:

- Tunnel or origin HTTP on loopback: **Full** is enough.
- Origin with a real certificate: **Full (strict)**.

### 2. Docker on the host

Copy this repo (or at least `website/` + `store/play/` icons) onto the
machine. From `website/`:

```bash
docker compose up --build -d
```

The container listens on **127.0.0.1:8080** only. Do not publish `8080` to
`0.0.0.0` unless you intend the origin to be reachable without Cloudflare.

### 3. Cloudflare Tunnel (recommended)

Zero open inbound ports.

1. Cloudflare Zero Trust → Networks → Tunnels → Create.
2. Public hostname: `medico.shishal.com` → service `http://127.0.0.1:8080`
   (or `http://site:80` if cloudflared is on the same Compose network).
3. Put the tunnel token in `website/.env` (gitignored at repo root as `.env`):

   ```
   CLOUDFLARE_TUNNEL_TOKEN=eyJ...
   ```

4. Start the tunnel sidecar:

   ```bash
   docker compose --profile tunnel up -d
   ```

If you already run `cloudflared` as a host service, skip the Compose profile
and point that tunnel at `http://127.0.0.1:8080`.

### 4. Check

- https://medico.shishal.com/healthz → `ok`
- https://medico.shishal.com/privacy/ loads without a login
- View source is HTML files, not a Flutter web build

## Payments later

Keep this hostname. Replace `public/checkout/` with the files from repo
`checkout/` (except `serve.py` and `config.example.js`), add a host-only
`config.js` as in `docs/06_PAYMENTS_PRODUCTION.md`, and expand the CSP in
`nginx.conf` so Razorpay + Supabase scripts can load.

Then set Flutter `CHECKOUT_URL=https://medico.shishal.com/checkout`.
