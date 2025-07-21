#!/bin/sh
# Map a friendly power level to the value expected by iw (mBm, e.g. 1000 = 10 dBm)

###############################################################################
# Detect driver
###############################################################################
driver=
for card in $(lsusb | awk '{print $6}' | uniq); do
    case "$card" in
        "0bda:8812" | "0bda:881a" | "0b05:17d2" | "2357:0101" | "2604:0012")
            driver=88XXau ;;
        "0bda:a81a")
            driver=8812eu ;;
        "0bda:f72b" | "0bda:b733")
            driver=8733bu ;;
    esac
done

###############################################################################
# Translate user-friendly level to numeric mBm
###############################################################################
level=$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')

case "$level" in
    pitmode) PWR=250  ;;   # 2.5 dBm
    low)     PWR=750  ;;   # 10 dBm
    medium)  PWR=1500 ;;   # 20 dBm
    high)    PWR=2500 ;;   # 30 dBm
    *)
        echo "Unknown level: $1" >&2
        echo "Usage: $0 Pitmode|Low|Medium|High" >&2
        exit 1 ;;
esac

###############################################################################
# Apply settings
###############################################################################
fw_setenv wlanpwr "$PWR"          # Always store the original value

TXPWR="$PWR"                      # Default: send the original value
if [ "$driver" = "88XXau" ]; then
    if [ "$PWR" -gt 1999 ]; then
        # if PWR > 1999, subtract 500 before doubling & negating
        adj=$(( PWR - 500 ))
    else
        # otherwise use the raw value
        adj=$PWR
    fi
    TXPWR=$(( -2 * adj ))
fi

iw dev wlan0 set txpower fixed "$TXPWR"

# Skip the limit command for 88XXau
if [ "$driver" != "88XXau" ]; then
    iw dev wlan0 set txpower limit "$PWR"
fi

echo "Power set to $TXPWR ($level)." | tee /tmp/webui.log
exit 0
