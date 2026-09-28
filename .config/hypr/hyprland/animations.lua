-- =============================================================================
-- hyprland/animations.lua
-- Animation curves and window/workspace/layer animation configuration.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Bezier curves
-- ---------------------------------------------------------------------------
-- Syntax: bezier = <name>, <x0>, <y0>, <x1>, <y1>

hl.config({
    bezier = {
        -- Slightly overshoots then settles — good for windows
        overshot  = "0.05, 0.9, 0.1, 1.05",
        -- Fast start, slow end — good for closing / layer exit
        smoothOut = "0.5, 0, 1.0, 0.5",
        -- Slow start, fast end — good for fade-in
        smoothIn  = "0.5, -0.5, 0.5, 1.0",
        -- Spring-like overshoot — good for dramatic open effects
        spring    = "0.155, 1.105, 0.2, 1.001",
        -- Linear — for border colour transitions
        linear    = "0.0, 0.0, 1.0, 1.0",
        -- Ease-out cubic
        easeOut   = "0.22, 1.0, 0.36, 1.0",
    },
})

-- ---------------------------------------------------------------------------
-- Animations
-- ---------------------------------------------------------------------------
-- Syntax: animation = <event>, <enabled>, <speed>, <bezier> [, <style>]
-- speed unit: 10 ≈ 100ms (higher value = faster)

hl.config({
    animations = {
        enabled = true,

        -- ── Windows ────────────────────────────────────────────────────
        -- Open: slide in with spring overshoot
        ["animation:windowsIn"]    = "1, 5, spring, slide",
        -- Close: slide out fast
        ["animation:windowsOut"]   = "1, 4, smoothOut, slide",
        -- Move / resize
        ["animation:windowsMove"]  = "1, 4, easeOut",

        -- ── Fade ────────────────────────────────────────────────────────
        ["animation:fadeIn"]       = "1, 4, smoothIn",
        ["animation:fadeOut"]      = "1, 3, smoothOut",
        ["animation:fadeDim"]      = "1, 4, smoothIn",
        ["animation:fadeShadow"]   = "1, 4, easeOut",
        ["animation:fadeSwitch"]   = "0, 1, easeOut",  -- disable (causes flash)
        ["animation:fadeLayers"]   = "1, 3, smoothOut",

        -- ── Workspaces ──────────────────────────────────────────────────
        ["animation:workspaces"]   = "1, 4, overshot, slide",
        ["animation:specialWorkspace"] = "1, 4, overshot, slidevert",

        -- ── Layers (waybar, rofi, etc.) ─────────────────────────────────
        ["animation:layers"]       = "1, 3, smoothOut, slide",

        -- ── Border colour transition ─────────────────────────────────────
        ["animation:border"]       = "1, 10, linear",
        ["animation:borderangle"]  = "1, 100, linear, loop",
    },
})
