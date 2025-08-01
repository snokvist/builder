#!/bin/sh
# set_distance.sh  –  distance‑based ACK/CTS timeout updater + status viewer
#                  Updates are logged to /tmp/webui.log (overwritten).
#
# Usage:
#   set_distance.sh <distance_in_meters>
#   set_distance.sh status        # or:  set_distance.sh print
#
# Notes:
# - Distance must be a non-negative integer (meters).
# - Timeout formulas:
#     ACK_timeout  = 33 + ceil(2*distance/300)
#     CTS2_timeout = 20 + ceil(distance/300)
# - Requires write access to /proc/net/rtl88x2eu/<iface>/*_timeout.

LOG=/tmp/webui.log
IFACE=wlan0
PROC_BASE="/proc/net/rtl88x2eu/${IFACE}"

print_status() {
    cat "${PROC_BASE}/ack_timeout"
    cat "${PROC_BASE}/cts2_timeout"
}

# Check arguments
[ $# -ne 1 ] && {
    echo "Usage: $0 <distance_in_meters> | status" >&2
    exit 1
}
arg="$1"

# Status mode
case "$arg" in
    status|print)
        print_status
        exit 0
        ;;
esac

# Validate numeric distance
case "$arg" in
    ''|*[!0-9]*)
        echo "✗ Invalid distance: $arg" >&2
        echo "  Distance must be a non-negative integer (meters)." >&2
        exit 1
        ;;
esac
DIST=$arg

# Base guard values (µs)
BASE_ACK=33
BASE_CTS=20

# Compute extra propagation time (ceil)
ACK_EXTRA=$(((2*DIST + 300 - 1) / 300))
CTS_EXTRA=$(((DIST + 300 - 1) / 300))

# Final timeout values
ACK_TIMEOUT=$((BASE_ACK + ACK_EXTRA))
CTS_TIMEOUT=$((BASE_CTS + CTS_EXTRA))

# Apply settings
echo "${ACK_TIMEOUT}" > "${PROC_BASE}/ack_timeout"
echo "${CTS_TIMEOUT}" > "${PROC_BASE}/cts2_timeout"

# Print and log
{
    echo "Distance: ${DIST} m"
    echo "Set ACK Timeout  = ${ACK_TIMEOUT} us"
    echo "Set CTS2 Timeout = ${CTS_TIMEOUT} us"
    print_status
} | tee "${LOG}"
