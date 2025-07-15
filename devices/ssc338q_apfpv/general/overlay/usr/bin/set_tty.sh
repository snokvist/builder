#!/bin/sh

echo "Setting tty to $1." | tee /tmp/webui.log
fw_setenv msposd_tty "$1"
/etc/init.d/S99msposd start
/etc/init.d/S991aalink start

exit 0
