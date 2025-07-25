#!/bin/sh
  
echo "------- AP_FPV settings -------"
echo "Current SSID: $(fw_printenv -n wlanssid || echo OpenIPC)"
echo "Current Passw: $(fw_printenv -n wlanpass || echo 12345678)"
echo "Current WlanPwr: $(fw_printenv -n wlanpwr || echo 250)"
echo "Current Channel: $(fw_printenv -n wlanchan || echo 149)"
echo "Current Link Control: $(fw_printenv -n mode || echo manual)"
echo "Current MSP TTY: $(fw_printenv -n msposd_tty || echo -)"
echo "Current Output: $(fw_printenv -n master_protocol || echo udp)://$(fw_printenv -n master_ip || echo 192.168.0.10):$(fw_printenv -n master_port || echo 5600)"
echo "-------------------------------"
echo "Connected sensor: $(ipcinfo -l)"
echo "Currently set sensor: $(fw_printenv sensor)"
echo "Current temp: $(ipcinfo -t)"
echo "-------------------------------"
iw dev wlan0 info
echo "-------------------------------"
cat /proc/net/rtl*/wlan0/sta_tp_info

exit 0
