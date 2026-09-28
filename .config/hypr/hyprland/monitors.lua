-- =============================================================================
-- hyprland/monitors.lua
-- Monitor configuration with hotplug awareness.
--
-- INTEGRATION WITH nwg-displays:
--   nwg-displays writes its output to ~/.config/hypr/monitors.conf (a legacy
--   .conf file).  The installer symlinks it into place.  Hyprland 0.56 native
--   Lua does not auto-source .conf files, so the relevant monitor keywords are
--   re-applied here via hl.on("monitor.added", ...).
--
--   To persist a specific layout, run:
--     nwg-displays
--   then add wsbind / monitor entries in custom/variables.lua.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Default catch-all monitor rule
-- Matches any monitor that has no explicit rule.
-- ---------------------------------------------------------------------------
hl.config({
    monitor = {
        -- Empty name = apply to all monitors not matched by a specific rule
        name       = "",
        resolution = "preferred",
        position   = "auto",
        scale      = 1,
    },
})

-- ---------------------------------------------------------------------------
-- Laptop internal display heuristics
-- ---------------------------------------------------------------------------
-- eDP-* monitors are almost always HiDPI laptop panels.
-- A scale of 1.5 is a sensible starting point; adjust to taste.

local function _apply_edp_scale(mon)
    if not mon or not mon.name then return end
    if mon.name:match("^eDP") then
        hl.config({
            monitor = {
                name       = mon.name,
                resolution = "preferred",
                position   = "0x0",
                scale      = 1.5,
            },
        })
        io.stderr:write(string.format(
            "[monitors] Applied HiDPI scale 1.5 to laptop panel %s\n", mon.name))
    end
end

-- Apply to already-connected monitors at startup
do
    local monitors = pcall(hl.get_monitors) and hl.get_monitors() or {}
    for _, mon in ipairs(monitors) do
        _apply_edp_scale(mon)
    end
end

-- ---------------------------------------------------------------------------
-- Hotplug: re-apply rules whenever a monitor is connected
-- ---------------------------------------------------------------------------
hl.on("monitor.added", function(mon)
    if not mon then return end

    -- Re-apply the default catch-all (hyprland may not do this automatically
    -- for newly hotplugged monitors in all firmware configurations).
    hl.config({
        monitor = {
            name       = "",
            resolution = "preferred",
            position   = "auto",
            scale      = 1,
        },
    })

    -- Apply eDP scale for laptop panels
    _apply_edp_scale(mon)

    -- Notify the user so they can adjust via nwg-displays if desired.
    hl.exec_cmd(string.format(
        "notify-send 'Monitor connected' '%s — run nwg-displays to configure' -a Hyprland",
        tostring(mon.name or "unknown")
    ))
end)

-- ---------------------------------------------------------------------------
-- Monitor disconnected — let Hyprland handle workspace migration automatically
-- ---------------------------------------------------------------------------
hl.on("monitor.removed", function(mon)
    if not mon then return end
    hl.exec_cmd(string.format(
        "notify-send 'Monitor disconnected' '%s' -a Hyprland",
        tostring(mon.name or "unknown")
    ))
end)
