#!/bin/sh
# Usage:  ./set_wlan_pass <new‑password>

# --- sanity‑check that exactly one argument was supplied ---------------------
if [ "$#" -ne 1 ]; then
    echo "Error: please supply exactly one argument (the new WLAN password)." >&2
    echo "Example:  $0 MySecret123" >&2
    exit 1
fi

pass="$1"

# --- rule 1: length ≥ 8 ------------------------------------------------------
if [ "${#pass}" -lt 8 ]; then
    echo "Error: password must be at least 8 characters long." >&2
    exit 1
fi

# --- rule 2: only letters or digits -----------------------------------------
# grep -Eq … returns 0 on a match, non‑zero otherwise.
if ! printf '%s\n' "$pass" | grep -Eq '^[A-Za-z0-9]+$'; then
    echo "Error: password may contain only letters (A–Z, a–z) and digits (0–9)." >&2
    exit 1
fi

# --- all checks passed – commit to environment ------------------------------
if fw_setenv wlanpass "$pass"; then
    echo "Password stored successfully."
else
    echo "Error: fw_setenv failed." >&2
    exit 1
fi

exit 0
