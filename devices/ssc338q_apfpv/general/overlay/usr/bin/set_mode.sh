#!/bin/sh
# switch_mode.sh  — set U-Boot variable “mode” and start/stop aalink service

# --- 1. Validate argument ---------------------------------------------------
[ $# -eq 1 ] || { echo "Usage: $0 {manual|aalink}"; exit 1; }

# normalise to lowercase so “Manual”, “MANUAL”, etc. work
mode=$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')

case "$mode" in
    manual|aalink) ;;          # accepted values
    *) echo "Usage: $0 {manual|aalink}"; exit 1 ;;
esac

# --- 2. Persist the choice in U-Boot ----------------------------------------
if ! fw_setenv mode "$mode"; then
    echo "Failed to write U-Boot environment – aborting." >&2
    exit 1
fi

# --- 3. Start or stop the aalink service ------------------------------------
service_script=/etc/init.d/S991aalink

if [ "$mode" = "manual" ]; then
    echo "Stopping aalink."
    "$service_script" stop
else
    echo "Starting aalink."
    "$service_script" start
fi

exit 0
