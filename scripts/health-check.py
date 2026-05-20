#!/usr/bin/env python3
"""
health-check.py
On-demand HTTP health check for the Northwind ALB endpoint.
Usage: python3 health-check.py <alb-url>
"""

import sys
import time
import requests

# ── Configuration ─────────────────────────────────────────────────────────────

TIMEOUT_SECONDS = 10
LATENCY_WARNING_MS = 1000  # warn if response takes longer than 1 second

# ── Functions ──────────────────────────────────────────────────────────────────

def check_endpoint(url):
    print(f"\n[CHECK] {url}")
    print("-" * 50)

    try:
        start = time.time()
        response = requests.get(url, timeout=TIMEOUT_SECONDS)
        latency_ms = round((time.time() - start) * 1000)

        status = response.status_code

        # ── Status code result ─────────────────────────────────────────────
        if status == 200:
            print(f"  Status : {status} ✅ OK")
        else:
            print(f"  Status : {status} ❌ UNEXPECTED")

        # ── Latency result ─────────────────────────────────────────────────
        if latency_ms < LATENCY_WARNING_MS:
            print(f"  Latency: {latency_ms}ms ✅ OK")
        else:
            print(f"  Latency: {latency_ms}ms ⚠️  SLOW")

        # ── Overall verdict ────────────────────────────────────────────────
        print("-" * 50)
        if status == 200 and latency_ms < LATENCY_WARNING_MS:
            print("  Result : PASS ✅")
        else:
            print("  Result : FAIL ❌")

    except requests.exceptions.ConnectionError:
        print("  Error  : ❌ Could not connect — is the ALB reachable?")
    except requests.exceptions.Timeout:
        print(f"  Error  : ❌ Request timed out after {TIMEOUT_SECONDS}s")

    print()

# ── Entry point ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 health-check.py <alb-url>")
        print("Example: python3 health-check.py http://my-alb-dns.amazonaws.com")
        sys.exit(1)

    url = sys.argv[1]
    check_endpoint(url)
