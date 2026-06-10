#!/usr/bin/env python3
"""Keep Render free-tier services awake by pinging their /health endpoints.

Usage:
    # One-shot ping
    python scripts/pinger.py

    # Loop forever (10 minute interval)
    python scripts/pinger.py --loop

    # Custom endpoints
    RAG_HEALTH_URL=https://shikkhaai-rag.onrender.com/health \
    BACKEND_HEALTH_URL=https://shikkhaai-backend.onrender.com/health \
        python scripts/pinger.py --loop
"""

from __future__ import annotations

import argparse
import os
import sys
import time
import urllib.error
import urllib.request


DEFAULT_RAG_URL = "http://127.0.0.1:8100/health"
DEFAULT_BACKEND_URL = "http://127.0.0.1:8000/health"


def ping(url: str, timeout: int = 30) -> tuple[bool, str]:
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response:
            body = response.read().decode("utf-8", errors="replace")[:200]
            status = response.getcode()
            return True, f"status={status} body={body!r}"
    except urllib.error.HTTPError as exc:
        return False, f"HTTP error {exc.code} for {url}"
    except urllib.error.URLError as exc:
        return False, f"URL error {exc.reason} for {url}"
    except Exception as exc:  # noqa: BLE001
        return False, f"Error pinging {url}: {exc}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Ping ShikkhaAI services to keep them warm")
    parser.add_argument(
        "--rag-url",
        default=os.getenv("RAG_HEALTH_URL", DEFAULT_RAG_URL),
        help="RAG service health URL (env: RAG_HEALTH_URL)",
    )
    parser.add_argument(
        "--backend-url",
        default=os.getenv("BACKEND_HEALTH_URL", DEFAULT_BACKEND_URL),
        help="Backend health URL (env: BACKEND_HEALTH_URL)",
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=int(os.getenv("PING_INTERVAL_SECONDS", "600")),
        help="Seconds between pings in loop mode (env: PING_INTERVAL_SECONDS, default: 600)",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=int(os.getenv("PING_TIMEOUT_SECONDS", "30")),
        help="Request timeout in seconds (env: PING_TIMEOUT_SECONDS, default: 30)",
    )
    parser.add_argument(
        "--loop",
        action="store_true",
        help="Run continuously instead of one-shot",
    )

    args = parser.parse_args()

    if not args.rag_url and not args.backend_url:
        print("Error: at least one URL must be provided.", file=sys.stderr)
        return 1

    urls = [
        ("RAG", args.rag_url),
        ("Backend", args.backend_url),
    ]

    while True:
        for name, url in urls:
            if not url:
                continue
            ok, msg = ping(url, timeout=args.timeout)
            prefix = "OK" if ok else "FAIL"
            print(f"[{prefix}] {name}: {msg}")

        if not args.loop:
            break

        print(f"Sleeping {args.interval}s...")
        time.sleep(args.interval)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
