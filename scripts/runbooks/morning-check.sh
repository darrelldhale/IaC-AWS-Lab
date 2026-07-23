#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "==================================================="
echo " NORTHWIND HEALTH GROUP DR RUNBOOK: Morning First Check"
echo " $(date -u '+%Y-%m-%d %H:%M:%S') UTC"
echo "==================================================="

# --- STEP 1: Current Alarm State ---
echo ""
echo "[1/4] Checking all alarm states..."
aws cloudwatch describe-alarms \
	--alarm-names "$ALARM_5XX" "$ALARM_CPU" "$ALARM_MEMORY" "$ALARM_BURN_RATE" "$ALARM_CANARY" "$ALARM_VPC_REJECT" "$ALARM_ALB_NO_HEALTHY_HOSTS" "$ALARM_ECS_NO_RUNNING_TASKS" \
	--region "$REGION" \
	--query "MetricAlarms[*].{Alarm:AlarmName,State:StateValue}" \
	--output table

# --- STEP 2: Last Deployment Status ---
echo ""
echo "[2/4] Checking last CodeDeploy deployment..."
DEPLOYMENT_ID=$(aws deploy list-deployments \
	--application-name "$CODEDEPLOY_APP" \
	--deployment-group-name "$CODEDEPLOY_GROUP" \
	--region "$REGION" \
	--query "deployments[0]" \
	--output text)

if [ "$DEPLOYMENT_ID" == "None" ] || [ -z "$DEPLOYMENT_ID" ]; then
	echo "No deployments found."
else
	aws deploy get-deployment \
		--deployment-id "$DEPLOYMENT_ID" \
		--region "$REGION" \
		--query "deploymentInfo.{ID:deploymentId,Status:status,Created:createTime}" \
		--output table
fi

# --- STEP 3: Active Task Definitions ---
echo ""
echo "[3/4] Checking active task definition revisions..."
aws ecs list-task-definitions \
	--family-prefix "$TASK_FAMILY" \
	--status ACTIVE \
	--region "$REGION" \
	--query "taskDefinitionArns" \
	--output table

# --- STEP 4: ECS Service Health ---
echo ""
echo "[4/4] Checking ECS service health..."
aws ecs describe-services \
	--cluster "$CLUSTER" \
	--services "$SERVICE" \
	--region "$REGION" \
	--query "services[0].{Desired:desiredCount,Running:runningCount,Status:status}" \
	--output table

# --- RECOVERY PATHS ---
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
echo "
echo " VERIFY RECOVERY:"
echo "   curl -s -o /dev/null -w '%{http_code}' http://${ALB_DNS}"
echo "   # Expected: 200"
echo ""
echo "   ~/sre-lite-lab/scripts/runbooks/triage.sh"
echo "   # Expected: all alarms OK"
echo "==================================================="
