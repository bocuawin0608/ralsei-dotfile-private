-- =============================================================================
-- hyprland/misc.lua
-- Miscellaneous Hyprland compositor settings.
-- =============================================================================

hl.config({
    misc = {
        -- ── Branding ─────────────────────────────────────────────────────
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,   -- 0 = do not force; wallpaper daemon handles it

        -- ── Variable refresh rate ────────────────────────────────────────
        -- vfr: only render when something changes (saves power)
        vfr = true,
        -- vrr: 0 = off, 1 = always, 2 = fullscreen-only
        vrr = 2,

        -- ── DPMS wakeup ──────────────────────────────────────────────────
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
        always_follow_on_dnd    = true,

        -- ── Window behaviour ─────────────────────────────────────────────
        animate_manual_resizes         = true,
        animate_mouse_windowdragging   = true,
        enable_swallow                 = true,       -- terminal window swallowing
        swallow_regex                  = "^(kitty|alacritty|foot|wezterm)$",
        swallow_exception_regex        = "^(ranger|nnn|lf|yazi)$",
        focus_on_activate              = false,      -- don't steal focus on XDG activate
        no_direct_scanout              = false,      -- allow direct scanout (fullscreen perf)
        mouse_move_focuses_monitor     = true,

        -- ── Grouping behaviour ───────────────────────────────────────────
        groupbar_gradients             = false,

        -- ── Hyprland crash recovery ──────────────────────────────────────
        -- crash_reporter        = true, -- enabled by default in 0.56

        -- ── IPC & rendering ──────────────────────────────────────────────
        disable_autoreload             = false,  -- auto-reload config on change
        suppress_portal_warnings       = false,
        new_window_takes_over_fullscreen = 2,    -- 0=no, 1=unfull, 2=unfull+focus
        initial_workspace_tracking     = 1,
        middle_click_paste             = true,
    },

    -- ── Cursor ───────────────────────────────────────────────────────────
    cursor = {
        no_hardware_cursors = false,
        hotspot_padding     = 1,
        inactive_timeout    = 5,       -- hide cursor after 5s of inactivity
        no_warps            = false,
        persistent_warps    = false,
        warp_on_change_workspace = false,
        zoom_factor         = 1.0,
        zoom_rigid          = false,
        enable_hyprcursor   = true,    -- use hyprcursor if available
        sync_gsettings_theme = true,
    },
})
