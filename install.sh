#!/usr/bin/env bash
# install.sh — Idempotent installer for ralsei dotfiles
# Usage: install.sh [--dry-run] [--minimal] [--full] [--uninstall] [--help]
set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 0. Meta
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
BACKUP_DIR="${HOME}/.config_backup_${TIMESTAMP}"
LOG_FILE="${HOME}/.local/log/ralsei-install-${TIMESTAMP}.log"

DRY_RUN=false
MODE="full"        # full | minimal
DO_UNINSTALL=false
INSTALLED_COUNT=0
SKIPPED_COUNT=0
LINKED_COUNT=0

# ── Terminal colors ────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
    CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'
    DIM='\033[2m'
else
    RED='' YELLOW='' GREEN='' CYAN='' BLUE='' BOLD='' RESET='' DIM=''
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1. Logging helpers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
mkdir -p "$(dirname "$LOG_FILE")"

_log_raw() { printf '%s\n' "$*" | tee -a "$LOG_FILE"; }

info()    { _log_raw "  ${CYAN}→${RESET}  $*"; }
ok()      { _log_raw "  ${GREEN}✓${RESET}  $*"; }
skip()    { _log_raw "  ${DIM}–${RESET}  $*"; (( SKIPPED_COUNT++ )) || true; }
warn()    { _log_raw "  ${YELLOW}⚠${RESET}  $*"; }
err()     { _log_raw "  ${RED}✗${RESET}  $*" >&2; }
section() { _log_raw ""; _log_raw "${BOLD}${BLUE}══ $* ══${RESET}"; }

dry_prefix() {
    $DRY_RUN && printf '[DRY-RUN] ' || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2. Argument parsing
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
usage() {
    cat <<'EOF'
ralsei dotfiles installer

Usage: install.sh [OPTIONS]

Options:
  --dry-run     Print every action without executing anything
  --minimal     Install only core components (hyprland, quickshell, fish)
  --full        Install all recommended + optional components (default)
  --uninstall   Remove symlinks created by this installer
  --help        Show this help

Examples:
  ./install.sh --dry-run --full
  ./install.sh --minimal
  ./install.sh --uninstall
EOF
}

for arg in "$@"; do
    case "$arg" in
        --dry-run)   DRY_RUN=true ;;
        --minimal)   MODE="minimal" ;;
        --full)      MODE="full" ;;
        --uninstall) DO_UNINSTALL=true ;;
        --help|-h)   usage; exit 0 ;;
        *)           err "Unknown argument: $arg"; usage; exit 1 ;;
    esac
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. OS + package manager detection
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
OS_ID=""
OS_LIKE=""
PKG_MGR=""
INSTALL_CMD=()

if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_LIKE="${ID_LIKE:-}"
fi

detect_pkg_manager() {
    if command -v pacman >/dev/null 2>&1; then
        PKG_MGR="pacman"
        INSTALL_CMD=(sudo pacman -S --noconfirm --needed)
    elif command -v apt >/dev/null 2>&1; then
        PKG_MGR="apt"
        INSTALL_CMD=(sudo apt install -y)
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
        INSTALL_CMD=(sudo dnf install -y)
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MGR="zypper"
        INSTALL_CMD=(sudo zypper install -y)
    else
        PKG_MGR="none"
    fi
}

detect_pkg_manager

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. Core helpers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# run CMD [args…] — executes only when not in dry-run
run() {
    if $DRY_RUN; then
        info "[DRY-RUN] Would run: $*"
    else
        "$@"
    fi
}

# make_dir PATH — create directory idempotently
make_dir() {
    local path="$1"
    if [[ -d "$path" ]]; then
        skip "Directory already exists: ${path/$HOME/~}"
    else
        info "$(dry_prefix)Creating directory: ${path/$HOME/~}"
        run mkdir -p "$path"
    fi
}

# backup_if_needed PATH — back up a real file/dir before we link over it
backup_if_needed() {
    local target="$1"
    # Skip if it doesn't exist or is already a symlink
    [[ -e "$target" && ! -L "$target" ]] || return 0
    local name
    name="$(basename "$target")"
    info "$(dry_prefix)Backing up: ${target/$HOME/~} → ${BACKUP_DIR/$HOME/~}/${name}"
    run mkdir -p "$BACKUP_DIR"
    run cp -r "$target" "${BACKUP_DIR}/${name}"
}

