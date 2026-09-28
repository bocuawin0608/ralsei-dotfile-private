-- =============================================================================
-- hyprland/variables.lua
-- Application and shell variable definitions.
-- Override any of these in custom/variables.lua without editing this file.
-- =============================================================================

--- Default terminal emulator
terminal = "kitty"

--- Default web browser
browser = "firefox"

--- Default file manager
fileManager = "nautilus"

--- Default code / IDE editor
codeEditor = "code"

--- Default plain-text editor
textEditor = "gedit"

--- Default volume mixer / audio control GUI
volumeMixer = "pavucontrol"

--- Default system settings application
settingsApp = "gnome-control-center"

--- Default task / process manager
taskManager = "gnome-system-monitor"

--- Default office suite (e.g. LibreOffice Writer, onlyoffice-desktopeditors)
officeSoftware = os.getenv("OFFICE_SOFTWARE") or "libreoffice --writer"

--- Quickshell config name.  Can be overridden by QS_CONFIG env var or
--- by setting qsConfig in custom/variables.lua.
qsConfig = os.getenv("QS_CONFIG") or "default"

--- Quickshell scripts base path (derived from qsConfig, used in keybinds).
--- This is a shell-expanded string, not a Lua path.
qsScripts = "$HOME/.config/quickshell/" .. qsConfig .. "/scripts"
