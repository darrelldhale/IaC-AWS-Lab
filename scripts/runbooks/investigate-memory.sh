#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "================================================="
echo " NORTHWIND HEALTH GROUP RUNBOOK: ECS Memory Investigation"
echo " $(date)"
echo "================================================="

# --- STEP 1: Alarm State ---
echo ""
echo "[1/4] Checking alarm state..."
aws cloudwatch describe-alarms \
  --alarm-names "$ALARM_MEMORY" \
  --region "$REGION" \
  --query "MetricAlarms[0].{State:StateValue,Reason:StateReason}" \
  --output table


# --- STEP 2: Current Memory Utilization ---
echo ""
echo "[2/4] Checking ECS memory utilization (last 10 minutes)..."
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name MemoryUtilization \
  --dimensions Name=ClusterName,Value="$CLUSTER" Name=ServiceName,Value="$SERVICE" \
  --start-time "$(date -u -d '10 minutes ago' '+%Y-%m-%dT%H:%M:%S')" \
  --end-time "$(date -u '+%Y-%m-%dT%H:%M:%S')" \
  --period 60 \
  --statistics Average Maximum \
  --region "$REGION" \
  --query "sort_by(Datapoints,&Timestamp)[*].{Time:Timestamp, AvgMemory:Average, MaxMemory:Maximum}" \
  --output table


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
echo " 1. If alarm is OK → issue may have self-resolved, continue monitoring"
echo ""
echo " 2. If memory is high and Running < Desired → tasks are being OOM killed,"
echo "    check ECS logs for out-of-memory errors:"
echo "    aws logs tail $LOG_GROUP --since 10m --region $REGION \\"
echo "      | grep -iE 'out of memory|oom|killed|heap|memory|malloc|cannot allocate|leak'"
echo ""
echo " 3. If memory is high and Running == Desired → likely a memory leak."
echo "    Scaling out will not fix a leak — it just adds more leaking tasks."
echo "    Check if a recent deployment preceded the spike. If so, consider a rollback:"
echo ""
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