# safe_link SRC DST — idempotently create symlink SRC → DST
safe_link() {
    local src="$1"
    local dst="$2"

    if [[ ! -e "$src" ]]; then
        warn "Source not found, skipping link: ${src/$HOME/~}"
        return
    fi

    # Already correct symlink — nothing to do
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        skip "Link already correct: ${dst/$HOME/~}"
        return
    fi

    backup_if_needed "$dst"

    # Remove stale symlink pointing elsewhere
    if [[ -L "$dst" ]]; then
        info "$(dry_prefix)Removing stale symlink: ${dst/$HOME/~}"
        run rm "$dst"
    fi

    info "$(dry_prefix)Linking: ${src/$HOME/~} → ${dst/$HOME/~}"
    run mkdir -p "$(dirname "$dst")"
    run ln -sf "$src" "$dst"
    (( LINKED_COUNT++ )) || true
}

# install_pkg NAME [PKG_NAME] — install a package if command not found
install_pkg() {
    local cmd="$1"
    local pkg="${2:-$1}"

    if command -v "$cmd" >/dev/null 2>&1; then
        ok "${cmd} already installed"
        (( INSTALLED_COUNT++ )) || true
        return
    fi

    if [[ "$PKG_MGR" == "none" ]]; then
        warn "No package manager found; cannot install ${pkg} automatically"
        return
    fi

    info "$(dry_prefix)Installing: ${pkg}"
    if ! $DRY_RUN; then
        "${INSTALL_CMD[@]}" "$pkg" 2>&1 | tee -a "$LOG_FILE" || \
            warn "Package install failed for ${pkg} (may need AUR/manual install)"
        (( INSTALLED_COUNT++ )) || true
    fi
}

# make_executable FILE
make_executable() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        warn "Cannot chmod: file not found: ${file/$HOME/~}"
        return
    fi
    if [[ -x "$file" ]]; then
        skip "Already executable: $(basename "$file")"
    else
        info "$(dry_prefix)chmod +x: $(basename "$file")"
        run chmod +x "$file"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. Uninstall mode
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
uninstall() {
    section "Uninstall"
    warn "Removing symlinks created by ralsei installer…"
    warn "Your original files were backed up at install time — check ~/.config_backup_*"

    local links=(
        "${HOME}/.config/quickshell"
        "${HOME}/.config/hypr"
        "${HOME}/.config/fish"
        "${HOME}/.config/matugen"
        "${HOME}/.config/cava"
        "${HOME}/.config/hypr/hyprland/keybinds.lua"
    )

    for link in "${links[@]}"; do
        if [[ -L "$link" ]]; then
            info "$(dry_prefix)Removing symlink: ${link/$HOME/~}"
            run rm "$link"
        else
            skip "Not a symlink: ${link/$HOME/~}"
        fi
    done

    ok "Uninstall complete. Re-run without --uninstall to reinstall."
    exit 0
}

$DO_UNINSTALL && uninstall

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. Banner
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
cat <<BANNER

${BOLD}${CYAN}╭─────────────────────────────────────────╮
│    ralsei dotfiles installer            │
│    Mode: ${MODE}  |  Dry-run: ${DRY_RUN}         │
╰─────────────────────────────────────────╯${RESET}

  OS:      ${OS_ID:-unknown} (${OS_LIKE:-})
  Pkg mgr: ${PKG_MGR}
  Repo:    ${SCRIPT_DIR}
  Backup:  ${BACKUP_DIR/$HOME/~} (created on first backup)
  Log:     ${LOG_FILE/$HOME/~}

BANNER

$DRY_RUN && warn "DRY-RUN mode — no changes will be made."

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. Required directories
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Required directories"
make_dir "${HOME}/Pictures/Wallpapers"
make_dir "${HOME}/Pictures/Screenshots"
make_dir "${HOME}/Videos"
make_dir "${HOME}/.cache/matugen"
make_dir "${HOME}/.local/bin"
make_dir "${HOME}/.local/log"
make_dir "${HOME}/.local/share"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 8. Core dependencies
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Core dependencies"

# Hyprland — usually installed via distro packages or AUR
if command -v hyprland >/dev/null 2>&1; then
    ok "hyprland already installed"
else
    if [[ "$PKG_MGR" == "pacman" ]]; then
        warn "Hyprland not found. Install via: yay -S hyprland OR paru -S hyprland"
    else
        warn "Hyprland not found. Visit https://hyprland.org for install instructions."
    fi
fi

# Quickshell — typically from AUR or built from source
if command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1; then
    ok "quickshell already installed"
