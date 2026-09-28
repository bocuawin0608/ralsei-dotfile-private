-- =============================================================================
-- hyprland/env.lua
-- Wayland / Qt / GTK / Electron environment variable exports.
-- Applied via hl.config({ env = {...} }) so hyprctl keyword env is used.
-- Override or extend in custom/env.lua without touching this file.
-- =============================================================================

hl.config({
    env = {
        -- ── Wayland session identity ──────────────────────────────────────
        { "XDG_CURRENT_DESKTOP",              "Hyprland"       },
        { "XDG_SESSION_TYPE",                 "wayland"        },
        { "XDG_SESSION_DESKTOP",              "Hyprland"       },

        -- ── Qt ────────────────────────────────────────────────────────────
        -- Prefer Wayland; fall back to XCB so Qt apps still work on XWayland
        { "QT_QPA_PLATFORM",                  "wayland;xcb"    },
        { "QT_WAYLAND_DISABLE_WINDOWDECORATION", "1"           },
        { "QT_AUTO_SCREEN_SCALE_FACTOR",      "1"              },
        { "QT_QPA_PLATFORMTHEME",             "gtk3"           },

        -- ── GTK / GDK ────────────────────────────────────────────────────
        { "GDK_BACKEND",                      "wayland,x11,*"  },

        -- ── Firefox / Mozilla ────────────────────────────────────────────
        { "MOZ_ENABLE_WAYLAND",               "1"              },
        { "MOZ_DBUS_REMOTE",                  "1"              },

        -- ── Electron / Chromium ──────────────────────────────────────────
        { "ELECTRON_OZONE_PLATFORM_HINT",     "auto"           },
        { "NIXOS_OZONE_WL",                   "1"              }, -- NixOS compat, harmless elsewhere

        -- ── SDL ──────────────────────────────────────────────────────────
        { "SDL_VIDEODRIVER",                  "wayland,x11"    },

        -- ── Clutter (GNOME) ──────────────────────────────────────────────
        { "CLUTTER_BACKEND",                  "wayland"        },

        -- ── Cursor ───────────────────────────────────────────────────────
        { "XCURSOR_SIZE",                     "24"             },
        { "XCURSOR_THEME",                    "Adwaita"        },

        -- ── Quickshell ───────────────────────────────────────────────────
        { "QS_CONFIG",                        qsConfig or "default" },

        -- ── Java / AWT (fixes blank windows in some Java GUIs) ───────────
        { "_JAVA_AWT_WM_NONREPARENTING",      "1"              },
    },
})
