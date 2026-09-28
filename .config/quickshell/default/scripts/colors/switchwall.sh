#!/usr/bin/env bash
# switchwall.sh — Wallpaper switcher + theme generator
# Usage: switchwall.sh <wallpaper_path> | switchwall.sh --random
set -euo pipefail

LOG_FILE="${HOME}/.local/log/ralsei-theme.log"
WALLPAPER_CACHE="${HOME}/.cache/current_wallpaper"
WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"
QS_CONFIG="${QS_CONFIG:-default}"

# ── Logging ────────────────────────────────────────────────────────────────────
log() {
    mkdir -p "$(dirname "$LOG_FILE")"
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE" >&2
}

# ── Pick wallpaper ─────────────────────────────────────────────────────────────
WALLPAPER=""
if [[ "${1:-}" == "--random" ]]; then
    if [[ ! -d "$WALLPAPER_DIR" ]]; then
        log "ERROR: Wallpaper directory not found: $WALLPAPER_DIR"
        exit 1
    fi
    mapfile -t candidates < <(
        find "$WALLPAPER_DIR" -maxdepth 3 -type f \
            \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
               -o -iname '*.webp' -o -iname '*.gif' \) 2>/dev/null
    )
    if [[ ${#candidates[@]} -eq 0 ]]; then
        log "ERROR: No images found in $WALLPAPER_DIR"
        exit 1
    fi
    WALLPAPER="${candidates[RANDOM % ${#candidates[@]}]}"
elif [[ -n "${1:-}" ]]; then
    WALLPAPER="$1"
else
    # Fall back to cached wallpaper if no argument given
    if [[ -f "$WALLPAPER_CACHE" ]]; then
        WALLPAPER="$(cat "$WALLPAPER_CACHE")"
    else
        log "ERROR: No wallpaper specified and no cache found. Usage: switchwall.sh <path> | --random"
        exit 1
    fi
fi

# ── Validate ───────────────────────────────────────────────────────────────────
if [[ ! -f "$WALLPAPER" ]]; then
    log "ERROR: File not found: $WALLPAPER"
    exit 1
fi
log "Applying wallpaper: $WALLPAPER"

# ── Save to cache ──────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$WALLPAPER_CACHE")"
printf '%s' "$WALLPAPER" > "$WALLPAPER_CACHE"

# ── Apply via best available backend ──────────────────────────────────────────
if command -v swww >/dev/null 2>&1; then
    # Ensure swww-daemon is running
    if ! swww query >/dev/null 2>&1; then
        swww-daemon --no-cache &
        sleep 0.5
    fi
    swww img "$WALLPAPER" \
        --transition-type grow \
        --transition-pos 0.5,0.5 \
        --transition-duration 0.8 \
        --transition-fps 60
    log "Applied via swww"
elif command -v hyprpaper >/dev/null 2>&1; then
    hyprctl hyprpaper wallpaper ",$WALLPAPER"
    log "Applied via hyprpaper"
elif command -v swaybg >/dev/null 2>&1; then
    pkill swaybg 2>/dev/null || true
    swaybg -i "$WALLPAPER" -m fill &
    disown
    log "Applied via swaybg"
elif command -v feh >/dev/null 2>&1; then
    feh --bg-fill "$WALLPAPER"
    log "Applied via feh"
else
    log "ERROR: No wallpaper backend found (swww / hyprpaper / swaybg / feh)"
    exit 1
fi

# ── Generate theme via matugen ────────────────────────────────────────────────
if command -v matugen >/dev/null 2>&1; then
    MATUGEN_CONFIG="${HOME}/.config/matugen/config.toml"
    if [[ -f "$MATUGEN_CONFIG" ]]; then
        matugen image "$WALLPAPER" --config "$MATUGEN_CONFIG" && \
            log "matugen theme generated" || \
            log "WARN: matugen failed (non-fatal)"
    else
        matugen image "$WALLPAPER" && \
            log "matugen theme generated (no config)" || \
            log "WARN: matugen failed (non-fatal)"
    fi
else
    log "WARN: matugen not found — theme colors not regenerated"
fi

# ── Signal Quickshell ─────────────────────────────────────────────────────────
qs -c "${QS_CONFIG}" ipc call themeReloaded 2>/dev/null \
    && log "Signalled Quickshell: themeReloaded" \
    || true

# ── Reload CAVA colors ────────────────────────────────────────────────────────
pkill -SIGHUP cava 2>/dev/null && log "Sent SIGHUP to cava" || true

# ── Reload kitty theme ────────────────────────────────────────────────────────
pkill -SIGUSR1 kitty 2>/dev/null && log "Sent SIGUSR1 to kitty" || true

log "Wallpaper switch complete: $WALLPAPER"
