#!/bin/sh
#
# set_aalink.sh  –  update MAX_MCS_* (20 / 40 MHz) and THRESH_* tables
#                   in /etc/aalink.conf
#
# ─────── How to use ─────────────────────────────────────────────────────────
# •   Pass the desired parameters on the *same* command line, e.g.
#
#       # Set every region to MCS 5/4 and “medium” thresholds
#       max_mcs=5 threshold=medium ./set_aalink.sh
#
#       # Different caps per region + high thresholds everywhere
#       max_mcs_eu=7 max_mcs_au=4 max_mcs_bu=6 threshold_high=1 ./set_aalink.sh
#
# •   Variable names accepted
#       max_mcs           – applies to *all* regions unless a per‑region override exists
#       max_mcs_eu|au|bu  – per‑region overrides
#       max_mcs0|2|4      – legacy synonyms (map to EU | AU | BU)
#
#       Choose *one* of  threshold_low | threshold_medium | threshold_high
#       or simply   threshold=low|medium|high
#       (plus optional threshold_eu|au|bu=low|medium|high overrides).
#
# •   Valid MCS range: 0‑7.  The script enforces “20 MHz cap = 40 MHz cap + 1”
#     with the special case 0 → 20 MHz = 1, 40 MHz = 0.
#
# •   Must run as root because it edits /etc/aalink.conf in‑place.
# ────────────────────────────────────────────────────────────────────────────

CONF=/etc/aalink.conf

THRESH_LOW="00,15,25,34,45,58,65,70"
THRESH_MEDIUM="00,20,30,38,50,63,75,88"
THRESH_HIGH="00,30,40,50,60,70,82,95"

############################################################################
set_mcs() {             # $1 = EU|AU|BU  $2 = desired 20‑MHz cap (0‑7)
    local region="$1" val="$2" cap20 cap40
    [ -z "$val" ] && return                     # nothing to do

    if [ "$val" -lt 0 ] || [ "$val" -gt 7 ]; then
        echo "✗  Invalid max_mcs ($val) for $region – must be 0‑7" >&2
        return
    fi

    if [ "$val" -eq 0 ]; then cap20=1; cap40=0
    else                     cap20=$val; cap40=$((val-1))
    fi

    sed -i \
        -e "s/^MAX_MCS_${region}=.*/MAX_MCS_${region}=${cap20}/" \
        -e "s/^MAX_MCS_40_${region}=.*/MAX_MCS_40_${region}=${cap40}/" \
        "$CONF"
}

set_thresh() {          # $1 = EU|AU|BU  $2 = low|medium|high
    local region="$1" level="$2" tbl
    [ -z "$level" ] && return

    case "$level" in
        low)    tbl=$THRESH_LOW    ;;
        medium) tbl=$THRESH_MEDIUM ;;
        high)   tbl=$THRESH_HIGH   ;;
        *)  echo "✗  Unknown threshold “$level” (use low|medium|high)" >&2; return ;;
    esac

    sed -i "s/^THRESH_${region}=.*/THRESH_${region}=${tbl}/" "$CONF"
}

############################################################################
# Global / per‑region parameter resolution
max_mcs_global=${max_mcs:-}
max_mcs_eu=${max_mcs_eu:-${max_mcs0:-$max_mcs_global}}
max_mcs_au=${max_mcs_au:-${max_mcs2:-$max_mcs_global}}
max_mcs_bu=${max_mcs_bu:-${max_mcs4:-$max_mcs_global}}

# one‑of flags → threshold choice
if   [ -n "$threshold_low" ];   then threshold=low
elif [ -n "$threshold_medium" ];then threshold=medium
elif [ -n "$threshold_high" ]; then threshold=high
fi

thresh_global=$threshold
thresh_eu=${threshold_eu:-$thresh_global}
thresh_au=${threshold_au:-$thresh_global}
thresh_bu=${threshold_bu:-$thresh_global}

############################################################################
# Apply changes – all three variants are always touched
set_mcs EU "$max_mcs_eu"
set_mcs AU "$max_mcs_au"
set_mcs BU "$max_mcs_bu"

set_thresh EU "$thresh_eu"
set_thresh AU "$thresh_au"
set_thresh BU "$thresh_bu"
