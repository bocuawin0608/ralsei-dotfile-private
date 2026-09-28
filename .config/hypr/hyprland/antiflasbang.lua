-- =============================================================================
-- hyprland/antiflasbang.lua  (intentional typo matches spec)
-- Anti-flashbang system — prevents blinding white flashes when opening
-- browser/Electron windows in dark-mode environments.
--
-- Opt-in: set ANTIFLASBANG_ENABLED=1 in your environment or custom/env.lua.
-- The system briefly forces the window to 0 opacity immediately after open,
-- then restores it after a short settle delay so the compositor has time to
-- render the first frame correctly.
-- =============================================================================

-- Only activate when explicitly requested to avoid impacting all users.
if os.getenv("ANTIFLASBANG_ENABLED") ~= "1" then
    return
end

-- ---------------------------------------------------------------------------
-- Apps known to flash white on first frame
-- ---------------------------------------------------------------------------
local bright_apps = {
    -- Chromium-family browsers
    "chromium",
    "chromium%-browser",
    "google%-chrome",
    "google%-chrome%-stable",
    "brave%-browser",
    "brave",
    "microsoft%-edge",
    "opera",
    "vivaldi",
    -- Firefox (less common but possible)
    "firefox",
    "firefox%-esr",
    "librewolf",
    -- Electron shells
    "code",
    "code%-oss",
    "vscodium",
    "discord",
    "element",
    "slack",
    "teams%-for%-linux",
    "spotify",
    "obsidian",
    "notion%-app",
    "figma%-linux",
    "gitkraken",
    "cursor",
}

-- Build a pattern for fast lookup
local bright_pattern = "^(" .. table.concat(bright_apps, "|") .. ")$"

-- ---------------------------------------------------------------------------
-- Settle delay (ms) — time to wait before restoring full opacity.
-- Increase if flashes still occur on a slow machine.
-- ---------------------------------------------------------------------------
local SETTLE_MS = 200

-- ---------------------------------------------------------------------------
-- window.opened handler
-- ---------------------------------------------------------------------------
hl.on("window.opened", function(win)
    if not win then return end

    local class   = win.class   or ""
    local address = win.address or ""

    -- Only act on matched apps
    if not class:lower():match(bright_pattern) then return end
    if address == "" then return end

    -- Temporarily set opacity to 0 via a windowrule scoped to this address.
    -- windowrulev2 address selector: "address:0x<hex>"
    local addr_selector = string.format("address:0x%s", address)

    -- Apply instant-hide rule
    hl.add_window_rule("opacity 0.0 0.0", addr_selector)

    -- Schedule opacity restore after SETTLE_MS using a background sleep command.
    -- We use `sleep` + hyprctl to avoid blocking the Lua runtime.
    -- The rule is removed (overridden back to 1.0) after the delay.
    hl.exec_cmd(string.format(
        "sleep %.2f && hyprctl keyword windowrulev2 'opacity 1.0 1.0, address:0x%s'",
        SETTLE_MS / 1000.0,
        address
    ))
end)

io.stderr:write("[antiflasbang] Anti-flashbang system active\n")
