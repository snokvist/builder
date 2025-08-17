#!/bin/sh

echo "set_ap_channel $1" | nc -w 10 127.0.0.1 12355

echo "Setting new channel $1 ..." > /tmp/webui.log

exit 0
