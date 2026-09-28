-- =============================================================================
-- hyprland/execs.lua
-- Autostart daemon management.
-- All autostart logic is deferred to the "hyprland.start" event so the
-- compositor is fully initialised before launching background processes.
-- =============================================================================

hl.on("hyprland.start", function()
    -- ── 1. dbus / systemd environment propagation ─────────────────────────
    -- Required so portal, polkit, and notification daemons see Wayland vars.
    hl.exec_cmd(
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
    )
    hl.exec_cmd(
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE"
    )

    -- ── 2. Polkit authentication agent ───────────────────────────────────
    -- Prefer the KDE agent; fall back to GNOME polkit; log if neither found.
    local polkit_kde   = "/usr/lib/polkit-kde-authentication-agent-1"
    local polkit_gnome = "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
    if is_file_exists(polkit_kde) then
        hl.exec_cmd(polkit_kde)
    elseif is_file_exists(polkit_gnome) then
        hl.exec_cmd(polkit_gnome)
    else
        io.stderr:write("[execs] WARNING: no polkit agent found. "
            .. "GUI apps requiring elevated privileges may not work.\n")
    end

    -- ── 3. Idle daemon ────────────────────────────────────────────────────
    -- hypridle handles screen lock / DPMS.
    local hypridle_ok = hl.exec_cmd_sync("command -v hypridle") or ""
    if hypridle_ok:match("hypridle") then
        hl.exec_cmd("pkill -x hypridle; hypridle")
    else
        io.stderr:write("[execs] WARNING: hypridle not found. Screen locking will not work.\n")
    end

    -- ── 4. Quickshell (shell widgets) ────────────────────────────────────
    -- qsConfig is defined in variables.lua (or custom override).
    local qs_cmd = string.format("qs -c %s", qsConfig or "default")
    local qs_ok = hl.exec_cmd_sync("command -v qs") or ""
    if qs_ok:match("qs") then
        hl.exec_cmd("pkill -x qs; " .. qs_cmd)
    else
        io.stderr:write("[execs] INFO: Quickshell (qs) not found. Shell widgets will not load.\n")
    end

    -- ── 5. Wallpaper daemon ───────────────────────────────────────────────
    -- Use swww-daemon if available; fall back to hyprpaper.
    local swww_ok = hl.exec_cmd_sync("command -v swww-daemon") or ""
    if swww_ok:match("swww") then
        -- swww-daemon is idempotent; safe to call even if already running.
        hl.exec_cmd("pkill -x swww-daemon; swww-daemon")
    else
        local hyprpaper_ok = hl.exec_cmd_sync("command -v hyprpaper") or ""
        if hyprpaper_ok:match("hyprpaper") then
            hl.exec_cmd("pkill -x hyprpaper; hyprpaper")
        else
            io.stderr:write("[execs] INFO: Neither swww-daemon nor hyprpaper found. "
                .. "Set a wallpaper manually.\n")
        end
    end

    -- ── 6. Input method (Fcitx5) ─────────────────────────────────────────
    local fcitx_ok = hl.exec_cmd_sync("command -v fcitx5") or ""
    if fcitx_ok:match("fcitx5") then
        hl.exec_cmd("pkill -x fcitx5; fcitx5 --daemon")
    end

    -- ── 7. Notification daemon ────────────────────────────────────────────
    -- Only start dunst if no notification daemon is already running via D-Bus.
    local dunst_ok = hl.exec_cmd_sync("command -v dunst") or ""
    if dunst_ok:match("dunst") then
        hl.exec_cmd("pkill -x dunst; dunst &")
    end

    -- ── 8. Night light / gamma ────────────────────────────────────────────
    local gammastep_ok = hl.exec_cmd_sync("command -v gammastep") or ""
    if gammastep_ok:match("gammastep") then
        hl.exec_cmd("pkill -x gammastep; gammastep -m wayland &")
    end
end)
