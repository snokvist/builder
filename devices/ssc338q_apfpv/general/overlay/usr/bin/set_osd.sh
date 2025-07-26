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


killall majestic
sleep 0.5
kill -9 $(pidof majestic) 
sleep 0.5
kill -9 $(pidof msposd) 
sleep 0.5
kill -9 $(pidof msposd) 
kill -9 $(pidof aalink)
kill -9 $(pidof antenna_osd)
majestic -s &
sleep 4
/etc/init.d/S98msposd start
sleep 1
/etc/init.d/S990antenna_osd start
/etc/init.d/S991aalink start
sleep 1
echo "" > /tmp/MSPOSD.msg
exit 0
