#!/bin/sh
# Usage:  ./set_wlan_pass <new‑password>

# --- sanity‑check that exactly one argument was supplied ---------------------
if [ "$#" -ne 1 ]; then
    echo "Error: please supply exactly one argument (the new WLAN password)." | tee /tmp/webui.log
    echo "Your password cannot be empty and must be at least 8 characters long and not contain trailing spaces. Example:  $0 MySecret123" | tee /tmp/webui.log
    exit 1
fi

pass="$1"

# --- rule 1: length ≥ 8 ------------------------------------------------------
if [ "${#pass}" -lt 8 ]; then
    echo "Error: password must be at least 8 characters long." | tee /tmp/webui.log
    exit 1
fi

# --- rule 2: only letters or digits -----------------------------------------
# grep -Eq … returns 0 on a match, non‑zero otherwise.
if ! printf '%s\n' "$pass" | grep -Eq '^[A-Za-z0-9]+$'; then
    echo "Error: password may contain only letters (A–Z, a–z) and digits (0–9)." | tee /tmp/webui.log
    exit 1
fi

# --- all checks passed – commit to environment ------------------------------
if fw_setenv wlanpass "$pass"; then
    echo "Password "$pass" stored successfully. Please restart the device to apply the new password" | tee /tmp/webui.log
else
    echo "Error: fw_setenv failed." | tee /tmp/webui.log
    exit 1
fi

exit 0
