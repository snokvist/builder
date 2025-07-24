#!/bin/sh
# Set or query Wi‑Fi TX power.
# Presets : Pitmode • Low • Medium • High
# Manual  : tx_power <mBm 50‑3150>
# Query   : get_current                (prints current power in mBm)

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
# Parse arguments
###############################################################################
if [ $# -eq 0 ]; then
    echo "Usage:"
    echo "  $0 Pitmode|Low|Medium|High"
    echo "  $0 tx_power <50‑3150>"
    echo "  $0 get_current           # prints current mBm"
    exit 1
fi

level=$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')
PWR=""

case "$level" in
    pitmode) PWR=250  ;;                      #  2.5 dBm
    low)     PWR=750  ;;                      # 10.0 dBm
    medium)  PWR=1500 ;;                      # 20.0 dBm
    high)    PWR=2500 ;;                      # 30.0 dBm
    tx_power)
        [ -z "$2" ] && { echo "tx_power needs <50‑3150>" >&2; exit 1; }
        printf '%s\n' "$2" | grep -Eq '^[0-9]+$' || {
            echo "tx_power value must be an integer" >&2; exit 1; }
        [ "$2" -lt 50 ] || [ "$2" -gt 3150 ] && {
            echo "tx_power out of range (50‑3150)" >&2; exit 1; }
        PWR="$2"
        ;;
    get_current)
        cur=$(iw dev wlan0 info 2>/dev/null | awk '/txpower/ {print $(NF-1); exit}')
        [ -z "$cur" ] && cur=$(iw dev | awk '/txpower/ {print $(NF-1); exit}')
        [ -z "$cur" ] && { echo "N/A" >&2; exit 1; }
        cur=${cur#-}                                      # strip minus sign
        mbm=$(awk "BEGIN {printf \"%d\", $cur*100}")
        echo "$mbm"
        exit 0
        ;;
    *)
        echo "Unknown level: $1" >&2
        echo "Usage: $0 Pitmode|Low|Medium|High|tx_power <50‑3150>|get_current" >&2
        exit 1 ;;
esac

###############################################################################
# Driver‑specific fixed value
###############################################################################
fw_setenv wlanpwr "$PWR"           # remember original mBm request

TXPWR="$PWR"
#if [ "$driver" = "88XXau" ]; then
#    adj=$PWR
#    [ "$PWR" -gt 1999 ] && adj=$(( PWR - 500 ))
#    TXPWR=$(( -2 * adj ))
#fi

###############################################################################
# Apply settings
###############################################################################
iw dev wlan0 set txpower fixed "$TXPWR"
iw dev wlan0 set txpower limit "$PWR"    # always write limit, even for 88XXau

###############################################################################
# Log/output: convert requested mBm → percentage of 0‑3250
###############################################################################
pct=$(( PWR * 100 / 3250 ))
echo "Power set: ${pct}%    (requested ${PWR} TX value)" | tee /tmp/webui.log
exit 0
