#!/bin/sh
# file: /usr/bin/set_video.sh
# BusyBox‑compatible wrapper for the video‑mode TCP service
# – supports index, dashed or spaced mode strings – logs everything.

###############################################################################
TARGET_IP=${TARGET_IP:-192.168.0.1}
TARGET_PORT=${TARGET_PORT:-12355}
NC_TIMEOUT=${NC_TIMEOUT:-2}            # seconds
LOGFILE=/tmp/webui.log                 # tee all I/O here
###############################################################################

# ---------------------------------------------------------------- mode list --
# Keep this list in the exact order you want the indices to have.
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

# -------------------------------------------------------------- arguments ---
[ "$#" -eq 0 ] && { usage | tee -a "$LOGFILE" >&2; exit 1; }

case "$1" in
    --get-current)
        CMD="get_current_video_mode"
        ;;
    --get-all)
        # Print list with a 1‑based index column
        idx=1
        echo "$MODE_LIST" | while IFS= read -r m; do
            printf '%2d: %s\n' "$idx" "$m"
            idx=$((idx+1))
        done | tee -a "$LOGFILE"
        exit 0
        ;;
    -h|--help)
        usage | tee -a "$LOGFILE"
        exit 0
        ;;
    *)
        # Decide how the mode was specified
        if [ "$#" -eq 1 ] && echo "$1" | grep -qE '^[0-9]+$'; then
            # pure index
            MODE=$(echo "$MODE_LIST" | sed -n "${1}p")
            [ -z "$MODE" ] && { echo "Index $1 out of range" | tee -a "$LOGFILE" >&2; exit 1; }
        elif [ "$#" -eq 1 ]; then
            # single dashed token
            MODE=$(printf '%s\n' "$1" | tr '-' ' ')
        else
            # already space‑separated
            MODE=$*
        fi
        CMD="set_simple_video_mode $MODE"
        ;;
esac

# ------------------------------------------------------------- run & log ---
OUTPUT=$(printf '%s\n' "$CMD" \
         | timeout "$NC_TIMEOUT" nc "$TARGET_IP" "$TARGET_PORT" 2>&1)
STATUS=$?

{
    printf '[%s] CMD: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$CMD"
    printf '%s\n' "$OUTPUT"
} | tee -a "$LOGFILE"

[ "$STATUS" -ne 0 ] && \
    echo "Command failed (exit $STATUS). Is the device reachable?" | \
    tee -a "$LOGFILE" >&2

exit "$STATUS"
