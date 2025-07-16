#!/bin/sh
# gs_cmd.sh  ping | toggle_rec
LOG=/tmp/webui.log
MASTER_IP="$(fw_printenv -n master_ip 2>/dev/null)" || exit 1

DB="dbclient -i /root/.ssh/id_rsa -y -T"   # -T = no‑pty, perfect for 1‑shot cmds
TIMEOUT=10                                  # seconds

case "$1" in
  ping)
    echo "▶  Pinging $MASTER_IP …" | tee -a "$LOG"
    ping -c 5 -A "$MASTER_IP" 2>&1 | tee "$LOG"
    ;;

  toggle_rec)
    echo "▶  Toggling recording on $MASTER_IP …" | tee "$LOG"
    if ! timeout "$TIMEOUT" \
         $DB root@"$MASTER_IP" \
         "kill -SIGUSR1 \$(pidof pixelpilot)" 2>&1 | tee "$LOG"
    then
      echo "❌  dbclient failed (key missing?)" | tee "$LOG"
      exit 1
    fi
    ;;

  *)  echo "Usage: $0 {ping|toggle_rec}" | tee "$LOG"; exit 1 ;;
esac
