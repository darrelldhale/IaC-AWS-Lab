#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"


echo "================================================="
echo " NORTHWIND RUNBOOK: SLO Burn Rate Investigation"
echo " $(date)"
echo "================================================="

# --- STEP 1: Alarm State ---
echo ""
echo "[1/4] Checking alarm state..."
aws cloudwatch describe-alarms \
  --alarm-names "$ALARM_BURN_RATE" \
  --region "$REGION" \
  --query "MetricAlarms[0].{State:StateValue,Reason:StateReason}" \
  --output table


# --- STEP 2: Recent 5xx Count ---
echo "[2/4] Checking recent 5xx error count (last 30 minutes)..."
aws cloudwatch get-metric-statistics \
  --namespace SRELab/Nginx \
  --metric-name Http5xxCount  \
  --start-time "$(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --period 60 \
  --statistics Sum \
  --region "$REGION" \
  --query "sort_by(Datapoints, &Timestamp)[*].{Time:Timestamp,Errors:Sum}" \
  --output table


# --- STEP 3: Recent Total Request Count ---
echo ""
echo "[3/4] Checking total request count (last 30 minutes)..."
aws cloudwatch get-metric-statistics \
  --namespace SRELab/Nginx \
  --metric-name HttpRequestCount \
  --start-time "$(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --period 60 \
  --statistics Sum \
  --region "$REGION" \
  --query "sort_by(Datapoints, &Timestamp)[*].{Time:Timestamp,Requests:Sum}" \
  --output table


# --- STEP 4: Recent 5xx Errors in Logs ---
echo ""
echo "[4/4] Querying last 30 minutes of 5xx errors in logs..."
QUERY_ID=$(aws logs start-query \
  --log-group-name "$LOG_GROUP" \
  --start-time "$(date -d '30 minutes ago' +%s)" \
  --end-time "$(date +%s)" \
  --query-string 'fields @timestamp, request, status | filter status >= 500 | sort @timestamp desc | limit 20' \
  --region "$REGION" \
  --output text)

sleep 3

aws logs get-query-results \
  --query-id "$QUERY_ID" \
  --region "$REGION" \
  --query "results[*][?field=='@timestamp' || field=='request' || field=='status'].value" \
  --output table


# --- RECOMMENDATION ---
echo ""
echo "================================================="
echo " RECOMMENDED NEXT STEPS"
echo "================================================="
echo " REMINDER: Northwind SLO = 99.5% success rate over 30 days"
echo " Burn rate alarm fires when errors are consuming budget 14.4x faster than allowed"
echo ""
echo " 1. If alarm is OK → budget consumption has slowed, continue monitoring"
echo ""
echo " 2. Check the dashboard for live success rate and burn rate — no math needed:"
echo "    https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=sre-lab-dev-dashboard"
echo ""
echo " 3. If 5xx errors are present → run the 5xx runbook for root cause:"
echo "    ./investigate-5xx.sh"
echo ""
echo " 4. If a deployment preceded the errors → rollback:"
echo "==================================================="
echo " RECOVERY PATHS"
echo "==================================================="
echo ""
echo " PATH A — Deployment is InProgress (catch it early):"
echo "   aws deploy stop-deployment \\"
echo "     --deployment-id $DEPLOYMENT_ID \\"
echo "     --auto-rollback-enabled"
echo ""
echo " PATH B — Deployment succeeded, previous active revision exists:"
echo "   1. Identify the last known good revision from step 3 output above"
echo "   2. Update deployment.json — change the task definition ARN to that revision"
echo "   3. Trigger recovery deployment:"
echo "      aws deploy create-deployment \\"
echo "        --cli-input-json file://deployment.json \\"
echo "        --output json"
echo ""
echo " PATH C — Deployment succeeded, only bad revision is active (Terraform deregistered rest):"
echo "   1. Update terraform.tfvars — set container_image to last known good image tag"
echo "   2. Run: ./tf-check.sh"
echo "   3. Run: terraform apply"
echo "   4. Copy the new task definition ARN from Terraform output"
echo "   5. Update deployment.json with the new ARN"
echo "   6. Trigger recovery deployment:"
echo "      aws deploy create-deployment \\"
echo "        --cli-input-json file://deployment.json \\"
echo "        --output json"
echo "
echo "   7. Make sure to push the tfvars change BACK to the repo."
echo ""
echo " VERIFY RECOVERY:"
echo "   curl -s -o /dev/null -w '%{http_code}' http://"$ALB_DNS"
echo "   # Expected: 200"
echo ""
echo "   ~/sre-lite-lab/scripts/runbooks/triage.sh"
echo "   # Expected: all alarms OK"
echo "==================================================="
