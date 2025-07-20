#!/bin/sh
# set_aalink_flags.sh – update MAX_MCS_* and THRESH_* in /etc/aalink.conf
# Usage example:
#     threshold_max=1 mcs_5=1 ./set_aalink_flags.sh
# ────────────────────────────────────────────────────────────────────────

CONF=/etc/aalink.conf

# Preset tables
THRESH_MIN="00,15,25,34,45,58,65,70"
THRESH_MED="00,20,30,38,50,63,75,88"
THRESH_MAX="00,30,40,50,60,70,82,95"

############################################################################
# Detect which MCS flag was supplied
mcs_set=""
for i in 0 1 2 3 4 5 6 7; do
    eval "val=\${mcs_$i}"
    [ -n "$val" ] && mcs_set="$i"
done
[ -z "$mcs_set" ] && { echo "✗  Set exactly one of mcs_0…mcs_7"; exit 1; }

# Derive caps (20 / 40 MHz)
if [ "$mcs_set" -eq 0 ]; then
    MCS20=1; MCS40=0
else
    MCS20=$mcs_set
    MCS40=$((mcs_set-1))
fi

############################################################################
# Detect which threshold flag was supplied
case "${threshold_min:+min}${threshold_medium:+med}${threshold_max:+max}" in
    min) THRESH=$THRESH_MIN ;;
    med) THRESH=$THRESH_MED ;;
    max) THRESH=$THRESH_MAX ;;
    *)   echo "✗  Set exactly one of threshold_min | threshold_medium | threshold_max"
         exit 1 ;;
esac

############################################################################
# Apply to all regions
for R in EU AU BU; do
    sed -i \
        -e "s/^MAX_MCS_${R}=.*/MAX_MCS_${R}=${MCS20}/" \
        -e "s/^MAX_MCS_40_${R}=.*/MAX_MCS_40_${R}=${MCS40}/" \
        -e "s/^THRESH_${R}=.*/THRESH_${R}=${THRESH}/" \
        "$CONF"
done

echo "✓  /etc/aalink.conf updated – MCS20=${MCS20} (40 MHz ${MCS40}), threshold=${THRESH}"
