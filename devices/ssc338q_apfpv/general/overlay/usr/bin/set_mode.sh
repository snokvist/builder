#!/bin/sh

echo "Setting mode $1. Please reboot device."
fw_setenv mode "$1"
/etc/init.d/S99msposd start
/etc/init.d/S991aalink start

exit 0
