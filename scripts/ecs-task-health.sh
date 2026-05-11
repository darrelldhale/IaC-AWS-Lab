#!/bin/bash
# ECS task health status table
set -uo pipefail

CLUSTER="${1:-sre-lab-dev-ecs-cluster}"

TASKS=$(aws ecs list-tasks --cluster "$CLUSTER" --query 'taskArns' --output text 2>/dev/null)

if [ -z "$TASKS" ]; then
  echo "No tasks found in cluster: $CLUSTER"
  exit 0
fi

printf "\nCluster: %s\n\n" "$CLUSTER"
printf "%-20s %-30s %-12s %-12s %-20s\n" "TASK ID" "SERVICE" "STATUS" "HEALTH" "STARTED"
printf "%-20s %-30s %-12s %-12s %-20s\n" "--------------------" "------------------------------" "------------" "------------" "--------------------"

aws ecs describe-tasks --cluster "$CLUSTER" --tasks $TASKS \
  --query 'tasks[*].{id:taskArn,group:group,last:lastStatus,health:healthStatus,started:startedAt}' \
  --output json | \
jq -r '.[] | [
  (.id | split("/") | last | .[0:20]),
  (.group | ltrimstr("service:") | .[0:30]),
  (.last // "UNKNOWN"),
  (.health // "UNKNOWN"),
  (.started // "N/A" | if . != "N/A" then (. | split("T") | .[0] + " " + (.[1] | split(".")[0])) else . end)
] | @tsv' | \
while IFS=$'\t' read -r id group status health started; do
  printf "%-20s %-30s %-12s %-12s %-20s\n" "$id" "$group" "$status" "$health" "$started"
done

echo ""
