-- =============================================================================
-- hyprland/performance.lua
-- Performance profile system.
--
-- Set the active profile via the PERFORMANCE_PROFILE environment variable:
--   export PERFORMANCE_PROFILE=performance  # integrated GPU / battery
--   export PERFORMANCE_PROFILE=balanced     # (default) everyday use
--   export PERFORMANCE_PROFILE=beautiful    # dedicated GPU / desktop
--
-- You can also change the profile at runtime:
--   hyprctl keyword decoration:blur:enabled false
-- =============================================================================

local profile = os.getenv("PERFORMANCE_PROFILE") or "balanced"

-- ---------------------------------------------------------------------------
-- Profile definitions
-- ---------------------------------------------------------------------------

local profiles = {
    -- ── performance ─────────────────────────────────────────────────────
    -- Prioritises GPU/CPU headroom. Disables expensive post-processing.
    performance = {
        decoration = {
            blur = {
                enabled = false,
                size    = 3,
                passes  = 1,
            },
            drop_shadow         = false,
            shadow_range        = 0,
            shadow_render_power = 0,
            dim_inactive        = false,
        },
        animations = {
            enabled = true,
            -- Override global speed by setting a fast multiplier via custom
            -- bezier / animation entries.
            ["animation:windowsIn"]  = "1, 8, smoothOut, slide",
            ["animation:windowsOut"] = "1, 8, smoothOut, slide",
            ["animation:workspaces"] = "1, 8, smoothOut, slide",
            ["animation:layers"]     = "1, 6, smoothOut, slide",
        },
        misc = {
            vfr = true,
            vrr = 1,  -- always VRR when supported
        },
    },

    -- ── balanced ────────────────────────────────────────────────────────
    -- Default everyday profile: subtle blur, shadows, smooth animations.
    balanced = {
        decoration = {
            blur = {
                enabled           = true,
                size              = 5,
                passes            = 1,
                new_optimizations = true,
                xray              = false,
            },
            drop_shadow         = true,
            shadow_range        = 12,
            shadow_render_power = 2,
            dim_inactive        = false,
        },
        animations = {
            enabled = true,
            ["animation:windowsIn"]  = "1, 5, spring, slide",
            ["animation:windowsOut"] = "1, 4, smoothOut, slide",
            ["animation:workspaces"] = "1, 4, overshot, slide",
            ["animation:layers"]     = "1, 3, smoothOut, slide",
        },
        misc = {
            vfr = true,
            vrr = 2,  -- fullscreen only
        },
    },

    -- ── beautiful ────────────────────────────────────────────────────────
    -- Maximum eye-candy: full blur, large shadow, slower animations.
    beautiful = {
        decoration = {
            blur = {
                enabled           = true,
                size              = 8,
                passes            = 3,
                new_optimizations = true,
                xray              = false,
                vibrancy          = 0.2,
                vibrancy_darkness = 0.0,
                noise             = 0.02,
            },
            drop_shadow          = true,
            shadow_range         = 25,
            shadow_render_power  = 4,
            dim_inactive         = false,
        },
        animations = {
            enabled = true,
            ["animation:windowsIn"]  = "1, 4, spring, slide",
            ["animation:windowsOut"] = "1, 3, smoothOut, slide",
            ["animation:workspaces"] = "1, 3, overshot, slide",
            ["animation:layers"]     = "1, 3, smoothOut, slide",
        },
        misc = {
            vfr = true,
            vrr = 2,
        },
    },
}

-- ---------------------------------------------------------------------------
-- Apply the selected profile
-- ---------------------------------------------------------------------------

local selected = profiles[profile]
if not selected then
    io.stderr:write(string.format(
        "[performance] Unknown profile '%s', falling back to 'balanced'\n", profile))
    selected = profiles["balanced"]
end

io.stderr:write(string.format("[performance] Applying profile: %s\n", profile))
pcall(hl.config, selected)

-- Expose the active profile name for other modules
PERFORMANCE_PROFILE = profile
