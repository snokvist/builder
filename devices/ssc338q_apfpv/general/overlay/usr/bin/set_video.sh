#!/bin/sh
# file: /usr/bin/set_video.sh
# BusyBox‑compatible wrapper for the video‑mode TCP service
# – supports index, dashed or spaced mode strings – logs everything.

set -o pipefail                     # propagate errors through the one‑tee pipeline

###############################################################################
TARGET_IP=${TARGET_IP:-192.168.0.1}
TARGET_PORT=${TARGET_PORT:-12355}
NC_TIMEOUT=${NC_TIMEOUT:-2}         # seconds
LOGFILE=/tmp/webui.log              # fresh log each time
###############################################################################

# ---------------------------------------------------------------- mode list --
MODE_LIST=$(cat <<'EOF'
4:3 720p 60
4:3 720p 60 50HzAC
4:3 960p 60
4:3 960p 60 50HzAC
4:3 1080p 60
4:3 1080p 60 50HzAC
4:3 1440p 60
4:3 1440p 60 50HzAC
4:3 1920p 60
4:3 1920p 60 50HzAC
4:3 720p 90
4:3 720p 90 50HzAC
4:3 960p 90
4:3 960p 90 50HzAC
4:3 1080p 90
4:3 1080p 90 50HzAC
4:3 1440p 90
4:3 1440p 90 50HzAC
4:3 540p 120
4:3 720p 120
4:3 960p 120
4:3 1080p 120
16:9 540p 60
16:9 540p 60 50HzAC
16:9 720p 60
16:9 720p 60 50HzAC
16:9 1080p 60
16:9 1080p 60 50HzAC
16:9 1440p 60
16:9 1440p 60 50HzAC
16:9 540p 90
16:9 540p 90 50HzAC
16:9 720p 90
16:9 720p 90 50HzAC
16:9 1080p 90
16:9 1080p 90 50HzAC
16:9 1344p 90
16:9 1344p 90 50HzAC
16:9 540p 120
16:9 720p 120
16:9 1080p 120
EOF
)

usage() {
    cat <<EOF
Usage:
  $(basename "$0") INDEX              # e.g. 37
  $(basename "$0") 16:9-1344p-90-50HzAC
  $(basename "$0") "16:9 1344p 90 50HzAC"

  $(basename "$0") --get-current
  $(basename "$0") --get-all

Environment:
  TARGET_IP, TARGET_PORT, NC_TIMEOUT   Override defaults
EOF
}

###############################################################################
# Everything below runs inside one block that is piped to tee once
###############################################################################
{
    # -------------------------------------------------------------- arguments -
    if [ "$#" -eq 0 ]; then
        usage >&2
        exit 1
    fi

    case "$1" in
        --get-current)
            CMD="get_current_video_mode"
            ;;
        --get-all)
            idx=1
            printf '[%s] Available video modes:\n' "$(date '+%Y-%m-%d %H:%M:%S')"
            echo "$MODE_LIST" | while IFS= read -r m; do
                printf '%2d: %s\n' "$idx" "$m"
                idx=$((idx+1))
            done
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            # Decide how the mode was specified
            if [ "$#" -eq 1 ] && echo "$1" | grep -qE '^[0-9]+$'; then
                MODE=$(echo "$MODE_LIST" | sed -n "${1}p")
                if [ -z "$MODE" ]; then
                    echo "Index $1 out of range" >&2
                    exit 1
                fi
            elif [ "$#" -eq 1 ]; then
                MODE=$(printf '%s\n' "$1" | tr '-' ' ')
            else
                MODE=$*
            fi
            CMD="set_simple_video_mode $MODE"
            ;;
    esac

    # ------------------------------------------------------------- run & log -
    printf '[%s] CMD: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$CMD"

    OUTPUT=$(printf '%s\n' "$CMD" \
             | timeout "$NC_TIMEOUT" nc "$TARGET_IP" "$TARGET_PORT" 2>&1)
    STATUS=$?

    printf '%s\n' "$OUTPUT"

    if [ "$STATUS" -ne 0 ]; then
        echo "Command failed (exit $STATUS). Is the device reachable?" >&2
    fi
    exit "$STATUS"
} 2>&1 | tee "$LOGFILE"
