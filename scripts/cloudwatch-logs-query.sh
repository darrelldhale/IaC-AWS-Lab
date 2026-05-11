#!/bin/bash
# Usage: ./cloudwatch-logs-query.sh <query-id>
# Fetches CloudWatch Logs Insights results in a readable table format

aws logs get-query-results \
  --query-id "$1" \
  --output json | \
jq -r '["TIMESTAMP","METHOD","STATUS","URI","TIME(s)"],
       (.results[] | map(select(.field != "@ptr")) |
       map({(.field): .value}) | add |
       [.["@timestamp"], .method, .status, .uri, .request_time]) |
       @tsv' | \
column -t -s $'\t'
