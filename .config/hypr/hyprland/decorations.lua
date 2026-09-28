-- =============================================================================
-- hyprland/decorations.lua
-- Visual decoration settings: rounding, blur, shadow, opacity, dim.
-- Per-app transparency is handled by window rules (rules.lua), not here.
-- The performance profile (performance.lua) may override blur/shadow settings.
-- =============================================================================

hl.config({
    decoration = {
        -- ── Rounded corners ──────────────────────────────────────────────
        rounding = 12,

        -- ── Active / inactive window opacity ────────────────────────────
        -- Keep at 1.0; per-app values live in rules.lua
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,

        -- ── Dim inactive ─────────────────────────────────────────────────
        -- Disabled globally; use per-app rules if dimming is desired.
        dim_inactive    = false,
        dim_strength    = 0.05,
        dim_special     = 0.4,
        dim_around      = 0.4,

        -- ── Drop shadow ──────────────────────────────────────────────────
        drop_shadow          = true,
        shadow_range         = 20,
        shadow_render_power  = 3,
        -- Shadow colour — ARGB hex (theme engine can override this)
        shadow_color         = "rgba(1a1a2eee)",
        shadow_inactive_color = "rgba(1a1a2e88)",
        shadow_offset        = "0, 4",
        shadow_scale         = 1.0,

        -- ── Blur ─────────────────────────────────────────────────────────
        -- Base "beautiful" values; performance.lua may reduce these.
        blur = {
            enabled           = true,
            size              = 8,
            passes            = 3,
            new_optimizations = true,
            xray              = false,
            ignore_opacity    = false,
            noise             = 0.01,
            contrast          = 1.0,
            brightness        = 1.0,
            vibrancy          = 0.15,
            vibrancy_darkness = 0.0,
            special           = false,  -- blur behind special workspaces
            popups            = true,
        },

        -- ── Screen shader (glow / colour grading) ────────────────────────
        -- Disabled by default; enable in performance profile "beautiful" or
        -- custom/env.lua by setting screen_shader to a GLSL file path.
        -- screen_shader = HOME .. "/.config/hypr/shaders/glow.glsl",
    },
})
