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


  mode-ap_alink)
    echo "Setting link control to experimental ap-alink." | tee /tmp/webui.log
    fw_setenv mode "ap_alink"
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
kill -9 $(pidof aalink)
kill -9 $(pidof ap_alink)

/etc/init.d/S99msposd stop
/etc/init.d/S991aalink stop
/etc/init.d/S996ap_alink stop
/etc/init.d/S997manual_antenna stop

/etc/init.d/S99msposd start
/etc/init.d/S991aalink start
/etc/init.d/S996ap_alink start
/etc/init.d/S997manual_antenna start
sleep 5
echo "" > /tmp/MSPOSD.msg
exit 0
