#!/bin/sh
# gs_cmd.sh  ping | toggle_rec | shutdown_vrx

set -o pipefail

LOG=/tmp/webui.log
MASTER_IP=$(fw_printenv -n master_ip 2>/dev/null) || exit 1

DB="sshpass -p root ssh -y"
TIMEOUT=5

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
       $DB root@"$MASTER_IP" 'kill -SIGUSR1 $(pidof pixelpilot)'; then
    echo "❌  ssh failed ..."
    exit 1
  fi
    } 2>&1 | tee "$LOG"
    ;;

  vrx_shutdown)
    {
      printf '▶  Shutting down VRX on %s …\n' "$MASTER_IP"

    if ! timeout "$TIMEOUT" \
       $DB root@"$MASTER_IP" 'shutdown now'; then
    echo "❌  ssh failed ..."
    exit 1
  fi
    } 2>&1 | tee "$LOG"
    ;;

  aalink_signalbar_enable)
    {
      printf '▶  Enabling signal bars ...\n'
      sed -i.bak 's|^SHOW_SIGNAL_BARS=.*|SHOW_SIGNAL_BARS=true|' /etc/aalink.conf
      kill -SIGHUP $(pidof aalink) 2>/dev/null

    } 2>&1 | tee "$LOG"
    ;;

    aalink_signalbar_disable)
    {
      printf '▶  Disabling signal bars ...\n'
      sed -i.bak 's|^SHOW_SIGNAL_BARS=.*|SHOW_SIGNAL_BARS=false|' /etc/aalink.conf
      kill -SIGHUP $(pidof aalink) 2>/dev/null

    } 2>&1 | tee "$LOG"
    ;;
    
    aalink_osd_level)
    {
      
      printf '▶  Setting OSD level %s ...\n' "$2"
      val=$2
      sed -i.bak "s|^OSD_LEVEL=.*|OSD_LEVEL=${val}|" /etc/aalink.conf
      kill -SIGHUP $(pidof aalink) 2>/dev/null

    } 2>&1 | tee "$LOG"
    ;;

    aalink_ip_dest)
    {
      
      printf '▶  Setting MASTER IP to %s ...\n' "$2"
      val=$2
      sed -i.bak "s|^PING_DEST=.*|PING_DEST=${val}|" /etc/aalink.conf
      kill -SIGHUP $(pidof aalink) 2>/dev/null

    } 2>&1 | tee "$LOG"
    ;;

    

    aalink_font_size)
    {
      printf '▶  Setting OSD font size to %s ...\n' "$2"
      sed -i.bak -E "s|^(OSD_PARAMS=.*&F)[0-9]+|\1$2|" /etc/aalink.conf
      kill -SIGHUP $(pidof aalink) 2>/dev/null

    } 2>&1 | tee "$LOG"
    ;;


    aalink_mcs_source)
    {
      val=$2
      printf '▶  Setting MCS source %s ...\n' "$2"
      sed -i.bak "s|^MCS_SOURCE=.*|MCS_SOURCE=${2}|" /etc/aalink.conf
      kill -SIGHUP $(pidof aalink) 2>/dev/null

    } 2>&1 | tee "$LOG"
    ;;

    aalink_throughput)
    {
      val=$2
      printf '▶  Setting throughput to %s ...\n' "$2"
      sed -i.bak "s|^THROUGHPUT_PCT=.*|THROUGHPUT_PCT=${2}|" /etc/aalink.conf
      kill -SIGHUP $(pidof aalink) 2>/dev/null

    } 2>&1 | tee "$LOG"
    ;;


    aalink_print_settings)
    {
      printf '▶  aalink Settings ...\n'
      echo "MCS RSSI Source: $(sed -n 's/^MCS_SOURCE=\(.*\)/\1/p' /etc/aalink.conf)"
      echo "Font size: $(sed -n -E 's|^OSD_PARAMS=.*&F([0-9]+).*|\1|p' /etc/aalink.conf)"
      echo "OSD level: $(sed -n 's/^OSD_LEVEL=\(.*\)/\1/p' /etc/aalink.conf)"
      echo "Show signal bars: $(sed -n 's/^SHOW_SIGNAL_BARS=\(.*\)/\1/p' /etc/aalink.conf)"
      echo "Throughput %: $(sed -n 's/^THROUGHPUT_PCT=\(.*\)/\1/p' /etc/aalink.conf)"

    } 2>&1 | tee "$LOG"
    ;;


  *)
        echo "Usage: $0 {vrx_ping|vrx_toggle_rec|vrx_shutdown|aalink_signalbar_enable|aalink_signalbar_disable|aalink_osd_level <level>|aalink_font_size <size>|aalink_mcs_source <source>|aalink_print_settings}" | tee "$LOG"; exit 1

    exit 1
    ;;
esac
