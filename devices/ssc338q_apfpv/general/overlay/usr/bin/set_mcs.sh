#!/bin/sh
# set_aalink.sh  –  group‑wide MCS / threshold updater + status viewer
#                  Updates are logged to /tmp/webui.log (overwritten).
#
# Usage:
#   set_aalink.sh mcs_0 … mcs_7
#   set_aalink.sh threshold_min | threshold_medium | threshold_max
#   set_aalink.sh status        # or:  set_aalink.sh print
# ───────────────────────────────────────────────────────────────────────────

CONF=/etc/aalink.conf
LOG=/tmp/webui.log

# Preset threshold tables
THRESH_MIN="00,15,25,34,45,58,65,70"
THRESH_MED="00,20,30,38,50,63,75,88"
THRESH_MAX="00,30,40,50,60,70,82,95"

############################################################################
# Show help if no / too many args
[ $# -ne 1 ] && {
    echo "Usage: $0  mcs_<0‑7> | threshold_<min|medium|max> | status" >&2
    exit 1
}
arg="$1"

############################################################################
print_summary() {
    CUR_MCS20=$(grep -m1 '^MAX_MCS_EU='    "$CONF" | cut -d= -f2)
    CUR_MCS40=$(grep -m1 '^MAX_MCS_40_EU=' "$CONF" | cut -d= -f2)
    CUR_THRESH=$(grep -m1 '^THRESH_EU='    "$CONF" | cut -d= -f2)

    printf "✓ /etc/aalink.conf status\n\
MCS caps:\n\
  20 MHz = %s\n\
  40 MHz = %s\n\
Thresholds:\n\
  %s\n" \
    "$CUR_MCS20" "$CUR_MCS40" "$CUR_THRESH"
}

############################################################################
# ─── Status / print mode ──────────────────────────────────────────────────
case "$arg" in
    status|print)
        print_summary
        exit 0
        ;;
esac

############################################################################
# ─── MCS update ───────────────────────────────────────────────────────────
if printf '%s\n' "$arg" | grep -q '^mcs_[0-7]$'; then
    mcs="${arg#mcs_}"

    if [ "$mcs" -eq 0 ]; then
        MCS20=1; MCS40=0
    else
        MCS20=$mcs; MCS40=$((mcs-1))
    fi

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
    mcs_*) ;;  # already handled
    *) echo "✗  Invalid argument: $arg" >&2
       echo "    Use mcs_0…mcs_7, threshold_min|medium|max, or status" >&2
       exit 1 ;;
esac

if [ -n "$THRESH" ]; then
    for R in EU AU BU; do
        sed -i "s/^THRESH_${R}=.*/THRESH_${R}=${THRESH}/" "$CONF"
    done
fi

############################################################################
# ─── Multi‑line summary + log (for *updates* only) ────────────────────────
print_summary | tee "$LOG"
