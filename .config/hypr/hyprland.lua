-- =============================================================================
-- hyprland.lua  (main entry point)
-- Loaded by Hyprland 0.56.2 as the native Lua configuration root.
-- The Lua package path is set so `require("hyprland.X")` resolves to
--   ~/.config/hypr/hyprland/X.lua
-- keybinds.lua lives at the repo root and is symlinked by the installer to
--   ~/.config/hypr/hyprland/keybinds.lua  — do NOT recreate it here.
-- =============================================================================

-- ── 1. Core API library ──────────────────────────────────────────────────────
-- Must be first: defines hl.*, HOME, is_file_exists, workspace_in_group.
require("hyprland.lib")

-- ── 2. Default variables ─────────────────────────────────────────────────────
-- Defines: terminal, browser, fileManager, codeEditor, textEditor,
--          volumeMixer, settingsApp, taskManager, officeSoftware, qsConfig
require("hyprland.variables")

-- ── 3. User variable overrides ───────────────────────────────────────────────
if is_file_exists(HOME .. "/.config/hypr/custom/variables.lua") then
    require("custom.variables")
end

-- ── 4. Environment variables ─────────────────────────────────────────────────
require("hyprland.env")

-- ── 5. User environment overrides ───────────────────────────────────────────
if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
    require("custom.env")
end

-- ── 6. Misc compositor settings ──────────────────────────────────────────────
require("hyprland.misc")

-- ── 7. Visual decorations ────────────────────────────────────────────────────
require("hyprland.decorations")

-- ── 8. Animations ────────────────────────────────────────────────────────────
require("hyprland.animations")

-- ── 9. Input devices ─────────────────────────────────────────────────────────
require("hyprland.input")

-- ── 10. Monitor configuration ────────────────────────────────────────────────
require("hyprland.monitors")

-- ── 11. Workspaces & layout ──────────────────────────────────────────────────
require("hyprland.workspaces")

-- ── 12. Performance profile ───────────────────────────────────────────────────
-- Loaded after decorations/animations so it can override them.
require("hyprland.performance")

-- ── 13. Window & layer rules ──────────────────────────────────────────────────
require("hyprland.rules")

-- ── 14. Anti-flashbang system ────────────────────────────────────────────────
require("hyprland.antiflasbang")

-- ── 15. Autostart daemons ────────────────────────────────────────────────────
require("hyprland.execs")

-- ── 16. Keybinds ────────────────────────────────────────────────────────────
-- The installer symlinks keybinds.lua (repo root) →
-- ~/.config/hypr/hyprland/keybinds.lua
-- It self-requires lib + variables at the top so it also works standalone.
require("hyprland.keybinds")
