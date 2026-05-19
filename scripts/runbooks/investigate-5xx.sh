#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "==================================================="
echo " NORTHWIND HEALTH GROUP RUNBOOK: HTTP 5xx Investigation"
echo " $(date -u '+%Y-%m-%d %H:%M:%S') UTC"
echo "==================================================="

# --- STEP 1: Alarm State ---
echo ""
echo "[1/5] Checking alarm state..."
aws cloudwatch describe-alarms \
  --alarm-names "$ALARM_5XX" \
  --region "$REGION" \
  --query "MetricAlarms[0].{State:StateValue,Reason:StateReason}" \
  --output table


# --- STEP 2: Recent 5xx Errors in Logs ---
echo ""
echo "[2/5] Querying last 10 minutes of 5xx errors in logs..."
QUERY_ID=$(aws logs start-query \
  --log-group-name "$LOG_GROUP" \
  --start-time "$(date -d '10 minutes ago' +%s)" \
  --end-time "$(date +%s)" \
  --query-string 'fields @timestamp, request, status, upstream_response_time | filter status >= 500 | sort @timestamp desc | limit 20' \
  --region "$REGION" \
  --output text)

sleep 3

aws logs get-query-results \
  --query-id "$QUERY_ID" \
  --region "$REGION" \
  --query "results[*][?field=='@timestamp' || field=='request' || field=='status'].value" \
  --output table


# --- STEP 3: ECS Service Health ---
echo""
echo "[3/5] Checking ECS service health..."
aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$REGION" \
  --query "services[0].{Running:runningCount,Desired:desiredCount,Status:status}" \
  --output table


# --- STEP 4: Last CodeDeploy Deployment ---
echo ""
echo "[4/5] Reviewing last CodeDeploy deployment..."
DEPLOYMENT_ID=$(aws deploy list-deployments \
  --application-name "$CODEDEPLOY_APP" \
  --deployment-group-name "$CODEDEPLOY_GROUP" \
  --region "$REGION" \
  --query "deployments[0]" \
  --output text)

if [ "$DEPLOYMENT_ID" == "None" ] || [ -z "$DEPLOYMENT_ID" ]; then
  echo "No deployments found for this deployment group."
else
  aws deploy get-deployment \
    --deployment-id "$DEPLOYMENT_ID" \
    --region "$REGION" \
    --query "deploymentInfo.{ID:deploymentId,Status:status,Created:createTime}" \
    --output table
fi


# --- STEP 5: Endpoint Breakdown ---
echo ""
echo "[5/5] Querying which endpoints are returning 5xx errors..."
QUERY_ID_URI=$(aws logs start-query \
  --log-group-name "$LOG_GROUP" \
  --start-time "$(date -d '10 minutes ago' +%s)" \
  --end-time "$(date +%s)" \
  --query-string 'filter status >= 500 | stats count(*) as error_count by uri | sort error_count desc | limit 10' \
  --region "$REGION" \
  --output text)

sleep 3

aws logs get-query-results \
  --query-id "$QUERY_ID_URI" \
  --region "$REGION" \
  --query "results[*][?field=='uri' || field=='error_count'].value" \
  --output table


# --- RECOMMENDATION ---
echo ""
echo "================================================="
echo " RECOMMENDED NEXT STEPS"
echo "================================================="
echo " 1. If alarm is OK → issue may have self-resolved, continue monitoring"
echo ""
echo " 2. If alarm is ALARM and a deployment is IN PROGRESS → stop and rollback:"
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
echo "   curl -s -o /dev/null -w '%{http_code}' \"http://"$ALB_DNS\""
echo "   # Expected: 200"
echo ""
echo "   ~/sre-lite-lab/scripts/runbooks/triage.sh"
echo "   # Expected: all alarms OK"
echo "==================================================="

