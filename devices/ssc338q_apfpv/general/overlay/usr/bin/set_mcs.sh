#!/bin/sh
# set_aalink.sh  –  group‑wide MCS or threshold update for /etc/aalink.conf
#                  Logs every run to /tmp/webui.log
# Usage:
#     set_aalink.sh mcs_0 … mcs_7
#     set_aalink.sh threshold_min | threshold_medium | threshold_max
# ───────────────────────────────────────────────────────────────────────────

CONF=/etc/aalink.conf               # file to edit
LOG=/tmp/webui.log                  # central log

# Preset threshold tables
THRESH_MIN="00,15,25,34,45,58,65,70"
THRESH_MED="00,20,30,38,50,63,75,88"
THRESH_MAX="00,30,40,50,60,70,82,95"

############################################################################
[ $# -ne 1 ] && {
    echo "Usage: $0  mcs_<0‑7>  |  threshold_<min|medium|max>" >&2
    exit 1
}
arg="$1"

############################################################################
# ─── MCS update ───────────────────────────────────────────────────────────
if printf '%s\n' "$arg" | grep -q '^mcs_[0-7]$'; then
    mcs="${arg#mcs_}"

    # derive caps (20 / 40 MHz)
    if [ "$mcs" -eq 0 ]; then
        MCS20=1; MCS40=0
    else
        MCS20=$mcs; MCS40=$((mcs-1))
    fi

    # write caps for all regions
    for R in EU AU BU; do
        sed -i \
            -e "s/^MAX_MCS_${R}=.*/MAX_MCS_${R}=${MCS20}/" \
            -e "s/^MAX_MCS_40_${R}=.*/MAX_MCS_40_${R}=${MCS40}/" \
            "$CONF"
    done
fi

############################################################################
# ─── Threshold update ─────────────────────────────────────────────────────
case "$arg" in
    threshold_min)    THRESH=$THRESH_MIN ;;
    threshold_medium) THRESH=$THRESH_MED ;;
    threshold_max)    THRESH=$THRESH_MAX ;;
    mcs_*) ;;  # handled above
    *) echo "✗  Invalid argument: $arg" >&2
       echo "    Use mcs_0…mcs_7 or threshold_min|medium|max" >&2
       exit 1 ;;
esac

if [ -n "$THRESH" ]; then
    for R in EU AU BU; do
        sed -i "s/^THRESH_${R}=.*/THRESH_${R}=${THRESH}/" "$CONF"
    done
fi

############################################################################
# ─── Build summary (always include BOTH caps & thresholds) ────────────────
CUR_MCS20=$(grep -m1 '^MAX_MCS_EU='   "$CONF" | cut -d= -f2)
CUR_MCS40=$(grep -m1 '^MAX_MCS_40_EU=' "$CONF" | cut -d= -f2)
CUR_THRESH=$(grep -m1 '^THRESH_EU='    "$CONF" | cut -d= -f2)

MSG="✓ /etc/aalink.conf updated — MCS (20 MHz)=${CUR_MCS20}, \
MCS (40 MHz)=${CUR_MCS40}, thresholds=${CUR_THRESH}"

# Print to console AND append to log (no –s flag)
echo "$MSG" | tee -a "$LOG"
