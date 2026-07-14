#!/bin/bash
# morning-check.sh
# Daily lab triage — run this first thing, then update OPERATIONS-LOG.md
# Usage: bash scripts/morning-check.sh

set -euo pipefail

source "$(dirname "$0")/runbooks/config.sh"

LINE="════════════════════════════════════════════════════════"

echo "$LINE"
echo "  SRE Lab — Morning Check"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "$LINE"
echo ""

# ── 1. CloudWatch Alarms ─────────────────────────────────────────────────────
echo "▶ [1/4] CloudWatch Alarms"
aws cloudwatch describe-alarms \
  --alarm-names \
    "$ALARM_5XX" \
    "$ALARM_CPU" \
    "$ALARM_MEMORY" \
    "$ALARM_BURN_RATE" \
    "$ALARM_CANARY" \
    "$ALARM_VPC_REJECT" \
    "$ALARM_ALB_NO_HEALTHY_HOSTS" \
    "$ALARM_ECS_NO_RUNNING_TASKS" \
  --query "MetricAlarms[*].{Alarm:AlarmName,State:StateValue}" \
  --output table
echo ""

# ── 2. Canary — Last 3 Runs ──────────────────────────────────────────────────
echo "▶ [2/4] Canary — Last 3 Runs"
aws synthetics get-canary-runs \
  --name "$CANARY_NAME" \
  --query "CanaryRuns[0:3].{Status:Status.State,Started:Timeline.Started}" \
  --output table
echo ""

# ── 3. VPC Rejects — Last 24 Hours ──────────────────────────────────────────
echo "▶ [3/4] VPC Rejects — Last 24 Hours"
START=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)
END=$(date -u +%Y-%m-%dT%H:%M:%SZ)
REJECTS=$(aws cloudwatch get-metric-statistics \
  --namespace "SRELab/VpcFlowLogs" \
  --metric-name "VpcRejectCount" \
  --start-time "$START" \
  --end-time "$END" \
  --period 86400 \
  --statistics Sum \
  --query "Datapoints[0].Sum" \
  --output text)
echo "  Total rejected connections: $REJECTS"
echo "  (Scanner noise is normal — look for new patterns if >500)"
echo ""

# ── 4. GitHub Actions — Last 5 Runs ─────────────────────────────────────────
echo "▶ [4/4] GitHub Actions"
if command -v gh &> /dev/null; then
  gh run list \
    --repo darrelldhale/IaC-AWS-Lab \
    --limit 5 \
    --json status,conclusion,workflowName,createdAt \
    --jq '.[] | "\(.createdAt)  \(.workflowName) — \(.status) / \(.conclusion)"'
else
  echo "  gh CLI not installed — check manually:"
  echo "  https://github.com/darrelldhale/sre-lite-lab/actions"
fi
echo ""

echo "$LINE"
echo "  Check complete. Update references/OPERATIONS-LOG.md"
echo "$LINE"
