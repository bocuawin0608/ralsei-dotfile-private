#!/usr/bin/env bash
# install.sh — Fully Automated, Idempotent Installer for ralsei dotfiles
# Zero interactive prompts — 1-command complete setup
set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 0. Meta & Setup
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
BACKUP_DIR="${HOME}/.config_backup_${TIMESTAMP}"
LOG_FILE="${HOME}/.local/log/ralsei-install-${TIMESTAMP}.log"

DRY_RUN=false
MODE="full"
DO_UNINSTALL=false
INSTALLED_COUNT=0
SKIPPED_COUNT=0
LINKED_COUNT=0

# ── Colors ────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'; YELLOW='\033[0;33m'; GREEN='\033[0;32m'
    CYAN='\033[0;36m'; BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'
    DIM='\033[2m'
else
    RED='' YELLOW='' GREEN='' CYAN='' BLUE='' BOLD='' RESET='' DIM=''
fi

# ── Logging ────────────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$LOG_FILE")"

_log_raw() { printf '%s\n' "$*" | tee -a "$LOG_FILE"; }
info()    { _log_raw "  ${CYAN}→${RESET}  $*"; }
ok()      { _log_raw "  ${GREEN}✓${RESET}  $*"; }
skip()    { _log_raw "  ${DIM}–${RESET}  $*"; (( SKIPPED_COUNT++ )) || true; }
warn()    { _log_raw "  ${YELLOW}⚠${RESET}  $*"; }
err()     { _log_raw "  ${RED}✗${RESET}  $*" >&2; }
section() { _log_raw ""; _log_raw "${BOLD}${BLUE}══ $* ══${RESET}"; }

dry_prefix() { $DRY_RUN && printf '[DRY-RUN] ' || true; }

