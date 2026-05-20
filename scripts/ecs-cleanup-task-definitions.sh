#!/usr/bin/env bash
# ecs-cleanup-task-definitions.sh
# Deregisters all inactive ECS task definition revisions.
# Keeps only the currently active revision running in the service.
# Usage: ./ecs-cleanup-task-definitions.sh

set -euo pipefail

CLUSTER="sre-lab-dev-ecs-cluster"
SERVICE="sre-lab-dev-ecs-service"
REGION="us-east-1"

# ── Get the active task definition revision ────────────────────────────────────
ACTIVE=$(aws ecs describe-services \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$REGION" \
  --query "services[0].taskDefinition" \
  --output text)

echo ""
echo "Active task definition: $ACTIVE"
echo "All other revisions will be deregistered."
echo ""

# ── List all registered revisions ─────────────────────────────────────────────
ALL=$(aws ecs list-task-definitions \
  --family-prefix sre-lab-dev-ecs-task \
  --status ACTIVE \
  --region "$REGION" \
  --query "taskDefinitionArns[]" \
  --output text)

# ── Deregister everything except the active revision ──────────────────────────
COUNT=0

for ARN in $ALL; do
  if [ "$ARN" == "$ACTIVE" ]; then
    echo "  KEEPING  $ARN"
  else
    echo "  REMOVING $ARN"
    aws ecs deregister-task-definition \
      --task-definition "$ARN" \
      --region "$REGION" \
      --output text --query "taskDefinition.taskDefinitionArn" > /dev/null
    COUNT=$((COUNT + 1))
  fi
done

echo ""
echo "Done. $COUNT revision(s) deregistered."
echo ""
