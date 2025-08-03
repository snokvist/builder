#!/bin/sh
# Simple hostapd-CSA wrapper for 20/40 MHz on a fixed set of 5 GHz channels.
# Usage: chan_bw.sh ch149-40

IFACE=wlan0                     # change if your AP lives on a different ifname
HOSTAPD_CLI="hostapd_cli -i $IFACE"
CS_COUNT=1                      # 1 beacon interval ≈102 ms – near-instant

##############################################################################
parse() {
    [ -z "$1" ] && { echo "usage: $(basename "$0") chXX-{20|40}" ; exit 1 ; }
    CH=$(printf '%s\n' "$1" | tr 'A-Z' 'a-z')
    CH=${CH#ch}                 # strip leading "ch"
    BW=${CH#*-}                 # part after "-"
    CH=${CH%-*}                 # part before "-"
}

chan_to_freq() { echo $((5000 + 5 * $1)) ; }

lookup_ht40_offset() {
    case "$1" in
        36|44|52|60|100|108|116|124|132|149|157) echo  1 ;;  # HT40+
        40|48|56|64|104|112|120|128|136|153|161) echo -1 ;;  # HT40-
        165) echo  0 ;;                                      # 20 MHz only
        *)   echo  9 ;;                                      # unsupported
    esac
}

##############################################################################
parse "$1"

case "$BW" in
    20|40) ;;  *) echo "bandwidth must be 20 or 40" ; exit 1 ;;
esac

SEC_OFFSET=$(lookup_ht40_offset "$CH")
[ "$SEC_OFFSET" = 9 ] && { echo "unsupported channel $CH" ; exit 1 ; }
[ "$BW" = 40 ] && [ "$SEC_OFFSET" = 0 ] && {
    echo "Channel $CH may not be used at 40 MHz" ; exit 1 ; }

PRI_FREQ=$(chan_to_freq "$CH")

if [ "$BW" = 20 ]; then
    # 20 MHz: no secondary channel, no center frequency
    $HOSTAPD_CLI chan_switch $CS_COUNT "$PRI_FREQ" \
        sec_channel_offset=0 bandwidth=20 ht
else
    CENTER_FREQ=$((PRI_FREQ + SEC_OFFSET * 10))
    $HOSTAPD_CLI chan_switch $CS_COUNT "$PRI_FREQ" \
        sec_channel_offset=$SEC_OFFSET \
        center_freq1=$CENTER_FREQ \
        bandwidth=40 ht
fi
