#!/bin/sh

# failover.sh — unified DNAT-based video routing controller

# CONFIGURABLES
PLACEHOLDER_IP="192.168.0.254"
PORT="5600"
STA1_IP=""
STA2_IP=""
FAIL_THRESH=2
INTERVAL=2
STATE_FILE="/tmp/stream_target"
IPTABLES_CHAIN="OUTPUT"

# Helper: print usage
usage() {
  echo "Usage:"
  echo "  $0 init <STA1_IP> <STA2_IP>"
  echo "  $0 switch <STA1|STA2>"
  echo "  $0 watch"
  exit 1
}

# Helper: perform DNAT switch
do_switch() {
  TARGET_IP="$1"
  echo "[INFO] Switching DNAT to $TARGET_IP"
  iptables -t nat -R "$IPTABLES_CHAIN" 1 -p udp --dport "$PORT" -d "$PLACEHOLDER_IP" -j DNAT --to-destination "$TARGET_IP:$PORT"
  echo "$TARGET_IP" > "$STATE_FILE"
}

# --- Mode: init ---
if [ "$1" = "init" ]; then
  [ $# -ne 3 ] && usage
  STA1_IP="$2"
  STA2_IP="$3"

  # Save to file for later watch mode
  echo "$STA1_IP" > /tmp/sta1_ip
  echo "$STA2_IP" > /tmp/sta2_ip

  # Clear existing nat rule
  iptables -t nat -F "$IPTABLES_CHAIN"

  # Initial DNAT to STA1
  iptables -t nat -A "$IPTABLES_CHAIN" -p udp --dport "$PORT" -d "$PLACEHOLDER_IP" -j DNAT --to-destination "$STA1_IP:$PORT"
  echo "$STA1_IP" > "$STATE_FILE"

  echo "[OK] DNAT setup initialized. Now stream to udp://$PLACEHOLDER_IP:$PORT"
  exit 0
fi

# --- Mode: switch STA1/STA2 ---
if [ "$1" = "switch" ]; then
  [ $# -ne 2 ] && usage
  [ ! -f /tmp/sta1_ip ] && echo "Error: must run 'init' first" && exit 1

  case "$2" in
    STA1)
      do_switch "$(cat /tmp/sta1_ip)"
      ;;
    STA2)
      do_switch "$(cat /tmp/sta2_ip)"
      ;;
    *)
      echo "Error: must be STA1 or STA2"
      usage
      ;;
  esac
  exit 0
fi

# --- Mode: watch loop ---
if [ "$1" = "watch" ]; then
  [ ! -f /tmp/sta1_ip ] && echo "Error: must run 'init' first" && exit 1
  STA1_IP=$(cat /tmp/sta1_ip)
  STA2_IP=$(cat /tmp/sta2_ip)
  CUR=$(cat "$STATE_FILE" 2>/dev/null)

  fail1=0
  fail2=0

  while true; do
    ping -c1 -W1 "$STA1_IP" >/dev/null && fail1=0 || fail1=$((fail1+1))
    ping -c1 -W1 "$STA2_IP" >/dev/null && fail2=0 || fail2=$((fail2+1))

    if [ "$CUR" = "$STA1_IP" ] && [ $fail1 -ge $FAIL_THRESH ] && [ $fail2 -lt $FAIL_THRESH ]; then
      do_switch "$STA2_IP"
      CUR="$STA2_IP"
    elif [ "$CUR" = "$STA2_IP" ] && [ $fail2 -ge $FAIL_THRESH ] && [ $fail1 -lt $FAIL_THRESH ]; then
      do_switch "$STA1_IP"
      CUR="$STA1_IP"
    fi

    sleep "$INTERVAL"
  done
  exit 0
fi

# Fallback
usage