else
    if [[ "$PKG_MGR" == "pacman" ]]; then
        warn "Quickshell not found. Install via: yay -S quickshell-git"
    else
        warn "Quickshell not found. See https://quickshell.outfoxxed.me/docs/install"
    fi
fi

install_pkg fish fish
install_pkg pipewire pipewire
install_pkg wireplumber wireplumber

# XDG portal
if [[ "$PKG_MGR" == "pacman" ]]; then
    install_pkg xdg-desktop-portal-hyprland xdg-desktop-portal-hyprland
fi

# polkit
if command -v polkit >/dev/null 2>&1 || [[ -f /usr/lib/polkit-1/polkitd ]]; then
    ok "polkit available"
else
    if [[ "$PKG_MGR" == "pacman" ]]; then
        install_pkg polkit-kde-agent polkit-kde-agent
    else
        install_pkg polkit polkit
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 9. Recommended dependencies
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Recommended dependencies"

RECOMMENDED=(
    "matugen:matugen"
    "cava:cava"
    "grim:grim"
    "slurp:slurp"
    "wl-copy:wl-clipboard"
    "wl-paste:wl-clipboard"
    "cliphist:cliphist"
    "hyprpicker:hyprpicker"
    "playerctl:playerctl"
    "brightnessctl:brightnessctl"
    "hypridle:hypridle"
    "hyprlock:hyprlock"
    "swww:swww"
    "fuzzel:fuzzel"
    "jq:jq"
    "curl:curl"
    "starship:starship"
)

for entry in "${RECOMMENDED[@]}"; do
    cmd="${entry%%:*}"
    pkg="${entry##*:}"
    if [[ "$MODE" == "full" ]]; then
        install_pkg "$cmd" "$pkg"
    else
        if command -v "$cmd" >/dev/null 2>&1; then
            ok "${cmd} already installed"
        else
            skip "Skipping ${cmd} (--minimal mode)"
        fi
    fi
done

# wl-clip-persist — clipboard persistence daemon
if [[ "$MODE" == "full" ]]; then
    if command -v wl-clip-persist >/dev/null 2>&1; then
        ok "wl-clip-persist already installed"
    elif [[ "$PKG_MGR" == "pacman" ]]; then
        info "$(dry_prefix)Installing wl-clip-persist from AUR"
        if ! $DRY_RUN; then
            if command -v yay >/dev/null 2>&1; then
                yay -S --noconfirm --needed wl-clip-persist 2>&1 | tee -a "$LOG_FILE" || \
                    warn "wl-clip-persist install failed (AUR helper required)"
            else
                warn "wl-clip-persist: install via AUR helper: yay -S wl-clip-persist"
            fi
        fi
    else
        warn "wl-clip-persist: not in standard repos. Build from source if needed."
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 10. Optional dependencies
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Optional dependencies"

OPTIONAL=(
    "tesseract:tesseract"
    "wf-recorder:wf-recorder"
    "ydotool:ydotool"
    "ollama:ollama"
    "mpvpaper:mpvpaper"
)

for entry in "${OPTIONAL[@]}"; do
    cmd="${entry%%:*}"
    pkg="${entry##*:}"
    if command -v "$cmd" >/dev/null 2>&1; then
        ok "${cmd} already installed"
    else
        skip "${cmd} not installed (optional — install manually if needed: ${pkg})"
    fi
done

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 11. Make scripts executable
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Script permissions"

# Find all .sh files in the repo and make them executable
while IFS= read -r -d '' script; do
    make_executable "$script"
done < <(find "${SCRIPT_DIR}" -name '*.sh' -not -path '*/.git/*' -print0)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 12. Symlink config directories
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Symlinking config"

# Helper: link a config component directory or file
link_config() {
    local component="$1"           # relative to .config/ in repo and ~/.config/
    local src="${SCRIPT_DIR}/.config/${component}"
    local dst="${HOME}/.config/${component}"
    safe_link "$src" "$dst"
}

# ── Quickshell ─────────────────────────────────────────────────────────────────
link_config "quickshell"

# ── Hyprland ───────────────────────────────────────────────────────────────────
# We link the hyprland sub-directory, not the whole hypr/ tree,
# to avoid stomping on the user's hyprland.conf and monitors.conf
make_dir "${HOME}/.config/hypr"
safe_link \
    "${SCRIPT_DIR}/.config/hypr/hyprland" \
    "${HOME}/.config/hypr/hyprland"

# Link keybinds.lua separately (it lives at the repo root)
safe_link \
    "${SCRIPT_DIR}/keybinds.lua" \
    "${HOME}/.config/hypr/hyprland/keybinds.lua"

