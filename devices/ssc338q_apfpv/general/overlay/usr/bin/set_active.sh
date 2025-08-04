#!/bin/sh
#
# change-active-ip.sh  –  update ACTIVE_IP in /etc/aalink.conf
# Usage: change-active-ip.sh <new-ip>

set -e

# --- sanity checks ---------------------------------------------------------
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ip-address>" >&2
    exit 1
fi

NEW_IP="$1"
CONF_FILE="/etc/aalink.conf"

if [ ! -w "$CONF_FILE" ]; then
    echo "Error: cannot write to $CONF_FILE (are you root?)." >&2
    exit 1
fi

# --- update /etc/aalink.conf ----------------------------------------------
# Replace an existing ACTIVE_IP line; if none exists, append one.
if grep -q '^ACTIVE_IP=' "$CONF_FILE"; then
    # BusyBox sed supports -i
    sed -i "s/^ACTIVE_IP=.*/ACTIVE_IP=${NEW_IP}/" "$CONF_FILE"
else
    echo "ACTIVE_IP=${NEW_IP}" >> "$CONF_FILE"
fi

# --- tell aalink to reload its config -------------------------------------
if pidof aalink >/dev/null 2>&1; then
    kill -SIGHUP "$(pidof aalink)"
else
    echo "Warning: aalink process not running; nothing to HUP." >&2
fi
