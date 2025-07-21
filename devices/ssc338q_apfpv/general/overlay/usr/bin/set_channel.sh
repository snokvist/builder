#!/bin/sh
# ---------------------------------------------------------
# set_channel.sh – BusyBox‑compatible channel helper
# Updated: 2025‑07‑21  (log aggregation)
#
# * Supports **all** 5 GHz channels (36‑173) with 20 MHz and HT40 variants.
# * Aggregates every line of output into a temp file, then writes it
#   once to /tmp/webui.log (replacing the old log) when the script ends.
# * Verifies channel switch via `iw dev $IFACE info` before committing.
# * Keeps the original 88XXau “reboot required” fallback logic.
# ---------------------------------------------------------

############################################################################
# 0)  Logging – collect everything, flush on exit
############################################################################
LOG_TMP="$(mktemp)"            # buffer for the whole run

log() {                        # log "message …"
    printf '%s\n' "$*"         # show immediately on the console
    printf '%s\n' "$*" >> "$LOG_TMP"
}

finish() {                     # dump buffer → /tmp/webui.log (overwrite)
    cat "$LOG_TMP" | tee /tmp/webui.log
    rm -f "$LOG_TMP"
}
trap finish EXIT

############################################################################
# 1)  Detect the USB WLAN chipset → driver name
############################################################################
detect_driver() {
    for id in $(lsusb | awk '{print $6}' | uniq); do
        case "$id" in
            0bda:8812|0bda:881a|0b05:17d2|2357:0101|2604:0012) echo 88XXau && return ;;
            0bda:a81a)                                         echo 8812eu && return ;;
            0bda:f72b|0bda:b733)                               echo 8733bu && return ;;
        esac
    done
    echo unknown
}
DRIVER="$(detect_driver)"

############################################################################
# 2)  Constants
############################################################################
IFACE=wlan0
HOSTAPD_CLI="hostapd_cli -i $IFACE"
CS=5                                   # beacon delay for CSA
BW40="bandwidth=40 ht vht"             # CSA flags for HT40

############################################################################
# 3)  Helper – write channel to bootloader env (permanent)
############################################################################
permanent_set() {                      # $1 = primary channel number
    fw_setenv wlanchan "$1" 2>&1 | tee -a "$LOG_TMP"
    log "(fw_setenv wlanchan $1)"
}

############################################################################
# 4)  Helper – verify that channel really switched
############################################################################
verify_channel() {                     # $1 = expected primary channel
    iw dev "$IFACE" info 2>/dev/null | awk '/channel/ {print $2}' | grep -q "^$1$"
}

############################################################################
# 5)  Helper – perform the channel change with 88XXau‑aware logic
############################################################################
do_switch() {                          # $1 = hostapd_cli command, $2 = primary channel
    if [ "$DRIVER" = 88XXau ]; then
        log "Live channel change currently not supported for 88XXau."
        if [ "$PERM" = "--make-permanent" ]; then
            permanent_set "$2"
            log "Please reboot the device for the channel change to take effect."
        fi
        return
    fi

    eval "$1" 2>&1 | tee -a "$LOG_TMP"
    sleep 3   # give hostapd a moment to complete CSA

    if verify_channel "$2"; then
        log "Channel $2 successfully set."
        [ "$PERM" = "--make-permanent" ] && permanent_set "$2"
    else
        log "WARNING: Channel switch to $2 FAILED – keeping previous settings."
    fi
}

############################################################################
# 6)  Main dispatch
############################################################################
MODE="$1"
PERM="$2"   # optional --make-permanent

case "$MODE" in
################################################################################
# UNII‑1 – 36/40‑48
    ch36)      do_switch "$HOSTAPD_CLI chan_switch $CS 5180  sec_channel_offset=1 center_freq1=5190 $BW40" 36 ;;
    ch36-20)   do_switch "$HOSTAPD_CLI chan_switch $CS 5180"                                                    36 ;;
    ch40-20)   do_switch "$HOSTAPD_CLI chan_switch $CS 5200"                                                    40 ;;
    ch44)      do_switch "$HOSTAPD_CLI chan_switch $CS 5220  sec_channel_offset=1 center_freq1=5230 $BW40" 44 ;;
    ch44-20)   do_switch "$HOSTAPD_CLI chan_switch $CS 5220"                                                    44 ;;
    ch48-20)   do_switch "$HOSTAPD_CLI chan_switch $CS 5240"                                                    48 ;;

