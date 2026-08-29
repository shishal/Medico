#!/usr/bin/env python3
"""Serve the checkout page and inject Supabase public config from the repo .env.

The Razorpay *secret* never goes in this page — only the Flutter-safe
SUPABASE_URL + SUPABASE_ANON_KEY, same as the mobile app.
"""

from __future__ import annotations

import json
import os
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CHECKOUT_DIR = Path(__file__).resolve().parent
ENV_PATH = ROOT / ".env"
PORT = int(os.environ.get("CHECKOUT_PORT", "4173"))


def load_env() -> dict[str, str]:
    values: dict[str, str] = {}
    if not ENV_PATH.exists():
        sys.exit(f"Missing {ENV_PATH}. Copy .env.example to .env first.")
    for line in ENV_PATH.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        values.setdefault(key.strip(), value.strip().strip('"').strip("'"))
    return values


def config_js(env: dict[str, str]) -> bytes:
    url = env.get("SUPABASE_URL", "")
    anon = env.get("SUPABASE_ANON_KEY", "")
    if not url or "YOUR_PROJECT" in url or not anon or anon == "your_anon_key":
        sys.exit("SUPABASE_URL / SUPABASE_ANON_KEY in .env are still placeholders.")
    payload = {"supabaseUrl": url, "supabaseAnonKey": anon}
    body = "window.CHECKOUT_CONFIG = " + json.dumps(payload) + ";\n"
    return body.encode("utf-8")


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, config: bytes, **kwargs):
        self._config = config
        super().__init__(*args, directory=str(CHECKOUT_DIR), **kwargs)

    def do_GET(self) -> None:
        if self.path.split("?", 1)[0] == "/config.js":
            self.send_response(200)
            self.send_header("Content-Type", "application/javascript; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(self._config)))
            self.end_headers()
            self.wfile.write(self._config)
            return
        super().do_GET()

    def log_message(self, format: str, *args) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), format % args))


def main() -> int:
    env = load_env()
    config = config_js(env)

    def factory(*args, **kwargs):
        return Handler(*args, config=config, **kwargs)

    server = ThreadingHTTPServer(("127.0.0.1", PORT), factory)
    print(f"Checkout: http://127.0.0.1:{PORT}", flush=True)
    print("Android emulator CHECKOUT_URL: http://10.0.2.2:4173", flush=True)
    print("Ctrl+C to stop.", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print()
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
