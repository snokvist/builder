#!/bin/sh
# gs_cmd.sh  ping | toggle_rec

set -o pipefail               # propagate errors through the single pipeline

LOG=/tmp/webui.log
MASTER_IP=$(fw_printenv -n master_ip 2>/dev/null) || exit 1

DB="dbclient -i /root/.ssh/id_rsa -y -T"    # -T = no-pty, perfect for 1-shot cmds
TIMEOUT=10                                  # seconds

case "$1" in
  ping)
    {
      printf '▶  Pinging %s …\n' "$MASTER_IP"
      ping -c 5 -A "$MASTER_IP"
    } 2>&1 | tee "$LOG"
    ;;

  toggle_rec)
    {
      printf '▶  Toggling recording on %s …\n' "$MASTER_IP"

      if ! timeout "$TIMEOUT" \
           $DB root@"$MASTER_IP" \
           "kill -SIGUSR1 \$(pidof pixelpilot)"; then
        echo "❌  dbclient failed (key missing?). Generate new key with "dropbear_setup.sh on VTX."
        exit 1
      fi
    } 2>&1 | tee "$LOG"
    ;;

  *)
    echo "Usage: $0 {ping|toggle_rec}" | tee "$LOG"
    exit 1
    ;;
esac
