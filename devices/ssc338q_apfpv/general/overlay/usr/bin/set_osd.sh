#!/bin/sh

case "$1" in
  mode-manual)
    echo "Setting link control to manual." | tee /tmp/webui.log
    fw_setenv mode "manual"
    ;;
  
  mode-aalink)
    echo "Setting link control to aalink." | tee /tmp/webui.log
    fw_setenv mode "aalink"
    ;;

  mode-standalone)
    echo "Setting tty to standalone." | tee /tmp/webui.log
    fw_setenv msposd_tty "standalone"
    ;;

  mode-tty0)
    echo "Setting tty to /dev/ttyS0." | tee /tmp/webui.log
    fw_setenv msposd_tty "/dev/ttyS0"
    ;;

  mode-tty1)
    echo "Setting tty to /dev/ttyS1." | tee /tmp/webui.log
    fw_setenv msposd_tty "/dev/ttyS1"
    ;;

  mode-tty2)
    echo "Setting tty to /dev/ttyS2." | tee /tmp/webui.log
    fw_setenv msposd_tty "/dev/ttyS2"
    ;;

  *)
    echo "Invalid argument: $1" | tee /tmp/webui.log
    exit 1
    ;;
esac

/etc/init.d/S99msposd start
/etc/init.d/S991aalink start

exit 0
