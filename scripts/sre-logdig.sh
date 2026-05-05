#!/bin/bash
# This script searches across multiple log sources for patterns - errors, a specific IP, an exception name, etc.
set -uo pipefail

# --- ARGUMENT VALIDATION ---
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <search_pattern> [since]"
    echo "Example: $0 'ERROR' '1 hour ago'"
    echo "Example: $0 '502' '30 min ago'"
    exit 1
fi

# --- VARIABLES ---
SEARCH_PATTERN="$1"
SINCE="${2:-1 hour ago}"  # Default to searching logs from the last hour

# --- HEADER ---
echo ""
echo "================================"
echo " SRE LogDig"
echo " Pattern: $SEARCH_PATTERN"
echo " Since: $SINCE"
echo " Host: $(hostname)"
echo " Time: $(date)"
echo "================================"
echo ""

# ---- LOG SOURCES ---
# Define an array of log sources to search through
SERVICES=(
    "my_app"
    "nginx"
    "sshd"
    "systemd"
)

# --- SEARCH LOGS ---
for SERVICE in "${SERVICES[@]}"; do
    echo "--- Checking: $SERVICE ---"

    RESULTS=$(journalctl -u "$SERVICE" \
        --since "$SINCE" \
        --no-pager \
        --output=short \
        2>/dev/null | grep -i "$SEARCH_PATTERN" || true)

    if [ -n "$RESULTS" ]; then
        echo "$RESULTS"
    else
        echo "No matches found for $SERVICE."
    fi

    echo ""
done

# --- FOOTER ---
echo "================================"
echo " LogDig complete: $(date)"
echo "================================"
echo ""
