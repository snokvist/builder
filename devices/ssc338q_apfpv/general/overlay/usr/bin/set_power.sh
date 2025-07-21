#!/bin/sh
# Set Wi-Fi TX power.
# - Presets:  Pitmode, Low, Medium, High     (same as before)
# - Manual:   tx_power <mBm 50-3150>         e.g.  tx_power 1234
#   (mBm = dBm × 100, so 2000 mBm = 20 dBm)

###############################################################################
# Detect driver
###############################################################################
driver=
for card in $(lsusb | awk '{print $6}' | uniq); do
    case "$card" in
        "0bda:8812" | "0bda:881a" | "0b05:17d2" | "2357:0101" | "2604:0012")
            driver=88XXau ;;        # Realtek 8812au/8821au etc.
        "0bda:a81a")
            driver=8812eu ;;
        "0bda:f72b" | "0bda:b733")
            driver=8733bu ;;
    esac
done

###############################################################################
# Translate CLI input to numeric mBm (PWR)
###############################################################################
if [ $# -eq 0 ]; then
    echo "Usage:"
    echo "  $0 Pitmode|Low|Medium|High"
    echo "  $0 tx_power <50-3150>"
    exit 1
fi

level=$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')
PWR=""

case "$level" in
    pitmode) PWR=250  ;;      #  2.5 dBm
    low)     PWR=750  ;;      # 10.0 dBm
    medium)  PWR=1500 ;;      # 20.0 dBm
    high)    PWR=2500 ;;      # 30.0 dBm
    tx_power)
        # Expect second argument = raw mBm integer
        if [ -z "$2" ]; then
            echo "tx_power requires a numeric argument (50-3150)" >&2; exit 1
        fi
        if ! printf '%s' "$2" | grep -Eq '^[0-9]+$'; then
            echo "tx_power value must be an integer (mBm)" >&2; exit 1
        fi
        if [ "$2" -lt 50 ] || [ "$2" -gt 3150 ]; then
            echo "tx_power value out of range (50-3150 mBm)" >&2; exit 1
        fi
        PWR="$2"
        ;;
    *)
        echo "Unknown level: $1" >&2
        echo "Usage: $0 Pitmode|Low|Medium|High|tx_power <50-3150>" >&2
        exit 1 ;;
esac

###############################################################################
# Calculate driver-specific fixed value
###############################################################################
fw_setenv wlanpwr "$PWR"      # store original value in U-Boot env

TXPWR="$PWR"                  # default = raw value
if [ "$driver" = "88XXau" ]; then
    # 88XXau wants:   if >1999 subtract 500, then -2 × value
    if [ "$PWR" -gt 1999 ]; then
        adj=$(( PWR - 500 ))
    else
        adj=$PWR
    fi
    TXPWR=$(( -2 * adj ))
fi

###############################################################################
# Apply settings
###############################################################################
iw dev wlan0 set txpower fixed "$TXPWR"

# Always write the power limit (including 88XXau)
iw dev wlan0 set txpower limit "$PWR"

echo "Power set: ${TXPWR} (mBm)  [requested ${PWR} mBm]" | tee /tmp/webui.log
exit 0
