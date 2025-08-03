#!/bin/sh
PRI=5745          # primary frequency for ch149
CENTER=5755       # HT40+ centre
case "$1" in
  20)
    hostapd_cli chan_switch 1 $PRI \
        sec_channel_offset=0 bandwidth=20 ht ;;
  40)
    hostapd_cli chan_switch 1 $PRI \
        sec_channel_offset=1 center_freq1=$CENTER \
        bandwidth=40 ht ;;
  *)
    echo "Usage: $0 {20|40}"
esac
