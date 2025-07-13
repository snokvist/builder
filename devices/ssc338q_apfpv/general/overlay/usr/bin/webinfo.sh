#!/bin/sh
  
echo "------- AP_FPV settings -------"
echo "Current SSID: $(fw_printenv -n wlanssid || echo OpenIPC)"
echo "Current Passw: $(fw_printenv -n wlanpass || echo 12345678)"
echo "Current WlanPwr: $(fw_printenv -n wlanpwr || echo 250)"
echo "Current Channel: $(fw_printenv -n wlanchan || echo 149)"
echo "Current Mode: $(fw_printenv -n mode || echo manual)"
echo "Current Mode: $(fw_printenv -n msposd_tty || echo manual)"
echo "-------------------------------"
echo "Connected sensor: $(ipcinfo -l)"
echo "Currently set sensor: $(fw_printenv sensor)"
echo "Current temp: $(ipcinfo -t)"
echo "-------------------------------"
cat /proc/net/rtl*/wlan0/sta_tp_info

exit 0
