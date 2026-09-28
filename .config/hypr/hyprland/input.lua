-- =============================================================================
-- hyprland/input.lua
-- Input device configuration: keyboard, mouse, touchpad, scroll.
-- Override individual settings in custom/variables.lua or custom/env.lua.
-- =============================================================================

-- Allow the user to specify a keyboard layout via environment variable.
local kb_layout  = os.getenv("KB_LAYOUT")  or "us"
local kb_variant = os.getenv("KB_VARIANT") or ""
local kb_options = os.getenv("KB_OPTIONS") or ""

hl.config({
    input = {
        -- ── Keyboard ─────────────────────────────────────────────────────
        kb_layout  = kb_layout,
        kb_variant = kb_variant,
        kb_options = kb_options,
        kb_model   = "",
        kb_rules   = "",

        -- Repeat settings
        repeat_rate  = 35,   -- characters per second while held
        repeat_delay = 300,  -- ms before repeat starts

        -- ── Mouse ────────────────────────────────────────────────────────
        follow_mouse   = 1,     -- focus follows mouse
        mouse_refocus  = true,
        float_switch_override_focus = 2,

        -- Pointer sensitivity: -1.0 (slow) .. 1.0 (fast), 0 = libinput default
        sensitivity = 0,
        accel_profile = "flat",  -- "flat" | "adaptive" | "custom"

        -- ── Touchpad ─────────────────────────────────────────────────────
        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
            tap_to_click         = true,
            drag_lock            = false,
            scroll_factor        = 1.0,
            middle_button_emulation = false,
            clickfinger_behavior = false,
            tap_button_map       = "lrm",  -- 1-finger=left, 2=right, 3=middle
        },

        -- ── Scroll ───────────────────────────────────────────────────────
        scroll_factor         = 1.0,
        scroll_method         = "2fg",   -- two-finger scroll
        natural_scroll        = false,   -- mouse wheel: keep standard direction

        -- ── Force no cursor on touch / pen ───────────────────────────────
        -- touch_only = false,
    },

    -- ── Gestures (touchpad / touchscreen) ────────────────────────────────
    gestures = {
        workspace_swipe            = true,
        workspace_swipe_fingers    = 3,
        workspace_swipe_distance   = 300,
        workspace_swipe_invert     = true,
        workspace_swipe_min_speed_to_force = 30,
        workspace_swipe_cancel_ratio = 0.5,
        workspace_swipe_create_new = true,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 10,
    },
})
