#!/bin/sh
# Waybeam first-boot customizer
# Runs once via S30customizer, then /etc/custom.ok prevents re-run.
#
# Detects the sensor driver loaded by the kernel and configures
# venc.json with the matching sensor tuning profile (.bin).

echo "Waybeam customizer: starting first-boot setup"

VENC_CONF="/etc/venc.json"
JSON_CLI="/usr/bin/json_cli"

# ---- Sensor detection and venc config ----

detect_sensor() {
    # Check loaded kernel modules for sensor driver
    if lsmod 2>/dev/null | grep -q "sensor_imx335"; then
        echo "imx335"
    elif lsmod 2>/dev/null | grep -q "sensor_imx415"; then
        echo "imx415"
    elif [ -e /lib/modules/*/sigmastar/sensor_imx335_mipi.ko ] && \
         ! [ -e /lib/modules/*/sigmastar/sensor_imx415_mipi.ko ]; then
        # Only imx335 .ko present — must be imx335
        echo "imx335"
    elif [ -e /lib/modules/*/sigmastar/sensor_imx415_mipi.ko ] && \
         ! [ -e /lib/modules/*/sigmastar/sensor_imx335_mipi.ko ]; then
        # Only imx415 .ko present — must be imx415
        echo "imx415"
    else
        echo ""
    fi
}

configure_sensor() {
    sensor="$1"
    case "$sensor" in
        imx335)
            bin="/etc/sensors/imx335_greg_fpvVII-gpt200.bin"
            ;;
        imx415)
            bin="/etc/sensors/imx415_greg_fpvXVIII-gpt200.bin"
            ;;
        *)
            echo "Waybeam customizer: unknown sensor '$sensor', skipping venc config"
            return 1
            ;;
    esac

    if [ ! -f "$bin" ]; then
        echo "Waybeam customizer: sensor bin not found: $bin"
        return 1
    fi

    if [ -f "$JSON_CLI" ] && [ -f "$VENC_CONF" ]; then
        echo "Waybeam customizer: setting sensor=$sensor sensorBin=$bin"
        "$JSON_CLI" set "$VENC_CONF" isp.sensorBin "$bin"
    else
        echo "Waybeam customizer: json_cli or venc.json not found, skipping"
        return 1
    fi
}

sensor=$(detect_sensor)
if [ -n "$sensor" ]; then
    configure_sensor "$sensor"
else
    echo "Waybeam customizer: no sensor detected, skipping venc config"
fi

echo "Waybeam customizer: first-boot setup complete"
