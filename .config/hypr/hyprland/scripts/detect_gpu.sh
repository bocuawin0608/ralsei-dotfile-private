#!/usr/bin/env bash
# detect_gpu.sh — Detect primary GPU vendor
# Outputs one of: nvidia, amd, intel, unknown
# Exit code is always 0
set -euo pipefail

detect_via_lspci() {
    if ! command -v lspci >/dev/null 2>&1; then return 1; fi
    local output
    output="$(lspci 2>/dev/null | grep -iE '(VGA|3D|Display)' || true)"
    if printf '%s' "$output" | grep -qi 'nvidia'; then
        printf 'nvidia'; return 0
    elif printf '%s' "$output" | grep -qiE '(amd|ati|radeon)'; then
        printf 'amd'; return 0
    elif printf '%s' "$output" | grep -qi 'intel'; then
        printf 'intel'; return 0
    fi
    return 1
}

detect_via_sysfs() {
    local drm_dir="/sys/class/drm"
    [[ -d "$drm_dir" ]] || return 1

    # Read vendor/device info from sysfs
    local vendor_file
    for vendor_file in "$drm_dir"/card*/device/vendor; do
        [[ -f "$vendor_file" ]] || continue
        local vendor_id
        vendor_id="$(cat "$vendor_file" 2>/dev/null | tr '[:upper:]' '[:lower:]')" || continue
        case "$vendor_id" in
            0x10de) printf 'nvidia'; return 0 ;;  # NVIDIA
            0x1002) printf 'amd';    return 0 ;;  # AMD
            0x8086) printf 'intel';  return 0 ;;  # Intel
        esac
    done

    # Try uevent for driver name
    local uevent
    for uevent in "$drm_dir"/card*/device/uevent; do
        [[ -f "$uevent" ]] || continue
        if grep -qi 'DRIVER=nvidia' "$uevent" 2>/dev/null; then
            printf 'nvidia'; return 0
        elif grep -qi 'DRIVER=amdgpu\|DRIVER=radeon' "$uevent" 2>/dev/null; then
            printf 'amd'; return 0
        elif grep -qi 'DRIVER=i915\|DRIVER=xe' "$uevent" 2>/dev/null; then
            printf 'intel'; return 0
        fi
    done
    return 1
}

detect_via_glxinfo() {
    if ! command -v glxinfo >/dev/null 2>&1; then return 1; fi
    local renderer
    renderer="$(glxinfo 2>/dev/null | grep -i 'OpenGL renderer' | head -1 || true)"
    if printf '%s' "$renderer" | grep -qi 'nvidia'; then
        printf 'nvidia'; return 0
    elif printf '%s' "$renderer" | grep -qiE '(amd|ati|radeon|rx [0-9])'; then
        printf 'amd'; return 0
    elif printf '%s' "$renderer" | grep -qi 'intel'; then
        printf 'intel'; return 0
    fi
    return 1
}

detect_via_modules() {
    if [[ -f /proc/modules ]]; then
        if grep -q '^nvidia ' /proc/modules 2>/dev/null; then
            printf 'nvidia'; return 0
        elif grep -qE '^(amdgpu|radeon) ' /proc/modules 2>/dev/null; then
            printf 'amd'; return 0
        elif grep -qE '^(i915|xe) ' /proc/modules 2>/dev/null; then
            printf 'intel'; return 0
        fi
    fi
    return 1
}

# ── Try detection methods in order of reliability ─────────────────────────────
if   detect_via_lspci   2>/dev/null; then exit 0
elif detect_via_sysfs   2>/dev/null; then exit 0
elif detect_via_modules 2>/dev/null; then exit 0
elif detect_via_glxinfo 2>/dev/null; then exit 0
else
    printf 'unknown'
    exit 0
fi
