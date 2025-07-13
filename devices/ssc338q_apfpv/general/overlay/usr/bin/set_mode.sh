#!/bin/sh

echo "Setting mode $1. Please reboot device."
fw_setenv $1

exit 0
