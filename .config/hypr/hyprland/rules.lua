-- =============================================================================
-- hyprland/rules.lua
-- Window and layer rules.
-- All rules use windowrulev2 / layerrule via hl.add_window_rule / hl.add_layer_rule.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Helper: build a class regex selector
-- ---------------------------------------------------------------------------
local function cls(pattern)
    return string.format("class:^(%s)$", pattern)
end

local function cls_i(pattern) -- case-insensitive prefix
    return string.format("class:^(?i)(%s).*$", pattern)
end

local function title(pattern)
    return string.format("title:^(%s)$", pattern)
end

-- ---------------------------------------------------------------------------
-- 1. Float rules
-- ---------------------------------------------------------------------------
local float_classes = {
    "pavucontrol",
    "nm-connection-editor",
    "blueman-manager",
    "org.gnome.Calculator",
    "org.gnome.Nautilus",     -- file-chooser dialog instances
    "xdg-desktop-portal-gtk",
    "file-roller",
    "Yad",
    "yad",
    "zenity",
    "polkit-gnome-authentication-agent-1",
    "org.kde.polkit-kde-authentication-agent-1",
    "org.gnome.Characters",
    "gnome-control-center",
    "nwg-look",
    "qt5ct",
    "qt6ct",
    "kvantummanager",
}

for _, c in ipairs(float_classes) do
    hl.add_window_rule("float", cls(c))
    -- Centre floated dialogs
    hl.add_window_rule("center", cls(c))
end

-- Float by title (portal / save-as dialogs)
local float_titles = {
    "Open File",
    "Open Folder",
    "Save File",
    "Save As",
    "Save Image",
    "File Upload",
    "(?i)open",
    "(?i)save",
    "(?i)confirm",
    "(?i)properties",
}
for _, t in ipairs(float_titles) do
    hl.add_window_rule("float",  string.format("title:^(%s)$", t))
    hl.add_window_rule("center", string.format("title:^(%s)$", t))
end

-- All floating windows get centered (catch-all)
hl.add_window_rule("center",  "floating:1")

-- ---------------------------------------------------------------------------
-- 2. Per-app size hints for common dialogs
-- ---------------------------------------------------------------------------
hl.add_window_rule("size 900 600", cls("pavucontrol"))
hl.add_window_rule("size 800 600", cls("nm-connection-editor"))
hl.add_window_rule("size 700 500", cls("blueman-manager"))
hl.add_window_rule("size 400 300", cls("org.gnome.Calculator"))
hl.add_window_rule("size 600 400", cls("file-roller"))

-- ---------------------------------------------------------------------------
-- 3. Opacity rules — terminal emulators
-- ---------------------------------------------------------------------------
-- active_opacity inactive_opacity (space-separated in windowrulev2)
local transparent_terms = {
    "kitty",
    "alacritty",
    "foot",
    "wezterm",
    "org.wezfurlong.wezterm",
}

for _, c in ipairs(transparent_terms) do
    hl.add_window_rule("opacity 0.92 0.88", cls(c))
end

-- ---------------------------------------------------------------------------
-- 4. XWayland / suppress_event
-- ---------------------------------------------------------------------------
-- Suppress client-side fullscreen requests from legacy X apps.
hl.add_window_rule("suppressevent maximize", "xwayland:1")

-- ---------------------------------------------------------------------------
-- 5. Layer rules
-- ---------------------------------------------------------------------------

-- Blur layers
local blur_namespaces = {
    "waybar",
    "quickshell",
    "rofi",
    "dunst",
    "gtk-layer-shell",  -- GNOME shell-style surfaces
    "notifications",
}

for _, ns in ipairs(blur_namespaces) do
    hl.add_layer_rule("blur",       ns)
    hl.add_layer_rule("ignorezero", ns)
end

-- Waybar and quickshell: also ignore alpha for blur correctness
hl.add_layer_rule("ignorealpha 0.5", "waybar")
hl.add_layer_rule("ignorealpha 0.5", "quickshell")

-- ---------------------------------------------------------------------------
-- 6. Idle-inhibit rules
-- ---------------------------------------------------------------------------
-- Prevent screen lock when a video/game is running fullscreen.
hl.add_window_rule("idleinhibit fullscreen", "class:.*")
hl.add_window_rule("idleinhibit focus",      cls("mpv"))
hl.add_window_rule("idleinhibit focus",      cls("vlc"))

-- ---------------------------------------------------------------------------
-- 7. Picture-in-picture / always-on-top
-- ---------------------------------------------------------------------------
hl.add_window_rule("float",  title("Picture.in.Picture"))
hl.add_window_rule("pin",    title("Picture.in.Picture"))
hl.add_window_rule("size 480 270", title("Picture.in.Picture"))

-- ---------------------------------------------------------------------------
-- 8. Steam quirks
-- ---------------------------------------------------------------------------
hl.add_window_rule("float",          cls("steam"))
hl.add_window_rule("float",          string.format("class:^(steam)$, title:^((?!Steam$).*)$"))
hl.add_window_rule("nofocus",        string.format("class:^(steam)$, title:^(notificationtoasts.*)$"))
hl.add_window_rule("size 800 600",   string.format("class:^(steam)$, title:^(Friends List)$"))
