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
cli -s .video0.bitrate 12000
cli -s .video0.codec h265
cli -s .video0.rcMode cbr
cli -s .outgoing.enabled true
cli -s .outgoing.server udp://192.168.0.10:5600
cli -s .records.split 5
cli -s .records.notime true
cli -s .fpv.enabled true
cli -s .fpv.noiseLevel 1

# Set access
chmod +x /usr/bin/alink.sh
chmod +x /usr/bin/all_rates.sh
chmod +x /usr/bin/set_channel.sh
chmod +x /usr/bin/web
