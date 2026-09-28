#!/usr/bin/env bash
# dotfiles_validate.sh — Config validation for ralsei dotfiles
# Checks Lua syntax and QS config validity
# Exit 0 = clean, Exit 1 = errors found
set -euo pipefail

# ── Colors ─────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
    BOLD='\033[1m'; RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BOLD='' RESET=''
fi

ERRORS=0
WARNS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
if [[ -d "${SCRIPT_DIR}/.config" ]]; then
    REPO_ROOT="${SCRIPT_DIR}"
    BASE_DIR="${SCRIPT_DIR}/.config"
else
    REPO_ROOT="${HOME}/.config/hypr/hyprland"
    BASE_DIR="${HOME}/.config"
fi

HYPR_CFG="${BASE_DIR}/hypr/hyprland"
QS_SCRIPTS="${BASE_DIR}/quickshell/${QS_CONFIG:-default}/scripts"
FISH_CFG="${BASE_DIR}/fish"

pass() { printf "${GREEN}[PASS]${RESET} %s\n" "$*"; }
fail() { printf "${RED}[FAIL]${RESET} %s\n" "$*"; (( ERRORS++ )) || true; }
warn() { printf "${YELLOW}[WARN]${RESET} %s\n" "$*"; (( WARNS++  )) || true; }

# ── Lua syntax validation ──────────────────────────────────────────────────────
validate_lua() {
    local file="$1"
    local label="${2:-$file}"
    if [[ ! -f "$file" ]]; then
        warn "Lua file not found: ${label}"
        return
    fi
    if command -v luac >/dev/null 2>&1; then
        local output
        if output="$(luac -p "$file" 2>&1)"; then
            pass "Lua syntax OK: ${label}"
        else
            fail "Lua syntax error in ${label}:\n  ${output}"
        fi
    else
        warn "luac not found — skipping Lua syntax check for ${label}"
    fi
}

# ── TOML validation ────────────────────────────────────────────────────────────
validate_toml() {
    local file="$1"
    local label="${2:-$file}"
    if [[ ! -f "$file" ]]; then
        warn "TOML file not found: ${label}"
        return
    fi
    if command -v python3 >/dev/null 2>&1 && python3 -c 'import tomllib' 2>/dev/null; then
        local output
        if output="$(python3 -c "import tomllib; tomllib.load(open('${file}','rb'))" 2>&1)"; then
            pass "TOML syntax OK: ${label}"
        else
            fail "TOML syntax error in ${label}:\n  ${output}"
        fi
    elif command -v taplo >/dev/null 2>&1; then
        if taplo check "$file" >/dev/null 2>&1; then
            pass "TOML syntax OK: ${label}"
        else
            fail "TOML syntax error in ${label}"
        fi
    else
        warn "No TOML validator found (need python3 3.11+ or taplo) — skipping ${label}"
    fi
}

# ── Bash script syntax check ───────────────────────────────────────────────────
validate_bash() {
    local file="$1"
    local label="${2:-$file}"
    if [[ ! -f "$file" ]]; then
        warn "Script not found: ${label}"
        return
    fi
    local output
    if output="$(bash -n "$file" 2>&1)"; then
        pass "Bash syntax OK: ${label}"
    else
        fail "Bash syntax error in ${label}:\n  ${output}"
    fi
}

# ── Fish syntax check ──────────────────────────────────────────────────────────
validate_fish() {
    local file="$1"
    local label="${2:-$file}"
    if [[ ! -f "$file" ]]; then
        warn "Fish file not found: ${label}"
        return
    fi
    if command -v fish >/dev/null 2>&1; then
        local output
        if output="$(fish --no-execute "$file" 2>&1)"; then
            pass "Fish syntax OK: ${label}"
        else
            fail "Fish syntax error in ${label}:\n  ${output}"
        fi
    else
        warn "fish not found — skipping fish syntax check for ${label}"
    fi
}

