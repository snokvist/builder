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

[ -z "$driver" ]       && { echo "Wireless module not detected!"; exit 1; }
[ "$driver" != "8812eu" ] && { echo "$driver currently not supported"; exit 1; }

# ── Keep-alive ping (every 0.1 s) ──────────────────────────────────
ping -i 0.1 192.168.0.10 >/dev/null 2>&1 &
PING_PID=$!
cleanup() { kill "$PING_PID" 2>/dev/null || true; exit; }
trap cleanup INT TERM EXIT

# ── Constants ──────────────────────────────────────────────────────
IF=wlan0
RATE=/proc/net/rtl88x2eu/$IF/rate_ctl
API="wget -qO- 'http://127.0.0.1/api/v1/set?video0.bitrate=%d'"

THR="-90 -85 -80 -70 -60 -30 -20 -10"
PR="6500 13000 19500 26000 39000 52000 58500 65000"

HYST=2
mcs=0
cnt=0

# ── Helper functions ───────────────────────────────────────────────
rssi() { iw dev "$IF" station dump 2>/dev/null | awk '/signal:/ {print $2; exit}'; }
get()  { echo "$1" | cut -d' ' -f$(($2 + 1)); }

# ── Main control loop ──────────────────────────────────────────────
while :; do
  s=$(rssi) || { sleep 0.1; continue; }
  printf '%s\n' "$s" | grep -qE '^-?[0-9]+$' || { sleep 0.1; continue; }

  next=$mcs
  thr_up=$(get "$THR" $((mcs + 1))) && up_th=$((thr_up + HYST))
  thr_cur=$(get "$THR" $mcs)        && dn_th=$((thr_cur - HYST))

  [ "$mcs" -lt 7 ] && [ "$s" -gt "$up_th" ] && next=$((mcs + 1))
  [ "$s" -lt "$dn_th" ]                      && next=$((mcs - 1))

  if [ "$next" -ne "$mcs" ]; then
    pr=$(get "$PR" $next)
    kb=$((pr * 2 / 3))
    code=$(printf "0x%X" $((0x68C + next)))

    if [ "$next" -gt "$mcs" ]; then
      printf "%s\n" "$code" >"$RATE"; sleep 0.05
      eval "$(printf "$API" "$kb")" >/dev/null
    else
      eval "$(printf "$API" "$kb")" >/dev/null
      sleep 0.05; printf "%s\n" "$code" >"$RATE"
    fi
    mcs=$next
  fi

  if [ $((cnt % 5)) -eq 0 ]; then
    echo "&L31&F20 MCS:$next | target:$(awk -v k="$kb" 'BEGIN{printf("%.1f",k/1000)}')Mb | actual:&B | CPU:&C,&Tc | TX:&Wc&G8 | uplink-rssi:$s" \
      > /tmp/MSPOSD.msg
  fi

  cnt=$((cnt + 1))
  sleep 0.1
done
