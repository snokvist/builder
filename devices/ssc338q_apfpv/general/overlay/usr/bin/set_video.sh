#!/bin/sh
# file: /usr/bin/set_video_json.sh
# BusyBox-compatible wrapper for the video-mode TCP service, with JSON output for gets

set -o pipefail                     # propagate errors through the one-tee pipeline

###############################################################################
TARGET_IP=${TARGET_IP:-192.168.0.1}
TARGET_PORT=${TARGET_PORT:-12355}
NC_TIMEOUT=${NC_TIMEOUT:-2}         # seconds
LOGFILE=/tmp/webui.log              # fresh log each time
###############################################################################

# -----------------------------------------------------------------------------#
# Your full MODE_LIST definition goes here, exactly as in your original script #
# (omitted for brevity)                                                        #
# -----------------------------------------------------------------------------#
# MODE_LIST=$(cat <<'EOF'
# 4:3 720p 60
# ... all your modes ...
# 16:9 1080p 120
# EOF
# )

usage() {
    cat <<EOF
Usage:
  $(basename "$0") --get-current
  $(basename "$0") --get-all
  $(basename "$0") INDEX                 # falls back to plain set logic
  $(basename "$0") 16:9-1344p-90-50HzAC   (etc)

Environment:
  TARGET_IP, TARGET_PORT, NC_TIMEOUT
EOF
}

# -----------------------------------------------------------------------------#
# 1) Handle --get-all before we start tee’ing, so it does NOT go into the log  #
# -----------------------------------------------------------------------------#
if [ "$1" = "--get-all" ]; then
    RAW=$(printf 'get_all_video_modes\n' \
          | timeout "$NC_TIMEOUT" nc "$TARGET_IP" "$TARGET_PORT" 2>&1)

    ARR='['
    FIRST=1
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        ESC=$(printf '%s' "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')
        if [ $FIRST -eq 1 ]; then
            ARR="${ARR}\"${ESC}\""
            FIRST=0
        else
            ARR="${ARR},\"${ESC}\""
        fi
    done <<EOF
$RAW
EOF
    ARR="${ARR}]"
    printf '{"available_modes":%s}\n' "$ARR"
    exit 0
fi

###############################################################################
# Everything below runs inside one block that is piped to tee (and logged)   #
###############################################################################
{
    if [ "$#" -eq 0 ]; then
        usage >&2
        exit 1
    fi

    case "$1" in
        --get-current)
            RAW=$(printf 'get_current_video_mode\n' \
                  | timeout "$NC_TIMEOUT" nc "$TARGET_IP" "$TARGET_PORT" 2>&1)
            if echo "$RAW" | grep -q 'Current mode file not found'; then
                MODE="unknown"
            else
                MODE=$(printf '%s' "$RAW" | tr -d '\r\n')
            fi
            ESC=$(printf '%s' "$MODE" | sed 's/\\/\\\\/g; s/"/\\"/g')
            printf '{"current_mode":"%s"}\n' "$ESC"
            exit 0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [ "$#" -eq 1 ] && echo "$1" | grep -qE '^[0-9]+$'; then
                MODE=$(echo "$MODE_LIST" | sed -n "${1}p")
                [ -n "$MODE" ] || { echo "Index $1 out of range" >&2; exit 1; }
            else
                ARG="$*"
                MODE=$(printf '%s\n' "$ARG" | tr '_' ':' | tr '-' ' ')
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
