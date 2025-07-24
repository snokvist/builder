#!/bin/sh
#
# set_externalosd.sh enabled|disabled
# Auto‑detects adapter and updates configs, then reloads/starts/stops daemons.

CONF_OSD=/etc/antennaosd.conf
CONF_AA=/etc/aalink.conf

usage() {
    echo "Usage: $0 enabled|disabled"
    exit 1
}

# --- parse args ---
[ $# -eq 1 ] || usage
STATE="$1"
[ "$STATE" = "enable" ] || [ "$STATE" = "disable" ] || usage

# --- detect adapter ---
for a in rtl8812au rtl88x2eu rtl8733bu; do
    if [ -f "/proc/net/${a}/wlan0/trx_info_debug" ]; then
        ADAPTER="$a"
        break
    fi
done
if [ -z "$ADAPTER" ]; then
    echo "Error: no known adapter found under /proc/net" >&2
    exit 2
fi

# --- helper: delete any existing lines for a key ---
del_key() {
    key="$1"
    sed -i "/^[[:space:]]*${key}[[:space:]]*=/d" "$2"
}

# --- update antennaosd.conf ---
for k in ping_enable info_file rssi_key curr_tx_rate_key curr_tx_bw_key rssi_udp_enable rssi_udp_key; do
    del_key "$k" "$CONF_OSD"
done

if [ "$STATE" = "enabled" ]; then
    cat <<EOF >> "$CONF_OSD"
ping_enable = 0
info_file = /tmp/aalink_ext.msg
rssi_key = used_rssi
curr_tx_rate_key = mcs
curr_tx_bw_key = mcs
rssi_udp_enable = 1
rssi_udp_key = rssi_udp
EOF
else
    cat <<EOF >> "$CONF_OSD"
ping_enable = 1
info_file = /proc/net/${ADAPTER}/wlan0/trx_info_debug
rssi_key =
curr_tx_rate_key =
curr_tx_bw_key =
rssi_udp_enable = 0
rssi_udp_key =
EOF
fi

# --- update aalink.conf ---
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

# --- reload / start / stop daemons ---
# Always ensure aalink is running (reload if already)
if pidof aalink >/dev/null 2>&1; then
    kill -1 "$(pidof aalink)" 2>/dev/null || true
else
    aalink >/dev/null 2>&1 &
fi

if [ "$STATE" = "enabled" ]; then
    if pidof antenna_osd >/dev/null 2>&1; then
        kill -1 "$(pidof antenna_osd)" 2>/dev/null || true
    else
        antenna_osd >/dev/null 2>&1 &
    fi
else
    if pidof antenna_osd >/dev/null 2>&1; then
        kill "$(pidof antenna_osd)" 2>/dev/null || true
    fi
fi

exit 0
