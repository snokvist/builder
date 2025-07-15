#!/bin/sh

echo "Setting mode $1." | tee /tmp/webui.log
fw_setenv mode "$1"
/etc/init.d/S99msposd start
/etc/init.d/S991aalink start

exit 0
