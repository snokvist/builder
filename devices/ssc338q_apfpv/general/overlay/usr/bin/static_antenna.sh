#!/bin/sh
# rssi_bar_16.sh – 16‑cell link‑quality bar + background ping
# BusyBox /bin/sh compatible
# ----------------------------------------------------------

# ---------- TUNE HERE ------------------------------------
INFO_FILE="/proc/net/rtl88x2eu/wlan0/trx_info_debug"
OUT_FILE="/tmp/MSPOSD.msg"

INTERVAL=0.1       # seconds between updates
BAR_WIDTH=30       # glyph cells in the bar
TOP=80             # % that fills the bar
BOTTOM=20          # % that empties the bar

OSD_HDR=' &F48&L20' # OSD control header
PING_IP="192.168.0.10"   # target to ping (leave empty to disable)

START='['          # left bracket of the bar
END=']'            # right bracket
EMPTY='.'          # glyph for unused cells (one byte)
# ----------------------------------------------------------

# UTF‑8 glyphs
GL_ANT=$(printf '\xEF\x80\x92')   #  antenna

FULL=$(printf  '\xE2\x96\x88')    # █
P1=$(printf    '\xE2\x96\x81')    # ▁
P2=$(printf    '\xE2\x96\x82')    # ▂
P3=$(printf    '\xE2\x96\x83')    # ▃
P4=$(printf    '\xE2\x96\x84')    # ▄
P5=$(printf    '\xE2\x96\x85')    # ▅
P6=$(printf    '\xE2\x96\x86')    # ▆
P7=$(printf    '\xE2\x96\x87')    # ▇
PARTIAL="$P1$P2$P3$P4$P5$P6$P7"

export LC_ALL=C.UTF-8

# ---------- start background ping ------------------------
if [ -n "$PING_IP" ]; then
    ping -i "$INTERVAL" "$PING_IP" >/dev/null 2>&1 &
    PING_PID=$!
    cleanup() { kill "$PING_PID" 2>/dev/null; exit; }
    trap cleanup INT TERM EXIT
fi
# ----------------------------------------------------------

while :; do
    # 1) read first link‑quality value
    Q=$(grep -m1 -E 'rssi[[:space:]]*:[[:space:]]*[0-9]+' "$INFO_FILE" \
        | sed -E 's/.*rssi[[:space:]]*:[[:space:]]*([0-9]+).*/\1/')
    [ -z "$Q" ] && Q=0

    # 2) clamp + linear scale
    if   [ "$Q" -le "$BOTTOM" ]; then PCT=0
    elif [ "$Q" -ge "$TOP"    ]; then PCT=100
    else PCT=$(( (Q - BOTTOM) * 100 / (TOP - BOTTOM) )); fi

    # 3) compute bar content
    EIG=$(( PCT * BAR_WIDTH * 8 / 100 ))
    FULLS=$(( EIG / 8 ))
    REM=$((  EIG % 8 ))

    BAR=''
    i=0
    while [ $i -lt $BAR_WIDTH ]; do
        if   [ $i -lt $FULLS ]; then
            BAR="$BAR$FULL"
        elif [ $i -eq $FULLS ] && [ $REM -gt 0 ]; then
            ofs=$(( (REM - 1) * 3 + 1 ))
            BAR="$BAR$(printf '%s' "$(echo "$PARTIAL" | cut -c $ofs-$((ofs+2)) )")"
            REM=0
        else
            BAR="$BAR$EMPTY"
        fi
        i=$((i+1))
    done

    # 4) write OSD message
    printf '%s%s %s%s%s %d%%\n' \
           "$OSD_HDR" "$GL_ANT" "$START" "$BAR" "$END" "$Q" > "$OUT_FILE"

    # 5) debug to stdout
    echo "DBG: raw=$Q%%  scaled=$PCT%%  bar='${START}${BAR}${END}'"

    sleep "$INTERVAL"
done
