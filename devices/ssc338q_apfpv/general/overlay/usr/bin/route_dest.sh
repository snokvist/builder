#!/bin/sh
set -eu

DEV="wlan0"

usage() {
  echo "Usage: $0 <gateway-IP>"
  exit 1
}

# 1) Check argument count
[ $# -eq 1 ] || usage

GW=$1

# 2) Basic IPv4 validation
echo "$GW" | grep -E -q '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || {
  echo "Error: '$GW' is not a valid IPv4 address." >&2
  exit 1
}

# 3) Replace default route
echo "Switching default route to via $GW dev $DEV …"
if ip route replace default via "$GW" dev "$DEV"; then
  echo "✔ Default route is now: $(ip route show default)"
else
  echo "✖ Failed to replace default route" >&2
  exit 1
fi

# 4) (On very old kernels, you could also:)
#    ip route flush cache
