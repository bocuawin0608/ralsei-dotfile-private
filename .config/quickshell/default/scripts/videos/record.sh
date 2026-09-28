#!/usr/bin/env bash
# record.sh — Screen recorder toggle using wf-recorder
# Usage: record.sh [--fullscreen] [--sound] [--region]
# Default: region capture (requires slurp + grim)
# Toggle: if already recording, stop gracefully
set -euo pipefail

SAVE_DIR="${HOME}/Videos"
TIMESTAMP="$(date '+%Y-%m-%d_%H.%M.%S')"
OUTPUT_FILE="${SAVE_DIR}/Recording_${TIMESTAMP}.mp4"
PIDFILE="/tmp/wf-recorder.pid"

# ── Dependency check ───────────────────────────────────────────────────────────
require() {
    command -v "$1" >/dev/null 2>&1 || {
        notify-send "record.sh" "Missing dependency: $1" --urgency=critical -a "recorder" 2>/dev/null || true
        printf 'ERROR: %s not found\n' "$1" >&2
        exit 1
    }
}
require wf-recorder

notify() {
    notify-send "${1}" "${2:-}" -a "recorder" 2>/dev/null || true
}

# ── Toggle: stop if already running ───────────────────────────────────────────
if [[ -f "$PIDFILE" ]]; then
    PID="$(cat "$PIDFILE")"
    if kill -0 "$PID" 2>/dev/null; then
        kill -SIGINT "$PID"
        sleep 0.5
        rm -f "$PIDFILE"
        notify "🔴 Recording stopped" "File saved to ~/Videos"
        exit 0
    else
        rm -f "$PIDFILE"
    fi
fi

# ── Parse flags ────────────────────────────────────────────────────────────────
DO_FULLSCREEN=false
DO_SOUND=false
DO_REGION=false

for arg in "$@"; do
    case "$arg" in
        --fullscreen) DO_FULLSCREEN=true ;;
        --sound)      DO_SOUND=true ;;
        --region)     DO_REGION=true ;;
    esac
done

# Default to region if no mode flag
if ! $DO_FULLSCREEN && ! $DO_REGION; then
    DO_REGION=true
fi

# ── Build wf-recorder command ──────────────────────────────────────────────────
mkdir -p "$SAVE_DIR"

WF_ARGS=()
WF_ARGS+=("--file=$OUTPUT_FILE")
WF_ARGS+=("--codec=libx264")

if $DO_SOUND; then
    if command -v pactl >/dev/null 2>&1; then
        AUDIO_SINK="$(pactl get-default-sink).monitor"
        WF_ARGS+=("--audio=$AUDIO_SINK")
    else
        WF_ARGS+=("--audio")
    fi
fi

if $DO_REGION; then
    require slurp
    REGION="$(slurp 2>/dev/null)" || {
        notify "Record cancelled" ""
        exit 0
    }
    WF_ARGS+=("--geometry=$REGION")
fi

# ── Start recording ────────────────────────────────────────────────────────────
notify "🔴 Recording started" "$(basename "$OUTPUT_FILE") — press keybind again to stop"

wf-recorder "${WF_ARGS[@]}" &
BGPID=$!
printf '%d' "$BGPID" > "$PIDFILE"
disown "$BGPID"
