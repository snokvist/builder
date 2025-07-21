#!/bin/sh
# aplink.sh – manage /etc/ap_alink.conf one value at a time
# Commands:
#   print                          → show current config
#   reload                         → stop / start the service
#   <key> <value>                  → set value then reload
#
# Valid keys:  bitrate_max bitrate_min dbmMax dbmMin autoPower

CONF=/etc/ap_alink.conf
LOG=/tmp/webui.log
SERVICE=/etc/init.d/S996ap_alink

reload_service() {
    echo "==> Reloading ap_alink service"
    if [ ! -x "$SERVICE" ]; then
        echo "(!) $SERVICE missing or not executable"
        return
    fi
    echo "   • stopping …"
    "$SERVICE" stop
    sleep 1
    echo "   • starting …"
    "$SERVICE" start
    echo "(reload complete)"
}

usage() {
    echo "usage:"
    echo "  $0 print"
    echo "  $0 reload"
    echo "  $0 <bitrate_max|bitrate_min|dbmMax|dbmMin|autoPower> <value>"
}

case "$1" in
###########################################################################
# PRINT MODE
###########################################################################
print)
    { if [ -f "$CONF" ]; then
          cat "$CONF"
      else
          echo "(!) $CONF not found"
      fi; } | tee "$LOG"
    ;;

###########################################################################
# RELOAD MODE (manual call)
###########################################################################
reload)
    { reload_service; } | tee "$LOG"
    ;;

###########################################################################
# SET MODE – one key/value pair, then auto-reload
###########################################################################
bitrate_max|bitrate_min|dbmMax|dbmMin|autoPower)
    [ -z "$2" ] && { usage | tee "$LOG"; exit 1; }

    KEY=$1
    VAL=$2
    ESC=$(printf '%s\n' "$VAL" | sed 's/[\/&]/\\&/g')   # escape for sed

    {   echo "==> Setting $KEY to $VAL"
        if grep -q "^${KEY}=" "$CONF" 2>/dev/null; then
            sed -i "s|^${KEY}=.*|${KEY}=${ESC}|" "$CONF"
            echo "(updated existing line)"
        else
            echo "${KEY}=${VAL}" >> "$CONF"
            echo "(added new line)"
        fi
        reload_service
    } | tee "$LOG"
    ;;

###########################################################################
# UNKNOWN ARGUMENT
###########################################################################
*)
    usage | tee "$LOG"
    exit 1
    ;;
esac