# ── Quickshell config check ────────────────────────────────────────────────────
validate_quickshell() {
    local qs_config="${QS_CONFIG:-default}"
    local qs_dir="${BASE_DIR}/quickshell/${qs_config}"
    if [[ ! -d "$qs_dir" ]]; then
        warn "Quickshell config dir not found: ${qs_dir}"
        return
    fi
    if command -v qs >/dev/null 2>&1; then
        # qs --check is not universally supported; try it, fall back gracefully
        local output
        if output="$(qs --check -c "${qs_config}" 2>&1)"; then
            pass "Quickshell config valid (${qs_config})"
        else
            # Distinguish between "flag unsupported" and actual errors
            if printf '%s' "$output" | grep -qi 'unknown option\|unrecognized\|was not expected'; then
                warn "qs --check not supported by this qs version — skipping QS validation"
            else
                fail "Quickshell config error (${qs_config}):\n  ${output}"
            fi
        fi
    else
        warn "qs not found — skipping Quickshell config validation"
    fi
}

printf "${BOLD}ralsei dotfiles validator${RESET}\n\n"

# ── Lua files ──────────────────────────────────────────────────────────────────
printf "${BOLD}Lua files${RESET}\n"
KEYBINDS_FILE="${REPO_ROOT}/keybinds.lua"
[[ ! -f "$KEYBINDS_FILE" ]] && KEYBINDS_FILE="${HYPR_CFG}/keybinds.lua"
validate_lua "$KEYBINDS_FILE" "keybinds.lua"
# Validate all Lua files in the hyprland dir
if [[ -d "$HYPR_CFG" ]]; then
    while IFS= read -r -d '' f; do
        [[ "$f" == *keybinds.lua ]] && continue
        validate_lua "$f" "$(basename "$f")"
    done < <(find "$HYPR_CFG" -name '*.lua' -print0 2>/dev/null)
fi

# ── TOML files ─────────────────────────────────────────────────────────────────
printf "\n${BOLD}TOML files${RESET}\n"
validate_toml "${BASE_DIR}/matugen/config.toml" "matugen/config.toml"

# ── Bash scripts ───────────────────────────────────────────────────────────────
printf "\n${BOLD}Bash scripts${RESET}\n"
SCRIPTS=(
    "${QS_SCRIPTS}/colors/switchwall.sh"
    "${QS_SCRIPTS}/colors/random_wallpaper.sh"
    "${QS_SCRIPTS}/videos/record.sh"
    "${HYPR_CFG}/scripts/fuzzel-emoji.sh"
    "${HYPR_CFG}/scripts/snip_to_search.sh"
    "${HYPR_CFG}/scripts/ai/primary-buffer-query.sh"
    "${HYPR_CFG}/scripts/auth_failure_hook.sh"
    "${HYPR_CFG}/scripts/detect_gpu.sh"
    "${HYPR_CFG}/scripts/dotfiles_doctor.sh"
    "${HYPR_CFG}/scripts/dotfiles_validate.sh"
)
for script in "${SCRIPTS[@]}"; do
    validate_bash "$script" "$(basename "$script")"
done

# ── Fish config ────────────────────────────────────────────────────────────────
printf "\n${BOLD}Fish config${RESET}\n"
if [[ -d "$FISH_CFG" ]]; then
    while IFS= read -r -d '' f; do
        validate_fish "$f" "fish/$(basename "$(dirname "$f")")/$(basename "$f")"
    done < <(find "$FISH_CFG" -name '*.fish' -print0 2>/dev/null)
fi

# ── Quickshell ─────────────────────────────────────────────────────────────────
printf "\n${BOLD}Quickshell${RESET}\n"
validate_quickshell

# ── Summary ────────────────────────────────────────────────────────────────────
printf '\n%s\n' "$(printf '─%.0s' {1..50})"
if (( ERRORS > 0 )); then
    printf "${RED}${BOLD}Validation failed: %d error(s), %d warning(s)${RESET}\n" "$ERRORS" "$WARNS"
    exit 1
elif (( WARNS > 0 )); then
    printf "${YELLOW}${BOLD}Validation passed with %d warning(s)${RESET}\n" "$WARNS"
    exit 0
else
    printf "${GREEN}${BOLD}All validations passed!${RESET}\n"
    exit 0
fi
