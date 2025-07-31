#!/bin/sh
#
# set_externalosd.sh enabled|disabled|status
# Auto‑detects adapter (rtl8812au|rtl8812eu|rtl8733bu), updates configs,
# reloads/starts/stops daemons, or reports current external‑OSD status.

CONF_OSD=/etc/antennaosd.conf
CONF_AA=/etc/aalink.conf
LOG=/tmp/webui.log

usage() {
    MSG="Usage: $0 enabled|disabled|status"
    echo "$MSG"
    echo "$MSG" > "$LOG"
    exit 1
}

# Initialize message collector
OUTPUT_MSG=""

# parse args
[ $# -eq 1 ] || usage
CMD="$1"
[ "$CMD" = "enabled" ] || [ "$CMD" = "disabled" ] || [ "$CMD" = "status" ] || usage

# status-only
if [ "$CMD" = "status" ]; then
    val=$(grep -E '^[[:space:]]*EXTERNAL_OSD=' "$CONF_AA" 2>/dev/null | tail -n1 | cut -d= -f2)
    if [ "$val" = "1" ]; then
        OUTPUT_MSG="true"
        echo "$OUTPUT_MSG"
        echo "$OUTPUT_MSG" > "$LOG"
        exit 0
    else
        OUTPUT_MSG="false"
        echo "$OUTPUT_MSG"
        echo "$OUTPUT_MSG" > "$LOG"
        exit 1
    fi
fi

STATE="$CMD"  # enabled or disabled

OUTPUT_MSG="Setting external OSD: $STATE\n"

# detect adapter
for a in rtl8812au rtl88x2eu rtl8733bu; do
    if [ -f "/proc/net/${a}/wlan0/trx_info_debug" ]; then
        ADAPTER="$a"
        break
    fi
done
if [ -z "$ADAPTER" ]; then
    OUTPUT_MSG="${OUTPUT_MSG}Error: no known adapter found under /proc/net\n"
    echo "$OUTPUT_MSG"
    echo "$OUTPUT_MSG" > "$LOG"
    exit 2
fi

# helper to delete existing keys
del_key() {
    key="$1"
    file="$2"
    sed -i "/^[[:space:]]*${key}[[:space:]]*=/d" "$file"
}

# update antennaosd.conf
for k in ping_enable info_file rssi_key curr_tx_rate_key curr_tx_bw_key rssi_udp_enable rssi_udp_key; do
    del_key "$k" "$CONF_OSD"
done

if [ "$STATE" = "enabled" ]; then
cat <<EOF >> "$CONF_OSD"
ping_enable = 0
info_file = /tmp/aalink_ext.msg
rssi_key = rssi_local
curr_tx_rate_key = mcs
curr_tx_bw_key = width
rssi_udp_enable = 0
rssi_udp_key =
EOF
else
cat <<EOF >> "$CONF_OSD"
ping_enable = 1
info_file = /proc/net/${ADAPTER}/wlan0/trx_info_debug
rssi_key =rssi
curr_tx_rate_key =curr_tx_rate
curr_tx_bw_key =curr_tx_bw
rssi_udp_enable = 0
rssi_udp_key =
EOF
fi

# update aalink.conf
for k in OSD_LEVEL EXTERNAL_OSD; do
    del_key "$k" "$CONF_AA"
done

if [ "$STATE" = "enabled" ]; then
cat <<EOF >> "$CONF_AA"
OSD_LEVEL=0
EXTERNAL_OSD=1
EOF
else
cat <<EOF >> "$CONF_AA"
OSD_LEVEL=3
EXTERNAL_OSD=0
EOF
fi

# reload/start/stop daemons
if pidof aalink >/dev/null 2>&1; then
    kill -1 "$(pidof aalink)" 2>/dev/null || true
else
    aalink >/dev/null 2>&1 &
fi

if [ "$STATE" = "enabled" ]; then
    OUTPUT_MSG="${OUTPUT_MSG}External OSD enabled - starting antenna_osd...\n"
    if pidof antenna_osd >/dev/null 2>&1; then
        kill -1 "$(pidof antenna_osd)" 2>/dev/null || true
    else
        antenna_osd >/dev/null 2>&1 &
    fi
else
    OUTPUT_MSG="${OUTPUT_MSG}External OSD disabled - stopping antenna_osd...\n"
    if pidof antenna_osd >/dev/null 2>&1; then
        kill "$(pidof antenna_osd)" 2>/dev/null || true
    fi
fi

# Final output to log and stdout
echo -e "$OUTPUT_MSG"
echo -e "$OUTPUT_MSG" > "$LOG"

exit 0
