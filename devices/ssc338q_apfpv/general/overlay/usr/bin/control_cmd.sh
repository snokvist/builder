#!/bin/sh
# control_cmd.sh  – utility for VRX / aalink management
#
# Actions:
#   vrx_ping | vrx_toggle_rec | vrx_shutdown
#   aalink_signalbar_enable  | aalink_signalbar_disable
#   aalink_osd_level   <level>
#   aalink_font_size   <size>
#   aalink_mcs_source  <source>
#   aalink_throughput  <percent>
#   aalink_ip_dest     <ip>
#   aalink_print_settings

LOG=/tmp/webui.log

# ────────────────────────────────────────────────────────────────────
# Obtain MASTER_IP; fall back to 192.168.0.10 when it isn’t in U‑Boot.
MASTER_IP=$(fw_printenv -n master_ip 2>/dev/null || true)
[ -n "$MASTER_IP" ] || MASTER_IP=192.168.0.10

DB="sshpass -p root ssh -y"
TIMEOUT=5
# ────────────────────────────────────────────────────────────────────

case "$1" in
# ===== VRX commands ==================================================
  vtx_start_adapter)
    {
      printf '▶  (RE)Starting adapter …\n'
      adapter start
    } 2>&1 | tee "$LOG"
    ;;

  vtx_stop_udhcpd)
    {
      printf '▶  Killing udhcpd …\n'
      kill -9 $(pidof udhcpd) 
    } 2>&1 | tee "$LOG"
    ;;
    
  vtx_reload_majestic)
    {
      printf '▶  Reloading majestic %s …\n'
      kill -1 $(pidof majestic) 
    } 2>&1 | tee "$LOG"
    ;;
  
  
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
        echo "❌  ssh failed …"
        exit 1
      fi
    } 2>&1 | tee "$LOG"
    ;;

  vrx_shutdown)
    {
      printf '▶  Shutting down VRX on %s …\n' "$MASTER_IP"
      if ! timeout "$TIMEOUT" \
           $DB root@"$MASTER_IP" 'shutdown now'; then
        echo "❌  ssh failed …"
        exit 1
      fi
    } 2>&1 | tee "$LOG"
    ;;

# ===== aalink simple switches =======================================
  aalink_signalbar_enable)
    {
      printf '▶  Enabling signal bars …\n'
      sed -i.bak 's|^SHOW_SIGNAL_BARS=.*|SHOW_SIGNAL_BARS=true|' /etc/aalink.conf
      kill -SIGHUP "$(pidof aalink)" 2>/dev/null
    } 2>&1 | tee "$LOG"
    ;;

  aalink_signalbar_disable)
    {
      printf '▶  Disabling signal bars …\n'
      sed -i.bak 's|^SHOW_SIGNAL_BARS=.*|SHOW_SIGNAL_BARS=false|' /etc/aalink.conf
      kill -SIGHUP "$(pidof aalink)" 2>/dev/null
    } 2>&1 | tee "$LOG"
    ;;

# ===== aalink commands that require a value =========================
  aalink_osd_level)
    {
      [ -n "$2" ] || { echo "❌  Missing <level>"; exit 1; }
      printf '▶  Setting OSD level to %s …\n' "$2"
      sed -i.bak "s|^OSD_LEVEL=.*|OSD_LEVEL=$2|" /etc/aalink.conf
      kill -SIGHUP "$(pidof aalink)" 2>/dev/null
    } 2>&1 | tee "$LOG"
    ;;

  aalink_font_size)
    {
      [ -n "$2" ] || { echo "❌  Missing <size>"; exit 1; }
      printf '▶  Setting OSD font size to %s …\n' "$2"
      sed -i.bak -E "s|^(OSD_PARAMS=.*&F)[0-9]+|\1$2|" /etc/aalink.conf
      kill -SIGHUP "$(pidof aalink)" 2>/dev/null
    } 2>&1 | tee "$LOG"
    ;;

  aalink_mcs_source)
    {
      [ -n "$2" ] || { echo "❌  Missing <source>"; exit 1; }
      printf '▶  Setting MCS source to %s …\n' "$2"
      sed -i.bak "s|^MCS_SOURCE=.*|MCS_SOURCE=$2|" /etc/aalink.conf
      kill -SIGHUP "$(pidof aalink)" 2>/dev/null
    } 2>&1 | tee "$LOG"
    ;;

  aalink_throughput)
    {
      [ -n "$2" ] || { echo "❌  Missing <percent>"; exit 1; }
      printf '▶  Setting throughput to %s%% …\n' "$2"
      sed -i.bak "s|^THROUGHPUT_PCT=.*|THROUGHPUT_PCT=$2|" /etc/aalink.conf
      kill -SIGHUP "$(pidof aalink)" 2>/dev/null
    } 2>&1 | tee "$LOG"
    ;;

  aalink_ip_dest)
    {
      [ -n "$2" ] || { echo "❌  Missing <ip>"; exit 1; }
      printf '▶  Setting MASTER IP to %s …\n' "$2"
      sed -i.bak "s|^PING_DEST=.*|PING_DEST=$2|" /etc/aalink.conf
      kill -SIGHUP "$(pidof aalink)" 2>/dev/null
    } 2>&1 | tee "$LOG"
    ;;

# ===== print aalink settings ========================================
  aalink_print_settings)
    {
      printf '▶  aalink Settings …\n'
      echo "MCS RSSI Source : $(sed -n 's/^MCS_SOURCE=\(.*\)/\1/p'          /etc/aalink.conf)"
      echo "Font size       : $(sed -n -E 's|^OSD_PARAMS=.*&F([0-9]+).*|\1|p' /etc/aalink.conf)"
      echo "OSD level       : $(sed -n 's/^OSD_LEVEL=\(.*\)/\1/p'            /etc/aalink.conf)"
      echo "Show signal bars: $(sed -n 's/^SHOW_SIGNAL_BARS=\(.*\)/\1/p'     /etc/aalink.conf)"
      echo "Throughput %    : $(sed -n 's/^THROUGHPUT_PCT=\(.*\)/\1/p'       /etc/aalink.conf)"
      echo "Ping destination: $(sed -n 's/^PING_DEST=\(.*\)/\1/p'            /etc/aalink.conf)"
      echo "-------------------------------"
      set_mcs.sh print
    } 2>&1 | tee "$LOG"
    ;;

# ===== everything else ==============================================
  *)
    {
      cat <<EOF
Usage: $0 {vrx_ping|vrx_toggle_rec|vrx_shutdown|aalink_signalbar_enable|\
aalink_signalbar_disable|aalink_osd_level <level>|aalink_font_size <size>|\
aalink_mcs_source <source>|aalink_throughput <percent>|aalink_ip_dest <ip>|\
aalink_print_settings}
EOF
      exit 1
    } 2>&1 | tee "$LOG"
    ;;
esac
