#!/bin/sh
# aplink.sh  –  minimal /etc/ap_alink.conf helper
# Usage:
#   aplink.sh print
#   aplink.sh <bitrate_max|bitrate_min|dbmMax|dbmMin|autoPower> <value>

CONF=/etc/ap_alink.conf
LOG=/tmp/webui.log

case "$1" in
    print)
        [ -f "$CONF" ] && cat "$CONF" | tee "$LOG"
        exit
        ;;

    bitrate_max|bitrate_min|dbmMax|dbmMin|autoPower)
        [ -z "$2" ] && { echo "missing value"; exit 1; }

        KEY=$1
        VAL=$2

        # change if present, else append
        if grep -q "^${KEY}=" "$CONF" 2>/dev/null; then
            sed -i "s|^${KEY}=.*|${KEY}=${VAL}|" "$CONF"
        else
            echo "${KEY}=${VAL}" >> "$CONF"
        fi

        echo "${KEY}=${VAL}"         # confirmation to stdout
        ;;

    *)
        echo "usage: $0 print | $0 <key> <value>" >&2
        exit 1
        ;;
esac
