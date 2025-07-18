#!/bin/sh
#
# dual_watchdog.sh  – monitor hostapd + majestic every 2 s
#                     restart after 3 consecutive misses,
#                     recognise restart loops (stub).
#
# BusyBox/ash compatible.  Start it in the background from rc.local or an init‑script:
#     /usr/local/bin/dual_watchdog.sh &

CHECK_INT=2        # seconds between polls
MAX_FAIL=3         # consecutive misses before restart
MAX_OK=3           # consecutive OKs that “clear” the error state
# How many restarts in a row make us declare “restart‑loop”; adjust as you like
RESTART_LOOP_THRESH=6

##############################################################################
# internal helpers
##############################################################################
is_alive() {                # $1 = executable name
    pidof "$1" >/dev/null 2>&1
}

restart_loop_stub() {       # $1 = service name
    local svc="$1"
    # ───── PLACEHOLDER ─────
    # Here you could: touch a GPIO, reboot, send an MQTT alert, etc.
    #logger -t dual_watchdog "$svc restart loop detected – stub called"
    echo "$svc restart loop detected – stub called" > /log/webui.log

    case "$svc" in
        majestic)
            # ── majestic-specific reset logic ──
            sed -i '/#set by air_manager/,/^$/d' "/etc/rc.local"
            killall -q msposd
            cli -s .video.size 1280x720
            cli -s .video.fps 60
            ;;
        hostapd)
            # ── hostapd-specific reset logic ──
            fw_setenv wlanchan
            fw_setenv wlanpwr
            ;;
        *)
            # Default/remainder logic for other services
            # e.g., generic alert
            # send_alert "Service $svc entered restart loop"
            ;;
    esac



}

restart_hostapd() {
    #logger -t dual_watchdog "hostapd missing – restarting"
    echo "hostapd missing – restarting" > /log/webui.log
    [ -e /var/run/hostapd/wlan0 ] && rm -f /var/run/hostapd/wlan0
    adapter start
}

restart_majestic() {
    logger -t dual_watchdog "majestic missing – restarting"
    
    /etc/init.d/S95majestic restart
}

##############################################################################
# per‑service state variables
##############################################################################
fail_hostapd=0      ok_hostapd=0      restarts_hostapd=0
fail_majestic=0     ok_majestic=0     restarts_majestic=0

##############################################################################
# main loop
##############################################################################
while : ; do
    ############################################################ hostapd
    if is_alive hostapd ; then
        fail_hostapd=0
        ok_hostapd=$((ok_hostapd + 1))
        if [ "$ok_hostapd" -ge "$MAX_OK" ]; then
            ok_hostapd=0
            restarts_hostapd=0             # “stable” again → clear loop counter
        fi
    else
        ok_hostapd=0
        fail_hostapd=$((fail_hostapd + 1))
        if [ "$fail_hostapd" -ge "$MAX_FAIL" ]; then
            restart_hostapd
            restarts_hostapd=$((restarts_hostapd + 1))
            fail_hostapd=0                 # restart done, start counting anew
            [ "$restarts_hostapd" -ge "$RESTART_LOOP_THRESH" ] && \
                restart_loop_stub hostapd
        fi
    fi

    ############################################################ majestic
    if is_alive majestic ; then
        fail_majestic=0
        ok_majestic=$((ok_majestic + 1))
        if [ "$ok_majestic" -ge "$MAX_OK" ]; then
            ok_majestic=0
            restarts_majestic=0
        fi
    else
        ok_majestic=0
        fail_majestic=$((fail_majestic + 1))
        if [ "$fail_majestic" -ge "$MAX_FAIL" ]; then
            restart_majestic
            restarts_majestic=$((restarts_majestic + 1))
            fail_majestic=0
            [ "$restarts_majestic" -ge "$RESTART_LOOP_THRESH" ] && \
                restart_loop_stub majestic
        fi
    fi

    sleep "$CHECK_INT"
done
