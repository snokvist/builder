#!/bin/sh
# map a friendly power level to the value expected by iw (mBm, e.g. 1000 = 10 dBm)

# normalise the argument to lowercase once
level=$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')

case "$level" in
    low)    PWR=1000 ;;   # 10 dBm
    medium) PWR=2000 ;;   # 20 dBm
    high)   PWR=3000 ;;   # 30 dBm
    *)
        echo "Unknown level: $1" >&2
        echo "Usage: $0 Low|Medium|High" >&2
        exit 1
        ;;
esac

fw_setenv wlanpwr "$PWR"
iw dev wlan0 set txpower fixed "$PWR"
iw dev wlan0 set txpower limit "$PWR"
echo "Power set to $PWR."
exit 0
