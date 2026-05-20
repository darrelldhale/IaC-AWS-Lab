#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "================================================="
echo " NORTHWIND HEALTH GROUP TRIAGE — All Alarm Status And ECS Health"
echo " $(date)"
echo "================================================="

echo ""
echo "Checking ECS Tasks Health..."
echo ""

aws ecs describe-services \
  --cluster sre-lab-dev-ecs-cluster \
  --services sre-lab-dev-ecs-service \
  --query "services[0].{Running:runningCount,Desired:desiredCount,Pending:pendingCount}" \
  --output table

aws elbv2 describe-target-groups \
  --query "TargetGroups[?starts_with(TargetGroupName, 'sre-lab-dev')].TargetGroupArn" \
  --output text | tr '\t' '\n' | while read -r arn; do
  echo "=== $arn ==="
  aws elbv2 describe-target-health \
    --target-group-arn "$arn" \
    --query 'TargetHealthDescriptions[*].[Target.Id, Target.Port, TargetHealth.State, TargetHealth.Description]' \
    --output table
done

sleep 3

echo ""
echo "Checking all 6 alarms..."
echo ""

aws cloudwatch describe-alarms \
  --alarm-names \
    "$ALARM_5XX" \
    "$ALARM_CPU" \
    "$ALARM_MEMORY" \
    "$ALARM_BURN_RATE" \
    "$ALARM_CANARY" \
    "$ALARM_VPC_REJECT" \
  --region "$REGION" \
  --query "MetricAlarms[*].{Alarm:AlarmName,State:StateValue,Reason:StateReason}" \
  --output table

echo ""
echo "================================================="
echo " RUNBOOK ROUTING"
echo "================================================="
echo " sre-lab-dev-http-5xx-too-high    → ./investigate-5xx.sh"
echo " sre-lab-dev-ecs-cpu-too-high     → ./investigate-cpu.sh"
echo " sre-lab-dev-ecs-memory-too-high  → ./investigate-memory.sh"
echo " sre-lab-dev-slo-burn-rate-too-high → ./investigate-burn-rate.sh"
echo " sre-lab-dev-canary-failed        → ./investigate-canary.sh"
echo ""
echo " Dashboard:"
echo " https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=sre-lab-dev-dashboard"
echo "================================================="
