# 00-env.fish — Environment variables for Wayland/Hyprland/Qt
# Loaded by fish for every session (login + interactive)

# ── Wayland / Display ──────────────────────────────────────────────────────────
set -gx WAYLAND_DISPLAY wayland-0
set -gx XDG_CURRENT_DESKTOP Hyprland
set -gx XDG_SESSION_TYPE wayland
set -gx XDG_SESSION_DESKTOP Hyprland

# ── Qt ─────────────────────────────────────────────────────────────────────────
set -gx QT_QPA_PLATFORM 'wayland;xcb'
set -gx QT_WAYLAND_DISABLE_WINDOWDECORATION 1
set -gx QT_AUTO_SCREEN_SCALE_FACTOR 1

# ── GTK ────────────────────────────────────────────────────────────────────────
set -gx GDK_BACKEND 'wayland,x11'

# ── Firefox / Mozilla ──────────────────────────────────────────────────────────
set -gx MOZ_ENABLE_WAYLAND 1

# ── Electron / Chromium ────────────────────────────────────────────────────────
set -gx ELECTRON_OZONE_PLATFORM_HINT auto

# ── Cursor ─────────────────────────────────────────────────────────────────────
set -gx XCURSOR_SIZE 24
set -gx XCURSOR_THEME Adwaita

# ── Quickshell ─────────────────────────────────────────────────────────────────
set -gx QS_CONFIG default

# ── XDG user dirs ─────────────────────────────────────────────────────────────
set -gx XDG_DATA_HOME "$HOME/.local/share"
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_CACHE_HOME "$HOME/.cache"
set -gx XDG_STATE_HOME "$HOME/.local/state"

# ── PATH additions (idempotent — fish_add_path skips duplicates) ───────────────
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.go/bin
