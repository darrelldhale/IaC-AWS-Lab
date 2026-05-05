#!/bin/bash
# This script captures a snapshot of the system's state before an investigation, including uptime, logged-in users, top resource consumers, disk usage, memory status, listening ports, failed services, recent errors, and OOM kills. The snapshot is saved to a timestamped file for later analysis.

# Catches any failures and exits
set -euo pipefail

# Variables
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT_DIR="$HOME/sre-snapshots"
OUTPUT_FILE="$OUTPUT_DIR/snapshot-$TIMESTAMP.txt"

# Create snapshot directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo "Created snapshot directory: $OUTPUT_DIR"
fi

# Begin snapshot
{
    echo "========================================="
    echo " PRE-INVESTIGATION SNAPSHOT"
    echo " Generated: $TIMESTAMP"
    echo " Host: $(hostname)"
    echo "========================================="
} >> "$OUTPUT_FILE"

# Function to write a section header
section() {
    {
        echo ""
        echo "----- $1 -----"
        echo ""
    } >> "$OUTPUT_FILE"
}

# Capture system data
section "UPTIME & LOAD"
uptime >> "$OUTPUT_FILE"

section "WHO IS LOGGED IN"
w >> "$OUTPUT_FILE"

section "TOP CPU CONSUMERS"
ps -aux --sort=-%cpu | head -n 15 >> "$OUTPUT_FILE"

section "TOP MEMORY CONSUMERS"
ps -aux --sort=-%mem | head -n 15 >> "$OUTPUT_FILE"

section "DISK USAGE"
df -h >> "$OUTPUT_FILE"

section "MEMORY"
free -h >> "$OUTPUT_FILE"

section "LISTENING PORTS"
ss -tuln >> "$OUTPUT_FILE"

section "FAILED SERVICES"
systemctl list-units --state=failed --no-pager >> "$OUTPUT_FILE"

section "RECENT ERRORS (last 30 minutes)"
journalctl -p err --since "30 min ago" --no-pager >> "$OUTPUT_FILE"

section "OOM KILLS"
dmesg | grep -i "oom\|killed process" >> "$OUTPUT_FILE" || echo "No OOM kills found." >> "$OUTPUT_FILE"

# Closing footer
{
    echo ""
    echo "========================================="
    echo " SNAPSHOT COMPLETE"
    echo " Saved to: $OUTPUT_FILE"
    echo "========================================="
} >> "$OUTPUT_FILE"

# Tell the operator where the snapshot is saved
echo ""
echo "Pre-investigation snapshot saved to: $OUTPUT_FILE"
echo ""