# UNII‑2A (DFS) – 52/56‑64
    ch52)      log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5260  sec_channel_offset=1 center_freq1=5270 $BW40" 52 ;;
    ch52-20)   log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5260"                                52 ;;
    ch56-20)   log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5280"                                56 ;;
    ch60)      log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5300  sec_channel_offset=1 center_freq1=5310 $BW40" 60 ;;
    ch60-20)   log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5300"                                60 ;;
    ch64-20)   log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5320"                                64 ;;

# UNII‑2C / UNII‑2‑Extended (DFS) – 100/104‑144
    ch100)     log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5500  sec_channel_offset=1 center_freq1=5510 $BW40" 100 ;;
    ch100-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5500"                                100 ;;
    ch104-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5520"                                104 ;;
    ch108)     log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5540  sec_channel_offset=1 center_freq1=5550 $BW40" 108 ;;
    ch108-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5540"                                108 ;;
    ch112-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5560"                                112 ;;
    ch116)     log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5580  sec_channel_offset=1 center_freq1=5590 $BW40" 116 ;;
    ch116-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5580"                                116 ;;
    ch120-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5600"                                120 ;;
    ch124)     log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5620  sec_channel_offset=1 center_freq1=5630 $BW40" 124 ;;
    ch124-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5620"                                124 ;;
    ch128-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5640"                                128 ;;
    ch132)     log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5660  sec_channel_offset=1 center_freq1=5670 $BW40" 132 ;;
    ch132-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5660"                                132 ;;
    ch136-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5680"                                136 ;;
    ch140)     log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5700  sec_channel_offset=1 center_freq1=5710 $BW40" 140 ;;
    ch140-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5700"                                140 ;;
    ch144-20)  log "DFS: CAC ~60 s…" ; do_switch "$HOSTAPD_CLI chan_switch $CS 5720"                                144 ;;

# UNII‑3 / UNII‑4 – 149/153‑165 and 169/173 (5.8‑6.0 GHz)
    ch149)     do_switch "$HOSTAPD_CLI chan_switch $CS 5745  sec_channel_offset=1 center_freq1=5755 $BW40" 149 ;;
    ch149-20)  do_switch "$HOSTAPD_CLI chan_switch $CS 5745"                                                    149 ;;
    ch153-20)  do_switch "$HOSTAPD_CLI chan_switch $CS 5765"                                                    153 ;;
    ch157)     do_switch "$HOSTAPD_CLI chan_switch $CS 5785  sec_channel_offset=1 center_freq1=5795 $BW40" 157 ;;
    ch157-20)  do_switch "$HOSTAPD_CLI chan_switch $CS 5785"                                                    157 ;;
    ch161-20)  do_switch "$HOSTAPD_CLI chan_switch $CS 5805"                                                    161 ;;
    ch165-20)  do_switch "$HOSTAPD_CLI chan_switch $CS 5825"                                                    165 ;;
    ch169)     do_switch "$HOSTAPD_CLI chan_switch $CS 5845  sec_channel_offset=1 center_freq1=5855 $BW40" 169 ;;
    ch169-20)  do_switch "$HOSTAPD_CLI chan_switch $CS 5845"                                                    169 ;;
    ch173-20)  do_switch "$HOSTAPD_CLI chan_switch $CS 5865"                                                    173 ;;
################################################################################
    *)
        log "Usage: $0 <channel‑mode> [--make-permanent]

Channel modes (20 MHz unless *‑20* is appended):
  ch36  ch40-20  ch44  ch48-20  ch52  ch56-20  ch60  ch64-20
  ch100 ch104-20 ch108 ch112-20 ch116 ch120-20 ch124 ch128-20
  ch132 ch136-20 ch140 ch144-20
  ch149 ch153-20 ch157 ch161-20 ch165-20 ch169 ch173-20

Add --make-permanent after a channel mode to store the chosen
primary channel with:  fw_setenv wlanchan <number>"
        exit 1
        ;;
esac
