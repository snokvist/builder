#!/bin/sh
# Usage:  ./set_wlan_ssid <new-ssid>

# --- sanity-check that exactly one argument was supplied ---------------------
if [ "$#" -ne 1 ]; then
    echo "Error: please supply exactly one argument (the new SSID)." | tee /tmp/webui.log
    echo "Your SSID must be 1–16 characters long and may contain only letters and digits. Example:  $0 MyHome123" | tee /tmp/webui.log
    exit 1
fi

ssid="$1"

# --- rule 1: length 1–16 -----------------------------------------------------
len=${#ssid}
if [ "$len" -lt 1 ] || [ "$len" -gt 16 ]; then
    echo "Error: SSID must be at least 1 and at most 16 characters long." | tee /tmp/webui.log
    exit 1
fi

# --- rule 2: only letters or digits -----------------------------------------
if ! printf '%s\n' "$ssid" | grep -Eq '^[A-Za-z0-9]+$'; then
    echo "Error: SSID may contain only letters (A–Z, a–z) and digits (0–9); no spaces or special characters." | tee /tmp/webui.log
    exit 1
fi

# --- all checks passed – commit to environment ------------------------------
if fw_setenv wlanssid "$ssid"; then
    echo "SSID stored successfully. Please restart the device to apply the new SSID." | tee /tmp/webui.log
else
    echo "Error: fw_setenv failed." | tee /tmp/webui.log
    exit 1
fi

exit 0
