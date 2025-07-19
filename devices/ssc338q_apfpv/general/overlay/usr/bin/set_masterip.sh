#!/bin/sh
# Usage:  ./set_ip_addr <new-IP-address>
#
# This script validates a user‑supplied IPv4 address and stores it
# in persistent U‑Boot environment under the variable *master_ip* via fw_setenv.
# ‑ An IPv4 address must consist of four octets (0–255) separated by dots.
# ‑ If validation fails, an explanatory error is written to /tmp/webui.log.
#
# ---------------------------------------------------------------------------

# --- sanity‑check that exactly one argument was supplied --------------------
if [ "$#" -ne 1 ]; then
    echo "Error: please supply exactly one argument (the new IP address)." | tee /tmp/webui.log
    echo "Example:  $0 192.168.0.10" | tee /tmp/webui.log
    exit 1
fi

ip="$1"

# --- rule: must be a valid IPv4 dotted‑decimal address ----------------------
# Quick regex screening (each octet 0‑255):
if ! printf '%s\n' "$ip" | grep -Eq '^(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])$'; then
    echo "Error: \"$ip\" is not a valid IPv4 address (format: x.x.x.x with each x 0‑255)." | tee /tmp/webui.log
    exit 1
fi

# --- all checks passed – commit to environment -----------------------------
# Stores the address in the U‑Boot environment variable "master_ip".
if fw_setenv master_ip "$ip"; then
    echo "IP address \"$ip\" stored successfully. Please restart the device to apply the new address." | tee /tmp/webui.log
else
    echo "Error: fw_setenv failed." | tee /tmp/webui.log
    exit 1
fi

exit 0
