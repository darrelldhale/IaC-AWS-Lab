#!/usr/bin/env python3
"""
alarm-check.py
Checks the current state of all SRE Lab CloudWatch alarms.
Usage: python3 alarm-check.py
"""

import boto3

# ── Configuration ──────────────────────────────────────────────────────────────

REGION = "us-east-1"

ALARMS = [
    "sre-lab-dev-http-5xx-too-high",
    "sre-lab-dev-ecs-cpu-too-high",
    "sre-lab-dev-ecs-memory-too-high",
    "sre-lab-dev-burn-rate-too-high",
    "sre-lab-dev-canary-failed",
    "sre-lab-dev-vpc-reject-too-high",
]

# ── State formatting ───────────────────────────────────────────────────────────

STATE_ICONS = {
    "OK":                 "✅ OK",
    "ALARM":              "❌ ALARM",
    "INSUFFICIENT_DATA":  "⚠️  INSUFFICIENT_DATA",
}

# ── Main ───────────────────────────────────────────────────────────────────────

def check_alarms():
    client = boto3.client("cloudwatch", region_name=REGION)

    response = client.describe_alarms(AlarmNames=ALARMS)
    alarms = response["MetricAlarms"]

    print("\n📋 SRE Lab — Alarm Status")
    print("=" * 50)

    firing = []

    for alarm in alarms:
        name  = alarm["AlarmName"]
        state = alarm["StateValue"]
        icon  = STATE_ICONS.get(state, state)
        print(f"  {icon:<28} {name}")

        if state == "ALARM":
            firing.append(name)

    print("=" * 50)

    if firing:
        print(f"\n🚨 {len(firing)} alarm(s) firing — begin triage immediately")
        for name in firing:
            print(f"   → {name}")
    else:
        print("\n✅ All alarms OK — system healthy")

    print()

if __name__ == "__main__":
    check_alarms()
