#!/bin/sh
# ---------------------------------------------------------
# set_channel.sh – BusyBox-compatible channel helper
#
# Usage:
#   set_channel.sh <channel-mode> [--make-permanent]
#
# Channel modes:
#   ch36  ch36-20  ch44  ch44-20  ch52  ch52-20
#   ch100 ch100-20 ch149 ch149-20 ch157 ch157-20
#
# Add --make-permanent after a channel mode to store the
# primary channel with:   fw_setenv chan <number>
# ---------------------------------------------------------

### USER CONSTANTS #######################################################
IFACE=wlan0
HOSTAPD_CLI="hostapd_cli -i $IFACE"
CS=5                                   # beacon delay for CSA
BW40="bandwidth=40 ht vht"             # CSA flags for HT40
##########################################################################

############################################################################
# Helper: write channel to bootloader env (permanent)
############################################################################
permanent_set() {  # $1 = primary channel number
    fw_setenv chan "$1" && echo "(fw_setenv chan $1)"
}

############################################################################
# Main dispatch
############################################################################
MODE="$1"
PERM="$2"   # optional --make-permanent

case "$MODE" in
################################ CHANNEL MODES ################################
    ch36)
        $HOSTAPD_CLI chan_switch $CS 5180 sec_channel_offset=1 center_freq1=5190 $BW40
        [ "$PERM" = "--make-permanent" ] && permanent_set 36
        ;;
    ch36-20)
        $HOSTAPD_CLI chan_switch $CS 5180
        [ "$PERM" = "--make-permanent" ] && permanent_set 36
        ;;
    ch44)
        $HOSTAPD_CLI chan_switch $CS 5220 sec_channel_offset=1 center_freq1=5230 $BW40
        [ "$PERM" = "--make-permanent" ] && permanent_set 44
        ;;
    ch44-20)
        $HOSTAPD_CLI chan_switch $CS 5220
        [ "$PERM" = "--make-permanent" ] && permanent_set 44
        ;;
    ch52)
        echo "DFS: CAC ~60 s…"
        $HOSTAPD_CLI chan_switch $CS 5260 sec_channel_offset=1 center_freq1=5270 $BW40
        [ "$PERM" = "--make-permanent" ] && permanent_set 52
        ;;
    ch52-20)
        echo "DFS: CAC ~60 s…"
        $HOSTAPD_CLI chan_switch $CS 5260
        [ "$PERM" = "--make-permanent" ] && permanent_set 52
        ;;
    ch140)
        $HOSTAPD_CLI chan_switch $CS 5700 sec_channel_offset=1 center_freq1=5710 $BW40
        [ "$PERM" = "--make-permanent" ] && permanent_set 140
        ;;
    ch149)
        $HOSTAPD_CLI chan_switch $CS 5745 sec_channel_offset=1 center_freq1=5755 $BW40
        [ "$PERM" = "--make-permanent" ] && permanent_set 149
        ;;
    ch149-20)
        $HOSTAPD_CLI chan_switch $CS 5745
        [ "$PERM" = "--make-permanent" ] && permanent_set 149
        ;;
    ch157)
        $HOSTAPD_CLI chan_switch $CS 5785 sec_channel_offset=1 center_freq1=5795 $BW40
        [ "$PERM" = "--make-permanent" ] && permanent_set 157
        ;;
    ch157-20)
        $HOSTAPD_CLI chan_switch $CS 5785
        [ "$PERM" = "--make-permanent" ] && permanent_set 157
        ;;

############################## HELP ###########################################
    *)
        cat <<EOF
Usage: $0 <channel-mode> [--make-permanent]

Channel modes:
  ch36  ch36-20  ch44  ch44-20  ch52  ch52-20
  ch100 ch100-20 ch149 ch149-20 ch157 ch157-20

Add --make-permanent after a channel mode to store the chosen
primary channel with:  fw_setenv chan <number>
EOF
        exit 1
        ;;
esac
