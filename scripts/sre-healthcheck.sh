#!/bin/bash
# This script performs a simple health check on the system, checking disk usage, memory usage, CPU load, failed services, and listening network ports.
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print pass or fail
pass() {
	echo -e "${GREEN}[PASS]${NC} $1"
}
fail() {
	echo -e "${RED}[FAIL]${NC} $1"
}
warn() {
	echo -e "${YELLOW}[WARN]${NC} $1"
}

# Header
echo ""
echo "========================================="
echo " SRE HEALTH CHECK"
echo " Host: $(hostname)"
echo " Time: $(date)"
echo "========================================="
echo ""

# --- LAYER 1: DISK ---
echo "[ DISK ]"
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

if [ "$DISK_USAGE" -ge 90 ]; then
	fail "Disk usage is at ${DISK_USAGE}% - critically full"
elif [ "$DISK_USAGE" -ge 75 ]; then
	warn "Disk usage is at ${DISK_USAGE}% - getting full"
else
	pass "Disk usage is at ${DISK_USAGE}%"
fi

# --- LAYER 2: MEMORY ---
echo ""
echo "[ MEMORY ]"
MEM_TOTAL=$(free -m | awk 'NR==2 {print $2}')
MEM_USED=$(free -m | awk 'NR==2 {print $3}')
MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))

if [ "$MEM_PCT" -ge 90 ]; then
	fail "Memory usage is at ${MEM_PCT}% - critically high"
elif [ "$MEM_PCT" -ge 75 ]; then
	warn "Memory usage is at ${MEM_PCT}% - getting high"
else
	pass "Memory usage is at ${MEM_PCT}%"
fi

# --- LAYER 3: CPU LOAD ---
echo ""
echo "[ CPU LOAD ]"
CPU_CORES=$(nproc)
LOAD_AVG=$(uptime | awk -F'load average: ' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
LOAD_INT=$(echo "$LOAD_AVG" | cut -d'.' -f1)
HALF_CORES=$((CPU_CORES / 2))

if [ "$HALF_CORES" -lt 1 ]; then
  HALF_CORES=1
fi


if [ "$LOAD_INT" -ge "$CPU_CORES" ]; then
	fail "CPU load average is at ${LOAD_AVG} - at or above ${CPU_CORES} cores"
elif [ "$LOAD_INT" -ge "$HALF_CORES" ]; then
	warn "CPU load average is at ${LOAD_AVG} - above 50% of ${CPU_CORES} cores"
else
	pass "CPU load average is at ${LOAD_AVG} across ${CPU_CORES} cores"
fi

# --- LAYER 4: FAILED SERVICES ---
echo ""
echo "[ FAILED SERVICES ]"
FAILED_SERVICES=$(systemctl list-units --state=failed --no-pager --no-legend | wc -l)

if [ "$FAILED_SERVICES" -gt 0 ]; then
	fail "There are ${FAILED_SERVICES} failed services"
	systemctl list-units --state=failed --no-pager --no-legend
else
	pass "No failed services detected"
fi

# --- LAYER 5: NETWORK PORTS ---
echo ""
echo "[ NETWORK PORTS ]"
LISTEN_PORTS=$(ss -tulnp | grep -c LISTEN)

if [ "$LISTEN_PORTS" -gt 0 ]; then
	pass "There are ${LISTEN_PORTS} listening ports"
	ss -tulnp | grep LISTEN
else
	warn "No ports are currently listening - is anything running?"
fi

# FOOTER
echo ""
echo "========================================="
echo " HEALTH CHECK COMPLETE: $(date)"
echo "========================================="
echo ""
