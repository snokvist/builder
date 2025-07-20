#!/bin/sh
# aplink.sh – manage /etc/ap_alink.conf one value at a time
#   print                       → show file
#   <key> <value>               → set value

CONF=/etc/ap_alink.conf
LOG=/tmp/webui.log

case "$1" in
    #####################################################################
    # PRINT MODE
    #####################################################################
    print)
        {  # everything inside braces goes through tee → $LOG
            if [ -f "$CONF" ]; then
                cat "$CONF"
            else
                echo "(!) $CONF not found"
            fi
        } | tee "$LOG"
        ;;

    #####################################################################
    # SET MODE  –  handle one key/value pair
    #####################################################################
    bitrate_max|bitrate_min|dbmMax|dbmMin|autoPower)
        [ -z "$2" ] && { echo "usage: $0 $1 <value>" | tee "$LOG"; exit 1; }

        KEY=$1
        VAL=$2
        ESC=$(printf '%s\n' "$VAL" | sed 's/[\/&]/\\&/g')   # escape for sed

        {  # everything inside braces goes through tee → $LOG
            echo "==> Setting $KEY to $VAL"
            if grep -q "^${KEY}=" "$CONF" 2>/dev/null; then
                sed -i "s|^${KEY}=.*|${KEY}=${ESC}|" "$CONF"
                echo "(updated existing line)"
            else
                echo "${KEY}=${VAL}" >> "$CONF"
                echo "(added new line)"
            fi
            echo "Done."
        } | tee "$LOG"
        ;;

    #####################################################################
    # UNKNOWN ARGUMENT
    #####################################################################
    *)
        echo "usage: $0 print  |  $0 <bitrate_max|bitrate_min|dbmMax|dbmMin|autoPower> <value>" | tee "$LOG"
        exit 1
        ;;
esac