# ── Argument Parsing ──────────────────────────────────────────────────────────
usage() {
    cat <<'EOF'
ralsei dotfiles installer (automated, idempotent)

Usage: install.sh [OPTIONS]

Options:
  --dry-run     Print actions without modifying files or installing packages
  --minimal     Install core components only (hyprland, quickshell, fish)
  --full        Install all recommended + optional tools (default)
  --uninstall   Remove symlinks created by this installer
  --help        Show this help message
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
# 1. Package Manager Detection
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
# 2. Helpers
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
run() {
    if $DRY_RUN; then
        info "[DRY-RUN] Would run: $*"
    else
        "$@"
    fi
}

make_dir() {
    local path="$1"
    if [[ -d "$path" ]]; then
        skip "Directory already exists: ${path/$HOME/~}"
    else
        info "$(dry_prefix)Creating directory: ${path/$HOME/~}"
        run mkdir -p "$path"
    fi
}

backup_if_needed() {
    local target="$1"
    [[ -e "$target" && ! -L "$target" ]] || return 0
    local name
    name="$(basename "$target")"
    info "$(dry_prefix)Backing up: ${target/$HOME/~} → ${BACKUP_DIR/$HOME/~}/${name}"
    run mkdir -p "$BACKUP_DIR"
    run cp -r "$target" "${BACKUP_DIR}/${name}"
}

safe_link() {
    local src="$1"
    local dst="$2"

    if [[ ! -e "$src" ]]; then
        warn "Source not found, skipping link: ${src/$HOME/~}"
        return
    fi

    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        skip "Link already correct: ${dst/$HOME/~}"
        return
    fi

    backup_if_needed "$dst"

    if [[ -L "$dst" ]]; then
        info "$(dry_prefix)Removing stale symlink: ${dst/$HOME/~}"
        run rm "$dst"
    fi

    info "$(dry_prefix)Linking: ${src/$HOME/~} → ${dst/$HOME/~}"
    run mkdir -p "$(dirname "$dst")"
    run ln -sf "$src" "$dst"
    (( LINKED_COUNT++ )) || true
}

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

make_executable() {
    local file="$1"
    [[ ! -f "$file" ]] && return
    if [[ -x "$file" ]]; then
        skip "Already executable: $(basename "$file")"
    else
        info "$(dry_prefix)chmod +x: $(basename "$file")"
        run chmod +x "$file"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3. Uninstall mode
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
uninstall() {
    section "Uninstall"
    warn "Removing symlinks created by ralsei installer…"
    warn "Your original files were backed up at install time — check ~/.config_backup_*"

    while IFS= read -r -d '' item; do
        rel="${item#"${SCRIPT_DIR}/.config/"}"
        dst="${HOME}/.config/${rel}"
        if [[ -L "$dst" ]]; then
            info "$(dry_prefix)Removing symlink: ${dst/$HOME/~}"
            run rm "$dst"
        fi
    done < <(find "${SCRIPT_DIR}/.config" -maxdepth 1 -mindepth 1 -print0)

    if [[ -L "${HOME}/.config/hypr/hyprland/keybinds.lua" ]]; then
        run rm "${HOME}/.config/hypr/hyprland/keybinds.lua"
    fi

    ok "Uninstall complete."
    exit 0
}

$DO_UNINSTALL && uninstall

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 4. Banner
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
cat <<BANNER

${BOLD}${CYAN}╭─────────────────────────────────────────╮
│    ralsei dotfiles automated installer  │
│    Mode: ${MODE}  |  Dry-run: ${DRY_RUN}         │
╰─────────────────────────────────────────╯${RESET}

  OS:      ${OS_ID:-unknown} (${OS_LIKE:-})
  Pkg mgr: ${PKG_MGR}
  Repo:    ${SCRIPT_DIR}
  Backup:  ${BACKUP_DIR/$HOME/~}
  Log:     ${LOG_FILE/$HOME/~}

BANNER

$DRY_RUN && warn "DRY-RUN mode — no changes will be made."

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 5. Required directories
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Required directories"
make_dir "${HOME}/Pictures/Wallpapers"
make_dir "${HOME}/Pictures/Screenshots"
make_dir "${HOME}/Videos"
make_dir "${HOME}/.cache/matugen"
make_dir "${HOME}/.local/bin"
make_dir "${HOME}/.local/log"
make_dir "${HOME}/.local/share"
make_dir "${HOME}/.config"
make_dir "${HOME}/.config/hypr"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 6. Core dependencies
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Core dependencies"

if command -v hyprland >/dev/null 2>&1; then
    ok "hyprland already installed"
else
    if [[ "$PKG_MGR" == "pacman" ]]; then
        warn "Hyprland not found. Try: yay -S hyprland OR pacman -S hyprland"
    fi
fi

if command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1; then
    ok "quickshell already installed"
else
    if [[ "$PKG_MGR" == "pacman" ]]; then
        warn "Quickshell not found. Try: yay -S quickshell-git"
    fi
fi

install_pkg fish fish
install_pkg pipewire pipewire
install_pkg wireplumber wireplumber

if [[ "$PKG_MGR" == "pacman" ]]; then
    install_pkg xdg-desktop-portal-hyprland xdg-desktop-portal-hyprland
fi

if command -v polkit >/dev/null 2>&1 || [[ -f /usr/lib/polkit-1/polkitd ]]; then
    ok "polkit available"
else
    if [[ "$PKG_MGR" == "pacman" ]]; then
        install_pkg polkit-kde-agent polkit-kde-agent
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 7. Recommended & Optional Dependencies
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Recommended & optional packages"

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

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 8. Script permissions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Script permissions"
while IFS= read -r -d '' script; do
    make_executable "$script"
done < <(find "${SCRIPT_DIR}" -name '*.sh' -not -path '*/.git/*' -print0)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 9. Symlink all configurations automatically
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Deploying configuration files"

# Symlink every item inside .config/ to ~/.config/
if [[ -d "${SCRIPT_DIR}/.config" ]]; then
    while IFS= read -r -d '' item; do
        rel="$(basename "$item")"
        src="${item}"
        dst="${HOME}/.config/${rel}"
        safe_link "$src" "$dst"
    done < <(find "${SCRIPT_DIR}/.config" -maxdepth 1 -mindepth 1 -print0)
fi

# Link keybinds.lua to both root hyprland locations
safe_link "${SCRIPT_DIR}/keybinds.lua" "${HOME}/.config/hypr/hyprland/keybinds.lua"
safe_link "${SCRIPT_DIR}/keybinds.lua" "${HOME}/.config/hypr/keybinds.lua"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 10. Automatic Theme & Wallpaper Initialization
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Theme initialization"

SWITCHWALL="${HOME}/.config/quickshell/default/scripts/colors/switchwall.sh"
[[ ! -f "$SWITCHWALL" ]] && SWITCHWALL="${HOME}/.config/quickshell/ii/scripts/colors/switchwall.sh"
[[ ! -f "$SWITCHWALL" ]] && SWITCHWALL="${SCRIPT_DIR}/.config/quickshell/default/scripts/colors/switchwall.sh"

WALLPAPER_DIR="${HOME}/Pictures/Wallpapers"
WALLPAPER_CACHE="${HOME}/.cache/current_wallpaper"

if [[ -f "$WALLPAPER_CACHE" ]]; then
    skip "Wallpaper cache set: $(cat "$WALLPAPER_CACHE")"
else
    # Look for wallpapers in repo or Pictures
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
                warn "Initial wallpaper application non-fatal error"
        fi
    else
        # Run matugen template directly if matugen available to ensure colors.json exists
        if command -v matugen >/dev/null 2>&1 && [[ -f "${SCRIPT_DIR}/.config/matugen/config.toml" ]]; then
            info "$(dry_prefix)Initializing default Matugen color scheme"
            if ! $DRY_RUN; then
                # Create a blank fallback color image to extract default palette
                python3 -c "from PIL import Image; Image.new('RGB', (100, 100), color='#381E72').save('/tmp/ralsei_init.png')" 2>/dev/null || true
                if [[ -f /tmp/ralsei_init.png ]]; then
                    matugen image /tmp/ralsei_init.png --config "${SCRIPT_DIR}/.config/matugen/config.toml" --source-color-index 0 2>&1 | tee -a "$LOG_FILE" || true
                fi
            fi
        fi
        skip "Add wallpapers to ~/Pictures/Wallpapers/ and run 'wallpaper --random'"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 11. Fish Shell Environment
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Fish shell setup"

if command -v fish >/dev/null 2>&1; then
    FISH_PATH="$(command -v fish)"
    if grep -qxF "$FISH_PATH" /etc/shells 2>/dev/null; then
        ok "fish registered in /etc/shells"
    else
        info "$(dry_prefix)Adding fish to /etc/shells"
        run bash -c "echo '${FISH_PATH}' | sudo tee -a /etc/shells" || true
    fi

    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7 2>/dev/null || echo "$SHELL")"
    if [[ "$CURRENT_SHELL" == "$FISH_PATH" ]]; then
        ok "fish is default shell"
    else
        info "To set fish as default shell, run: chsh -s ${FISH_PATH}"
    fi
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 12. Automated Validation Check
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
section "Config validation"

VALIDATE_SCRIPT="${SCRIPT_DIR}/.config/hypr/hyprland/scripts/dotfiles_validate.sh"
if [[ -f "$VALIDATE_SCRIPT" ]] && ! $DRY_RUN; then
    info "Running config validation check…"
    bash "$VALIDATE_SCRIPT" 2>&1 | tee -a "$LOG_FILE" || true
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 13. Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
cat <<SUMMARY

${BOLD}${GREEN}══ Automated installation complete! ══${RESET}

  Mode:      ${MODE}${DRY_RUN:+ (dry-run)}
  Symlinks:  ${LINKED_COUNT} deployed to ~/.config/
  Skipped:   ${SKIPPED_COUNT} (already configured)
  Log:       ${LOG_FILE/$HOME/~}

${BOLD}Quick Start:${RESET}
  • Start Hyprland & Quickshell
  • Add wallpapers to ~/Pictures/Wallpapers/
  • Run ${CYAN}wallpaper --random${RESET} to switch theme
  • Run ${CYAN}dotfiles doctor${RESET} to verify system health

SUMMARY