# ── Fish ───────────────────────────────────────────────────────────────────────
link_config "fish"

# ── Matugen ────────────────────────────────────────────────────────────────────
link_config "matugen"

# ── CAVA ──────────────────────────────────────────────────────────────────────
link_config "cava"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 13. Initialize theme
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Theme initialization"

SWITCHWALL="${HOME}/.config/quickshell/default/scripts/colors/switchwall.sh"
WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"
WALLPAPER_CACHE="${HOME}/.cache/current_wallpaper"

if [[ -f "$WALLPAPER_CACHE" ]]; then
    skip "Wallpaper cache already set: $(cat "$WALLPAPER_CACHE")"
else
    # Look for a default wallpaper in the repo
    DEFAULT_WALL=""
    for candidate in \
        "${SCRIPT_DIR}/wallpapers/default.jpg" \
        "${SCRIPT_DIR}/wallpapers/default.png" \
        "${SCRIPT_DIR}/wallpapers/default.webp" \
        "${SCRIPT_DIR}/.wallpaper"
    do
        if [[ -f "$candidate" ]]; then
            DEFAULT_WALL="$candidate"
            break
        fi
    done

    # Or pick from ~/Pictures/Wallpapers if any exist
    if [[ -z "$DEFAULT_WALL" ]]; then
        mapfile -t walls < <(
            find "$WALLPAPER_DIR" -maxdepth 2 -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
                2>/dev/null | head -1
        )
        [[ ${#walls[@]} -gt 0 ]] && DEFAULT_WALL="${walls[0]}"
    fi

    if [[ -n "$DEFAULT_WALL" && -f "$SWITCHWALL" ]]; then
        info "$(dry_prefix)Applying initial wallpaper: ${DEFAULT_WALL/$HOME/~}"
        if ! $DRY_RUN; then
            bash "$SWITCHWALL" "$DEFAULT_WALL" 2>&1 | tee -a "$LOG_FILE" || \
                warn "Initial wallpaper application failed (non-fatal)"
        fi
    else
        skip "No default wallpaper found — run 'wallpaper --random' after adding images to ~/Pictures/Wallpapers/"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 14. Fish shell setup
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Fish shell"

if command -v fish >/dev/null 2>&1; then
    FISH_PATH="$(command -v fish)"
    # Add fish to /etc/shells if not already present
    if grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null; then
        ok "fish in /etc/shells"
    else
        info "$(dry_prefix)Adding fish to /etc/shells: ${FISH_PATH}"
        run bash -c "echo '${FISH_PATH}' | sudo tee -a /etc/shells" || \
            warn "Could not add fish to /etc/shells (non-fatal; do manually)"
    fi

    # Offer to set fish as default shell — but never force it
    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 2>/dev/null || echo "$SHELL")"
    if [[ "$CURRENT_SHELL" == "$FISH_PATH" ]]; then
        ok "fish is already the default shell"
    else
        warn "Default shell is ${CURRENT_SHELL}. To switch: chsh -s ${FISH_PATH}"
    fi
else
    warn "fish not found; shell setup skipped"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 15. Validate (optional, non-blocking)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Validation"

VALIDATE_SCRIPT="${HOME}/.config/hypr/hyprland/scripts/dotfiles_validate.sh"
if [[ -f "$VALIDATE_SCRIPT" ]] && ! $DRY_RUN; then
    info "Running config validator…"
    bash "$VALIDATE_SCRIPT" 2>&1 | tee -a "$LOG_FILE" || \
        warn "Validation found issues (see log for details)"
else
    skip "Validation skipped (dry-run or script not yet linked)"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 16. Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
cat <<SUMMARY

${BOLD}${GREEN}══ Installation complete ══${RESET}

  Mode:      ${MODE}${DRY_RUN:+ (dry-run)}
  Symlinks:  ${LINKED_COUNT} created
  Skipped:   ${SKIPPED_COUNT} (already up to date)
  Log:       ${LOG_FILE/$HOME/~}

${BOLD}Next steps:${RESET}
  1. Add wallpapers to ~/Pictures/Wallpapers/
  2. Run: ${CYAN}wallpaper --random${RESET}   (in fish) or
          ${CYAN}switchwall.sh --random${RESET} (in bash)
  3. Start Hyprland and Quickshell
  4. Run: ${CYAN}dotfiles doctor${RESET}   to verify all components

SUMMARY

$DRY_RUN && warn "Dry-run complete — no files were modified."
