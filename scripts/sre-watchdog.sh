#!/bin/bash
# This script is a watchdog that checks if a process is running and restarts it if it's not.
set -uo pipefail

# --- CONFIG ---
SERVICE="${1:-nginx}"
CHECK_INTERVAL=10
LOG_FILE="$HOME/sre-snapshots/watchdog-${SERVICE}.log" # The name of the service to monitor
MAX_RESTARTS=5
RESTART_COUNT=0

# --- LOGGING ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - $1" | tee -a "$LOG_FILE"
}

# --- STARTUP ---
log "Starting watchdog for service: $SERVICE"
log "Check interval: ${CHECK_INTERVAL}s | Max restarts: $MAX_RESTARTS"

# --- MAIN LOOP ---
while true; do

    if sudo systemctl is-active --quiet "$SERVICE"; then
        log "[OK] $SERVICE is running."
    else
        log "[DOWN] $SERVICE is NOT running - attempting to restart."
        RESTART_COUNT=$(( RESTART_COUNT + 1 ))

        if [ "$RESTART_COUNT" -gt "$MAX_RESTARTS" ]; then
            log "[CRITICAL] Maximum restart attempts reached for $SERVICE. Exiting watchdog."
            exit 1
        fi

        if sudo systemctl restart "$SERVICE"; then
            log "[RESTARTED] Successfully restarted $SERVICE (restart ${RESTART_COUNT}/${MAX_RESTARTS})"
        else
            log "[ERROR] Failed to restart $SERVICE."
        fi
    fi

    sleep "$CHECK_INTERVAL"

done

