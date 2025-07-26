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
cli -s .video0.size 1920x1440
cli -s .video0.bitrate 8096
cli -s .video0.codec h265
cli -s .video0.rcMode cbr
cli -s .video0.gopSize 5
cli -s .outgoing.enabled true
cli -s .outgoing.server udp://192.168.0.10:5600
cli -s .records.split 5
cli -s .records.notime true
cli -s .fpv.enabled true
cli -s .fpv.noiseLevel 0
cli -s .isp.sensorConfig /etc/sensors/imx335_greg_fpvV.bin
cli -s .video0.qpDelta -12
#cli -s .osd.font /usr/share/fonts/truetype/osd.ttf

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
chmod +x /usr/bin/set_tty.sh
chmod +x /usr/bin/set_wlanssid.sh
chmod +x /usr/bin/air_man_ap
chmod +x /etc/rc.local
chmod +x /etc/init.d/S994air_man
chmod +x /usr/bin/set_video.sh
chmod +x /etc/init.d/S95majestic
chmod +x /usr/bin/gs_cmd.sh
chmod +x /usr/bin/dropbear_setup.sh
chmod +x /usr/bin/service_watchdog.sh
chmod +x /usr/bin/set_osd.sh
chmod +x /usr/bin/ota.sh
chmod +x /usr/bin/control_cmd.sh
chmod +x /etc/init.d/S990antenna_osd
chmod +x /usr/bin/set_masterip.sh
chmod +x /usr/bin/set_mcs.sh
chmod +x /usr/bin/msposd
chmod +x /usr/bin/antenna_osd
chmod +x /usr/bin/set_externalosd.sh
mv /etc/init.d/S99msposd /etc/init.d/S96msposd
