#!/bin/sh
# ---------------------------------------------------------
# set_channel.sh – BusyBox-compatible channel helper
#
# Usage:
#   set_channel.sh <channel-mode> [--make-permanent]
#
# Channel modes:
#   ch36  ch36-20  ch44  ch44-20  ch52  ch52-20
#   ch100 ch100-20 ch140 ch149 ch149-20 ch157 ch157-20
#
# Add --make-permanent after a channel mode to store the
# primary channel with:   fw_setenv wlanchan <number>
# ---------------------------------------------------------

############################################################################
# 0)  Helper – log everything to /tmp/webui.log *and* to the console
############################################################################
log() {           # log "message …"
    printf '%s\n' "$*" | tee /tmp/webui.log
}

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
DRIVER=$(detect_driver)

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
    fw_setenv wlanchan "$1" 2>&1 | tee -a /tmp/webui.log
    log "(fw_setenv wlanchan $1)"
}

############################################################################
# 4)  Helper – do the channel change with 88XXau-aware logic
############################################################################
do_switch() {                          # $1 = hostapd_cli command, $2 = primary channel
    if [ "$DRIVER" = 88XXau ]; then
        log "Live channel change currently not supported."
        if [ "$PERM" = "--make-permanent" ]; then
            permanent_set "$2"
            log "Please reboot the device for the channel change to take effect."
        fi
    else
        eval "$1" 2>&1 | tee -a /tmp/webui.log
        [ "$PERM" = "--make-permanent" ] && permanent_set "$2"
    fi
}

############################################################################
# 5)  Main dispatch
############################################################################
MODE="$1"
PERM="$2"   # optional --make-permanent

case "$MODE" in
################################################################################
    ch36)      do_switch "$HOSTAPD_CLI chan_switch $CS 5180  sec_channel_offset=1 center_freq1=5190 $BW40" 36 ;;
    ch36-20)   do_switch "$HOSTAPD_CLI chan_switch $CS 5180"                                                    36 ;;
    ch44)      do_switch "$HOSTAPD_CLI chan_switch $CS 5220  sec_channel_offset=1 center_freq1=5230 $BW40" 44 ;;
    ch44-20)   do_switch "$HOSTAPD_CLI chan_switch $CS 5220"                                                    44 ;;
    ch52)      log "DFS: CAC ~60 s…"
               do_switch "$HOSTAPD_CLI chan_switch $CS 5260  sec_channel_offset=1 center_freq1=5270 $BW40" 52 ;;
    ch52-20)   log "DFS: CAC ~60 s…"
               do_switch "$HOSTAPD_CLI chan_switch $CS 5260"                                                    52 ;;
    ch140)     do_switch "$HOSTAPD_CLI chan_switch $CS 5700  sec_channel_offset=1 center_freq1=5710 $BW40" 140 ;;
    ch149)     do_switch "$HOSTAPD_CLI chan_switch $CS 5745  sec_channel_offset=1 center_freq1=5755 $BW40" 149 ;;
    ch149-20)  do_switch "$HOSTAPD_CLI chan_switch $CS 5745"                                                    149 ;;
    ch157)     do_switch "$HOSTAPD_CLI chan_switch $CS 5785  sec_channel_offset=1 center_freq1=5795 $BW40" 157 ;;
    ch157-20)  do_switch "$HOSTAPD_CLI chan_switch $CS 5785"                                                    157 ;;
################################################################################
    *)
        log "Usage: $0 <channel-mode> [--make-permanent]

Channel modes:
  ch36  ch36-20  ch44  ch44-20  ch52  ch52-20
  ch100 ch100-20 ch140 ch149 ch149-20 ch157 ch157-20

Add --make-permanent after a channel mode to store the chosen
primary channel with:  fw_setenv wlanchan <number>"
        exit 1
        ;;
esac
