#!/bin/sh
# set_distance.sh  –  distance-based ACK/CTS timeout updater + status viewer
#                  Updates are logged to /tmp/webui.log (overwritten).
#
# Usage:
#   set_distance.sh [--quiet] <distance_in_meters>
#   set_distance.sh [--quiet] status | print
#
# Notes:
# - Distance must be a non-negative integer (meters).
# - Timeout formulas:
#     ACK_timeout  = 33 + ceil(2*distance/300)
#     CTS2_timeout = 20 + ceil(distance/300)
# - Automatically detects any rtl8xxx driver under /proc/net/*8*.

LOG=/tmp/webui.log
IFACE=wlan0

# Parse optional --quiet
QUIET=0
if [ "$1" = "--quiet" ]; then
    QUIET=1
    shift
fi

# Discover the first rtl8xxx driver proc path matching our interface
PROC_BASE=$(ls -d /proc/net/*8*/* 2>/dev/null | grep "/${IFACE}$" | head -n1)
if [ -z "$PROC_BASE" ]; then
    echo "✗ Unable to locate /proc/net/*8*/${IFACE}." >&2
    exit 1
fi

print_status() {
    cat "${PROC_BASE}/ack_timeout"
    cat "${PROC_BASE}/cts2_timeout"
}

# Check arguments
[ $# -ne 1 ] && {
    echo "Usage: $0 [--quiet] <distance_in_meters> | status" >&2
    exit 1
}
arg="$1"

# Status mode
case "$arg" in
    status|print)
        if [ "$QUIET" -eq 1 ]; then
            print_status > /dev/null
        else
            print_status | tee "$LOG"
        fi
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

# Print and log results (or suppress if quiet)
if [ "$QUIET" -eq 1 ]; then
    {
        echo "Distance: ${DIST} m"
        echo "Set ACK Timeout  = ${ACK_TIMEOUT} us"
        echo "Set CTS2 Timeout = ${CTS_TIMEOUT} us"
        print_status
    } > /dev/null
else
    {
        echo "Distance: ${DIST} m"
        echo "Set ACK Timeout  = ${ACK_TIMEOUT} us"
        echo "Set CTS2 Timeout = ${CTS_TIMEOUT} us"
        print_status
    } | tee "$LOG"
fi
