#!/bin/sh

echo "Setting TTY to $1."
fw_setenv msposd_tty $1

/etc/init.d/S99msposd start

exit 0
