#!/usr/bin/env bash
# dotfiles_doctor.sh — Diagnostics for ralsei dotfiles
# Checks all components and reports [OK] / [WARN] / [ERROR]
set -euo pipefail

# ── Colors ─────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    RED='' YELLOW='' GREEN='' CYAN='' BOLD='' RESET=''
fi

ERRORS=0
WARNS=0

ok()   { printf "${GREEN}[OK]${RESET}   %s\n"   "$*"; }
warn() { printf "${YELLOW}[WARN]${RESET} %s\n"  "$*"; (( WARNS++  )) || true; }
err()  { printf "${RED}[ERROR]${RESET} %s\n"    "$*"; (( ERRORS++ )) || true; }
section() { printf "\n${BOLD}${CYAN}── %s ──${RESET}\n" "$*"; }

# ── Helper: check binary ───────────────────────────────────────────────────────
check_cmd() {
    local name="$1"
    local severity="${2:-required}"  # required | recommended | optional
    if command -v "$name" >/dev/null 2>&1; then
        local ver
        ver="$(command "$name" --version 2>/dev/null | head -1 || true)"
        ok "${name}  ${ver:+(${ver})}"
    else
        case "$severity" in
            required)    err    "${name} not found (REQUIRED)" ;;
            recommended) warn   "${name} not found (recommended)" ;;
            optional)    warn   "${name} not found (optional)" ;;
        esac
    fi
}

# ── Helper: check file/symlink ─────────────────────────────────────────────────
check_file() {
    local path="$1"
    local label="${2:-$path}"
    if [[ -e "$path" ]]; then
        if [[ -L "$path" ]]; then
            local target
            target="$(readlink -f "$path")"
            ok "${label} → ${target}"
        else
            ok "${label}"
        fi
    else
        warn "${label} not found (${path})"
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
if [[ -d "${SCRIPT_DIR}/.config" ]]; then
    REPO_ROOT="${SCRIPT_DIR}"
    BASE_DIR="${SCRIPT_DIR}/.config"
else
    REPO_ROOT="${HOME}/.config/hypr/hyprland"
    BASE_DIR="${HOME}/.config"
fi

printf "${BOLD}ralsei dotfiles doctor${RESET}\n"
printf 'Date: %s\n' "$(date)"

# ── Core compositor ────────────────────────────────────────────────────────────
section "Core compositor"
check_cmd hyprland         required
check_cmd hyprctl          required
if command -v hyprland >/dev/null 2>&1; then
    VER="$(hyprland --version 2>/dev/null | head -1 || hyprctl version 2>/dev/null | grep -oP 'v[\d.]+' | head -1 || true)"
    [[ -n "$VER" ]] && ok "Hyprland version: ${VER}" || true
fi

# ── Shell ─────────────────────────────────────────────────────────────────────
section "Shell"
check_cmd fish             required
check_cmd starship         optional

# ── Quickshell ────────────────────────────────────────────────────────────────
section "Quickshell"
check_cmd qs               required
check_cmd quickshell       optional
check_file "${BASE_DIR}/quickshell"         "QS config dir"
QS_CONFIG="${QS_CONFIG:-default}"
check_file "${BASE_DIR}/quickshell/${QS_CONFIG}" "QS config (${QS_CONFIG})"

# ── Audio ─────────────────────────────────────────────────────────────────────
section "Audio"
check_cmd pipewire         required
check_cmd wireplumber      required
check_cmd wpctl            recommended
check_cmd playerctl        recommended
check_cmd pactl            optional

# ── Theme engine ──────────────────────────────────────────────────────────────
section "Theme"
check_cmd matugen          recommended
check_cmd cava             optional
check_file "${BASE_DIR}/matugen/config.toml"  "matugen config"
check_file "${HOME}/.cache/matugen/colors.json"   "matugen colors cache"

# ── Screenshot / Capture ──────────────────────────────────────────────────────
section "Screenshot / Capture"
check_cmd grim             recommended
check_cmd slurp            recommended
check_cmd hyprshot         optional
check_cmd hyprpicker       optional
check_cmd wf-recorder      optional
check_cmd tesseract        optional

# ── Clipboard ─────────────────────────────────────────────────────────────────
section "Clipboard"
check_cmd wl-copy          recommended
check_cmd wl-paste         recommended
check_cmd cliphist         recommended
check_cmd wl-clip-persist  optional

# ── Wallpaper backends ────────────────────────────────────────────────────────
section "Wallpaper"
WALLPAPER_FOUND=false
for be in swww hyprpaper swaybg feh; do
    if command -v "$be" >/dev/null 2>&1; then
        ok "$be (active backend)"
        WALLPAPER_FOUND=true
        break
    fi
done
$WALLPAPER_FOUND || err "No wallpaper backend found (need: swww | hyprpaper | swaybg | feh)"
check_file "${HOME}/Pictures/Wallpapers" "Wallpapers directory"
check_file "${HOME}/.cache/current_wallpaper" "Current wallpaper cache"

# ── Session / Lock ────────────────────────────────────────────────────────────
section "Session / Lock"
check_cmd hypridle         recommended
check_cmd hyprlock         recommended
check_cmd loginctl         required
check_cmd polkit           recommended

# ── XDG / Desktop portals ─────────────────────────────────────────────────────
section "XDG Portals"
check_cmd xdg-open         recommended
XDP_HYP="/usr/lib/xdg-desktop-portal-hyprland"
if [[ -x "$XDP_HYP" ]] || command -v xdg-desktop-portal-hyprland >/dev/null 2>&1; then
    ok "xdg-desktop-portal-hyprland"
else
    warn "xdg-desktop-portal-hyprland not found (recommended)"
fi

# ── Miscellaneous tools ────────────────────────────────────────────────────────
section "Miscellaneous"
check_cmd fuzzel           recommended
check_cmd brightnessctl    recommended
check_cmd ydotool          optional
check_cmd ollama           optional
check_cmd curl             recommended
check_cmd jq               recommended

# ── Config files ──────────────────────────────────────────────────────────────
section "Config files"
KEYBINDS_PATH="${REPO_ROOT}/keybinds.lua"
[[ ! -f "$KEYBINDS_PATH" ]] && KEYBINDS_PATH="${BASE_DIR}/hypr/hyprland/keybinds.lua"
check_file "$KEYBINDS_PATH"                                         "keybinds.lua"
check_file "${BASE_DIR}/cava/config"                                "cava config"
check_file "${BASE_DIR}/fish/config.fish"                           "fish config"
check_file "${BASE_DIR}/quickshell/${QS_CONFIG}/scripts/colors/switchwall.sh" "switchwall.sh"
check_file "${BASE_DIR}/hypr/hyprland/scripts/fuzzel-emoji.sh"      "fuzzel-emoji.sh"
check_file "${BASE_DIR}/hypr/hyprland/scripts/snip_to_search.sh"    "snip_to_search.sh"
check_file "${BASE_DIR}/hypr/hyprland/scripts/ai/primary-buffer-query.sh" "primary-buffer-query.sh"

# ── Summary ────────────────────────────────────────────────────────────────────
printf '\n%s\n' "$(printf '─%.0s' {1..50})"
if (( ERRORS > 0 )); then
    printf "${RED}${BOLD}%d error(s), %d warning(s)${RESET}\n" "$ERRORS" "$WARNS"
    exit 1
elif (( WARNS > 0 )); then
    printf "${YELLOW}${BOLD}0 errors, %d warning(s)${RESET}\n" "$WARNS"
    exit 0
else
    printf "${GREEN}${BOLD}All checks passed!${RESET}\n"
    exit 0
fi
