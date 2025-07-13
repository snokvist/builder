#!/bin/sh
set -euo pipefail

# ── Driver detection ───────────────────────────────────────────────
driver=""
for card in $(lsusb | awk '{print $6}' | uniq); do
  case "$card" in
    0bda:8812|0bda:881a|0b05:17d2|2357:0101|2604:0012) driver=88XXau ;;
    0bda:a81a)                                         driver=8812eu ;;
    0bda:f72b|0bda:b733)                               driver=8733bu ;;
  esac
done

[ -z "$driver" ] && { echo "Wireless module not detected!"; exit 1; }
[ "$driver" != "8812eu" ] && { echo "$driver currently not supported"; exit 1; }

# ── Keep-alive ping (every 0.1 s) ─────────────────────────────────
ping -i 0.1 192.168.0.10 >/dev/null 2>&1 &
PING_PID=$!

cleanup() {
  kill "$PING_PID" 2>/dev/null || :
  exit
}
trap cleanup INT TERM EXIT

# ── Helper to read current channel width ────────────────────────────
get_width() {
  iw dev "$IF" info 2>/dev/null \
    | awk -F'width: ' '/width:/ { print $2+0; exit }'
}

IF=wlan0
RATE=/proc/net/rtl88x2eu/$IF/rate_ctl
API='wget -qO- "http://127.0.0.1/api/v1/set?video0.bitrate=%d"'

# Per-RSSI thresholds and bitrates

#THR='-90 -85 -77 -60 -13 -12 -11 -10'
#THR="-90 -85 -80 -70 -60 -30 -20 -10"

THR="-85 -80 -75 -65 -55 -10 -9 -8"

#THR="-90 -85 -80 -70 -60 -40 -10 -9"
PR='6500 13000 19500 26000 39000 52000 58500 65000'
H=2

# ── Wait for valid RSSI ────────────────────────────────────────────
rssi() {
  iw dev "$IF" station dump 2>/dev/null \
    | awk '/signal:/ {print $2; exit}'
}

echo "Waiting for valid RSSI…"
while ! s=$(rssi) || ! printf '%s\n' "$s" | grep -qE '^-?[0-9]+$' \
      || [ "$s" -ge -10 ] || [ "$s" -le -95 ]; do
  sleep .1
done
echo "Good RSSI: $s dBm"

# ── Initialize state ───────────────────────────────────────────────
m=0
c=0
width=$(get_width)

# ── Main loop ─────────────────────────────────────────────────────
while :; do
  s=$(rssi) || { sleep .1; continue; }
  [ "$(printf '%s\n' "$s" | grep -E '^-?[0-9]+$')" ] || { sleep .1; continue; }

  # every 5 seconds (≈50×0.1 s), refresh channel width
  if [ $((c % 50)) -eq 0 ]; then
    new_w=$(get_width)
    [ -n "$new_w" ] && width=$new_w
  fi

  up=$(echo "$THR" | awk -v n=$((m+1)) '{print $n}')
  dn=$(echo "$THR" | awk -v n=$((m+0)) '{print $n}')
  nu=$m
  [ $m -lt 7 ] && [ "$s" -gt $((up + H)) ] && nu=$((m+1))
  [ "$s" -lt $((dn - H)) ] && nu=$((m-1))

  if [ $nu -ne $m ]; then
    kb=$(( $(echo "$PR" | awk -v n=$((nu+1)) '{print $n}') * width / 40 ))
    code=$(printf "0x%X" $((0x00C + nu)))
    if [ $nu -gt $m ]; then
      printf "%s\n" "$code" >"$RATE"
      sleep .05
      eval "$(printf "$API" "$kb")" >/dev/null
    else
      eval "$(printf "$API" "$kb")" >/dev/null
      sleep .05
      printf "%s\n" "$code" >"$RATE"
    fi
    m=$nu
  fi

  # status update every 5 loops
  if [ $((c % 5)) -eq 0 ]; then
    echo "&L31&F20 $s | MCS:$m | $kb | &B | CPU:&C,&Tc | TX:&Wc&G8" \
      > /tmp/MSPOSD.msg
  fi

  c=$((c+1))
  sleep .1
done