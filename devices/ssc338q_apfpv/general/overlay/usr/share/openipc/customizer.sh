#!/bin/sh
#
# Perform basic settings on a known IP camera
#
#
# Set custom upgrade url
#
fw_setenv upgrade 'https://github.com/OpenIPC/builder/releases/download/latest/openipc.ssc338q-nor-apfpv.tgz'
#
#
# Set custom majestic settings
#
cli -s .isp.exposure 8
cli -s .video0.fps 60
cli -s .video0.size 1440x1080
cli -s .video0.bitrate 8096
cli -s .video0.codec h265
cli -s .video0.rcMode cbr
cli -s .video0.gopSize 3
cli -s .outgoing.enabled true
cli -s .outgoing.server udp://192.168.0.10:5600
cli -s .records.split 5
cli -s .records.notime true
cli -s .fpv.enabled true
cli -s .fpv.noiseLevel 1
cli -s .isp.sensorConfig /etc/sensors/imx335_greg_fpvV.bin

# Set access
chmod +x /usr/bin/all_rates.sh
chmod +x /usr/bin/set_channel.sh
chmod +x /usr/bin/web
chmod +x /usr/bin/aalink
chmod +x /etc/init.d/S991aalink
chmod +x /etc/init.d/S992web
chmod +x /usr/bin/set_power.sh
chmod +x /usr/bin/set_mode.sh
chmod +x /usr/bin/webinfo.sh
chmod +x /usr/bin/overheat_protection.sh
chmod +x /etc/init.d/S993overheat_protect
chmod +x /usr/bin/set_wlanpass.sh
