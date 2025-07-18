#!/bin/sh
# gs_cmd.sh  ping | toggle_rec | shutdown_vrx

set -o pipefail

LOG=/tmp/webui.log
MASTER_IP=$(fw_printenv -n master_ip 2>/dev/null) || exit 1

DB="dbclient -i /root/.ssh/id_rsa -y -T"
TIMEOUT=10

case "$1" in
  vrx_ping)
    {
      printf '▶  Pinging %s …\n' "$MASTER_IP"
      ping -c 5 -A "$MASTER_IP"
    } 2>&1 | tee "$LOG"
    ;;

  vrx_toggle_rec)
    {
      printf '▶  Toggling recording on %s …\n' "$MASTER_IP"

      if ! timeout "$TIMEOUT" \
           $DB root@"$MASTER_IP" \
           "kill -SIGUSR1 \$(pidof pixelpilot)"; then
        echo "❌  dbclient failed (key missing?). Generate a key with dropbear_setup.sh on the VTX."
        exit 1
      fi
    } 2>&1 | tee "$LOG"
    ;;

  vrx_shutdown)
    {
      printf '▶  Shutting down VRX on %s …\n' "$MASTER_IP"

      if ! timeout "$TIMEOUT" \
           $DB root@"$MASTER_IP" \
           "shutdown now"; then
        echo "❌  shutdown command failed"
        exit 1
      fi
    } 2>&1 | tee "$LOG"
    ;;

  aalink_signalbar_enable)
    {
      printf '▶  Enabling signal bars ...\n'
      #logic

    } 2>&1 | tee "$LOG"
    ;;

    aalink_signalbar_disable)
    {
      printf '▶  Disabling signal bars ...\n'
      #logic

    } 2>&1 | tee "$LOG"
    ;;
    
    aalink_osd_level)
    {
      printf '▶  Setting OSD level %s ...\n' "$2"
      #logic

    } 2>&1 | tee "$LOG"
    ;;

    aalink_font_size)
    {
      printf '▶  Setting OSD font size to %s ...\n' "$2"
      #logic

    } 2>&1 | tee "$LOG"
    ;;


    aalink_mcs_source)
    {
      printf '▶  Setting MCS source %s ...\n' "$2"
      #logic

    } 2>&1 | tee "$LOG"
    ;;


  *)
    echo "Usage: $0 {vrx_ping|vrx_toggle_rec|vrx_shutdown_vrx}" | tee "$LOG"
    exit 1
    ;;
esac
