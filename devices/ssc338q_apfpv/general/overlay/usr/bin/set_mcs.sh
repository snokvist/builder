#!/bin/sh
# set_aalink.sh ─ group‑wide MCS or threshold update for /etc/aalink.conf
# Usage examples:
#     set_aalink.sh mcs_3
#     set_aalink.sh threshold_max
# ──────────────────────────────────────────────────────────────────────────

CONF=/etc/aalink.conf                        # file to edit

# Preset threshold tables
THRESH_MIN="00,15,25,34,45,58,65,70"
THRESH_MED="00,20,30,38,50,63,75,88"
THRESH_MAX="00,30,40,50,60,70,82,95"

############################################################################
# Sanity check
[ $# -ne 1 ] && {
    echo "Usage: $0  mcs_<0‑7>  |  threshold_<min|medium|max>" >&2
    exit 1
}

arg="$1"

############################################################################
# ─── MCS update ───────────────────────────────────────────────────────────
if printf '%s\n' "$arg" | grep -q '^mcs_[0-7]$'; then
    mcs="${arg#mcs_}"

    if [ "$mcs" -eq 0 ]; then
        MCS20=1; MCS40=0          # special 0 → 1/0 rule
    else
        MCS20=$mcs
        MCS40=$((mcs-1))
    fi

    for R in EU AU BU; do
        sed -i \
            -e "s/^MAX_MCS_${R}=.*/MAX_MCS_${R}=${MCS20}/" \
            -e "s/^MAX_MCS_40_${R}=.*/MAX_MCS_40_${R}=${MCS40}/" \
            "$CONF"
    done

    echo "✓  MCS caps set to 20 MHz=${MCS20}, 40 MHz=${MCS40}"
    exit 0
fi

############################################################################
# ─── Threshold update ─────────────────────────────────────────────────────
case "$arg" in
    threshold_min)    THRESH=$THRESH_MIN ;;
    threshold_medium) THRESH=$THRESH_MED ;;
    threshold_max)    THRESH=$THRESH_MAX ;;
    *) echo "✗  Invalid argument: $arg" >&2
       echo "    Use mcs_0…mcs_7 or threshold_min|medium|max" >&2
       exit 1 ;;
esac

for R in EU AU BU; do
    sed -i "s/^THRESH_${R}=.*/THRESH_${R}=${THRESH}/" "$CONF"
done

echo "✓  Threshold table set to: $arg"
