#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "================================================="
echo " NORTHWIND HEALTH GROUP RUNBOOK: Canary Failed Investigation"
echo " $(date)"
echo "================================================="

# --- STEP 1: Alarm State ---
echo ""
echo "[1/4] Checking alarm state..."
aws cloudwatch describe-alarms \
  --alarm-names "$ALARM_CANARY" \
  --region "$REGION" \
  --query "MetricAlarms[0].{State:StateValue,Reason:StateReason}" \
  --output table


# --- STEP 2: Direct connectivity test ---
echo ""
echo "[2/4] Testing ALB connectivity directly..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "http://$ALB_DNS" || echo "000")
echo "HTTP response code: $HTTP_CODE"
if [ "$HTTP_CODE" == "200" ]; then
  echo "ALB is responding normally — canary failure may be transient"
elif [ "$HTTP_CODE" == "000" ]; then
  echo "ALB unreachable — connection failed or timed out"
else
  echo "ALB returned $HTTP_CODE — connectivity issue confirmed"
fi


# --- STEP 3: ECS Service Health ---
echo ""
echo "[3/4] Checking ECS service health..."
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$REGION" \
  --query "services[0].{Running:runningCount,Desired:desiredCount,Status:status}" \
  --output table


# --- STEP 4: Recent ECS Service Events ---
echo ""
echo "[4/4] Checking recent ECS service events..."
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$REGION" \
  --query "services[0].events[:5].{Time:createdAt,Message:message}" \
  --output table


# --- RECOMMENDATION ---
echo ""
echo "================================================="
echo " RECOMMENDED NEXT STEPS"
echo "================================================="
echo " 1. If alarm is OK and curl returned 200 → transient blip, no action needed"
echo ""
echo " 2. If alarm is ALARM and curl returned 200 → canary script issue, not app issue"
echo "    Find all failed canary runs instantly:"
echo "    aws s3 ls s3://sre-lab-dev-canary-results-425924867120/ --region $REGION --recursive | grep FAILED"
echo ""
echo " 3. If alarm is ALARM and curl did NOT return 200 → real outage confirmed"
echo "    Running == Desired but no 200 → app is up but returning errors, run:"
echo "    ./investigate-5xx.sh"
echo ""
echo " 4. If Running < Desired → tasks are down, check ECS events above and logs:"
echo "    aws logs tail $LOG_GROUP --since 10m --region $REGION"
echo ""
echo " 5. Check the dashboard for full system view:"
echo "    https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=sre-lab-dev-dashboard"
echo "================================================="
