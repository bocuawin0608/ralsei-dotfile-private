# Ralsei Dotfile — Root Orchestrator Skill

> **Status:** Constitution of the repository. Every AI agent operating on this codebase MUST read this document before making any change. No exceptions.

---

## Table of Contents

1. [Purpose and Scope](#1-purpose-and-scope)
2. [Repository Discovery Rules](#2-repository-discovery-rules)
3. [Existing Skill Integration](#3-existing-skill-integration)
4. [System Architecture](#4-system-architecture)
5. [Directory Structure](#5-directory-structure)
6. [Hyprland Rules](#6-hyprland-rules)
7. [Authoritative Keymap](#7-authoritative-keymap)
8. [Quickshell Architecture](#8-quickshell-architecture)
9. [QML Architecture](#9-qml-architecture)
10. [Theme Architecture](#10-theme-architecture)
11. [Wallpaper Architecture](#11-wallpaper-architecture)
12. [CAVA Integration](#12-cava-integration)
13. [AI Desktop Integration](#13-ai-desktop-integration)
14. [Subtitle and Media Overlay](#14-subtitle-and-media-overlay)
15. [Screen Translation and OCR](#15-screen-translation-and-ocr)
16. [Google Lens Integration](#16-google-lens-integration)
17. [Security Architecture](#17-security-architecture)
18. [Anti-Flashbang System](#18-anti-flashbang-system)
19. [Authentication Failure Reaction](#19-authentication-failure-reaction)
20. [Fish Shell Architecture](#20-fish-shell-architecture)
21. [Installation](#21-installation)
22. [Dependency Management](#22-dependency-management)
23. [Environment Detection](#23-environment-detection)
24. [Multi-Monitor Support](#24-multi-monitor-support)
25. [Performance Engineering](#25-performance-engineering)
26. [Low-RAM Mode](#26-low-ram-mode)
27. [Hardware Adaptation](#27-hardware-adaptation)
28. [Update Compatibility](#28-update-compatibility)
29. [Configuration Validation and Rollback](#29-configuration-validation-and-rollback)
30. [Logging and Diagnostics](#30-logging-and-diagnostics)
31. [Testing Strategy](#31-testing-strategy)
32. [Development Workflow](#32-development-workflow)
33. [Extension Guidelines](#33-extension-guidelines)
34. [Anti-Patterns](#34-anti-patterns)
35. [Visual Design Language](#35-visual-design-language)
36. [Definition of Done](#36-definition-of-done)
37. [Engineering Checklist](#37-engineering-checklist)
38. [Performance Checklist](#38-performance-checklist)
39. [Security Checklist](#39-security-checklist)
40. [Compatibility Checklist](#40-compatibility-checklist)
41. [UI/UX Checklist](#41-uiux-checklist)
42. [Pre-Commit Checklist](#42-pre-commit-checklist)
43. [Pre-Reload Checklist](#43-pre-reload-checklist)
44. [Pre-Release Checklist](#44-pre-release-checklist)

---

## 1. Purpose and Scope

This document is the **constitution** of the Ralsei dotfile repository. It acts as an orchestrator over every specialized skill in `.agentskill/` and defines the architectural decisions that govern the entire desktop environment.

**Target system:**
- Compositor: Hyprland **0.56.2** (Lua configuration, Aquamarine rendering)
- Shell UI: **Quickshell** (QtQuick/QML)
- Color theming: **Matugen** (Material Design 3 palette from wallpaper)
- Audio visualization: **CAVA** + PipeWire
- Shell: **Fish**

**What this skill teaches an AI agent:**
- What the system does and why it is designed this way
- Where every category of code belongs
- How every subsystem communicates
- How to safely extend the system without breaking it
- How to detect and avoid conflicts, regressions, and security issues

---

## 2. Repository Discovery Rules

Before making **any** change, an AI agent MUST perform the following discovery sequence:

```
Step 1 — Read this file (skill.md) completely.
Step 2 — Read every skill in .agentskill/:
          .agentskill/hyprland/SKILL.md      → Hyprland 0.56.2 Lua API, rendering, IPC
          .agentskill/lua/SKILL.md           → Lua idioms, naming, error handling
          .agentskill/quickshell/SKILL.md    → Quickshell/QML architecture
          .agentskill/ui/SKILL.md            → UI design principles
          .agentskill/ux/SKILL(3).md         → UX design principles
Step 3 — Read keybinds.lua completely.
Step 4 — Identify which subsystem the task touches.
Step 5 — Read the relevant subsystem files.
Step 6 — Plan the minimal change.
Step 7 — Validate against all checklists at the bottom of this document.
```

> [!IMPORTANT]
> Never skip Step 2. The `.agentskill/` skills are authoritative domain knowledge. This root skill orchestrates them; it does not replace them.

### Skill Dependency Map

```
skill.md  (this file — root orchestrator)
    ├── .agentskill/hyprland/SKILL.md   → All Hyprland Lua config, IPC, rendering decisions
    ├── .agentskill/lua/SKILL.md        → All Lua code style and patterns in keybinds.lua
    ├── .agentskill/quickshell/SKILL.md → All Quickshell/QML decisions in the shell
    ├── .agentskill/ui/SKILL.md         → Visual hierarchy, contrast, accessibility
    └── .agentskill/ux/SKILL(3).md      → Interaction design, cognitive load, feedback
```

---

## 3. Existing Skill Integration

### How skills interact

| Skill | Domain | When to activate |
|---|---|---|
| `hyprland/SKILL.md` | Compositor, Lua API, window rules, IPC | Any change to `.config/hypr/**` |
| `lua/SKILL.md` | Lua style, tables, error handling | Any change to `*.lua` files |
| `quickshell/SKILL.md` | QML architecture, multi-monitor, services | Any change to `.config/quickshell/**` |
| `ui/SKILL.md` | Visual hierarchy, color, typography | Any new Quickshell UI component |
| `ux/SKILL(3).md` | Interaction patterns, cognitive load | Any new interactive behavior |

### Skill authority hierarchy

```
hyprland/SKILL.md  →  compositor-level truth (no override)
lua/SKILL.md       →  Lua code style truth (no override)
quickshell/SKILL.md → QML/shell truth (no override)
ui/SKILL.md        →  visual design guidelines (extends quickshell)
ux/SKILL(3).md     →  interaction design guidelines (extends ui)
skill.md (this)    →  system-level orchestration and cross-cutting concerns
```

> [!NOTE]
> If a decision in this file appears to conflict with a specialized skill, the specialized skill wins for its domain. Open an engineering discussion; do not silently override.

---

## 4. System Architecture

### Component hierarchy

```
Hyprland 0.56.2  (Wayland compositor, window manager, Lua engine)
    │
    ├─ Window Management (Dwindle/Master layout, rules, floating)
    ├─ Workspace Model (10 workspaces per group, special scratchpad)
    ├─ Keybind Dispatch (keybinds.lua → hl.bind() → hl.dsp.*)
    ├─ IPC Events (hl.on() → event-driven automation)
    └─ Environment Export (dbus-update-activation-environment)
           │
           ▼
    Quickshell  (QtQuick/QML shell runtime)
           │
           ├─ Top Bar (workspace indicator, system status, clock, media)
           ├─ Bottom Bar (launcher hint, notifications, tray)
           ├─ Overview (workspace + window previews, search)
           ├─ App Launcher (fuzzy search, calculator, shell commands)
           ├─ Clipboard Viewer (cliphist integration)
           ├─ Emoji Picker (fuzzel fallback)
           ├─ Sidebar Left (AI panel, media controls)
           ├─ Sidebar Right (notification center, control center)
           ├─ Media Controls Panel (playerctl)
           ├─ Wallpaper Selector (thumbnail grid + apply)
           ├─ Session Menu (lock, sleep, shutdown)
           ├─ OSK (on-screen keyboard)
           ├─ Subtitle Overlay (YouTube/media subtitles, audio-reactive)
           ├─ Screen Translation Overlay
           ├─ Region Screenshot / OCR / Google Lens workflow
           ├─ Widget Overlay (CTRL+G canvas widgets)
           └─ Cheatsheet (SUPER+Slash)
           │
           ▼
    Theme Engine
           │
           ├─ Wallpaper backend (swww / hyprpaper / mpvpaper)
           ├─ Matugen (Material Design 3 palette extraction)
           ├─ Generated palette → Hyprland decoration colors
           ├─ Generated palette → Quickshell Theme singleton
           ├─ Generated palette → Terminal (kitty/foot color scheme)
           ├─ Generated palette → CAVA gradient colors
           ├─ Generated palette → GTK/Qt application theming
           └─ Generated palette → CSS/SCSS (if used)
```

### Communication paths

| From | To | Mechanism |
|---|---|---|
| Hyprland keybind | Quickshell | `qs ipc call <signal>` |
| Quickshell | Hyprland | `hyprctl dispatch` or Hyprland IPC socket |
| Wallpaper change | Matugen | Script invocation |
| Matugen output | Quickshell | Generated config file, `FileView` watcher |
| Matugen output | CAVA | Generated config file, SIGHUP or restart |
| Matugen output | Terminal | Symlink swap or SIGHUP |
| PipeWire | CAVA | Direct audio capture |
| CAVA | Quickshell subtitle overlay | Named pipe / IPC |
| AI service | Quickshell | HTTP REST (async Process) |
| Hyprland events | Quickshell | Quickshell Hyprland IPC singleton |

> [!IMPORTANT]
> IPC from Hyprland to Quickshell always goes via `qs ipc call`. The keybind pattern in `keybinds.lua` is authoritative:
> ```lua
> hl.bind("SUPER + Tab", hl.dsp.global("quickshell:overviewWorkspacesToggle"))
> ```
> Quickshell signals are namespaced `quickshell:<signalName>`.

---

## 5. Directory Structure

```
~/.config/
├── hypr/
│   ├── hyprland.lua          # Main Hyprland entry point
│   ├── monitors.lua          # Monitor configuration (hotplug-aware)
│   ├── workspaces.lua        # Workspace layout (nwg-displays compatible)
│   ├── hyprland/             # Core abstractions library
│   │   ├── lib.lua           # hl.* API (hl.bind, hl.config, hl.dsp.*)
│   │   ├── variables.lua     # terminal, browser, fileManager, etc.
│   │   ├── env.lua           # Environment variable exports
│   │   ├── execs.lua         # Autostart daemons
│   │   ├── rules.lua         # Window and layer rules
│   │   └── keybinds.lua      # Source of keybind truth (symlinked from repo root keybinds.lua)
│   └── custom/               # Machine-local overrides (gitignored)
│       ├── variables.lua
│       ├── env.lua
│       └── rules.lua
│
├── quickshell/
│   └── <qsConfig>/           # Active shell config (e.g. "default")
│       ├── shell.qml         # Entry point
│       ├── welcome.qml       # Welcome screen
│       ├── services/         # Headless singletons
│       │   ├── Hyprland.qml
│       │   ├── Audio.qml
│       │   ├── Network.qml
│       │   ├── Notifications.qml
│       │   ├── Media.qml
│       │   ├── AI.qml
│       │   ├── Subtitle.qml
│       │   └── Theme.qml     # Material Design 3 token singleton
│       ├── components/       # Dumb reusable UI primitives
│       ├── widgets/          # Smart themed domain widgets
│       ├── panels/           # Top-level PanelWindow assemblies
│       │   ├── TopBar.qml
│       │   ├── BottomBar.qml
│       │   ├── Overview.qml
│       │   ├── Launcher.qml
│       │   ├── SidebarLeft.qml
│       │   ├── SidebarRight.qml
│       │   ├── SubtitleOverlay.qml
│       │   └── SessionMenu.qml
│       ├── scripts/          # Shell scripts called from QML
│       │   ├── colors/
│       │   │   └── switchwall.sh
│       │   └── videos/
│       │       └── record.sh
│       └── assets/
│           ├── icons/
│           └── fonts/
│
├── fish/
│   ├── config.fish           # Minimal bootstrap only
│   ├── conf.d/               # Auto-sourced modules
│   └── functions/            # Autoloaded functions
│
├── cava/
│   └── config                # Generated by theme engine (do not hand-edit)
│
├── matugen/
│   └── config.toml           # Matugen template configuration
│
└── kitty/ (or foot/)
    └── kitty.conf (or foot.ini)   # Terminal — generated theme section
```

```
<repo_root>/
├── .agentskill/              # Specialized AI skills
├── keybinds.lua              # ← AUTHORITATIVE KEYMAP (symlinked into hypr/)
├── install.sh                # Idempotent installer
├── skill.md                  # THIS FILE
└── LICENSE
```

```
~/Pictures/Wallpapers/        # Default wallpaper library
~/Videos/                     # Recordings output
~/Pictures/Screenshots/       # Screenshot output
```

---

## 6. Hyprland Rules

> [!IMPORTANT]
> Read `.agentskill/hyprland/SKILL.md` before touching **any** Hyprland configuration. The rules in that skill are authoritative for the compositor layer.

### Configuration language

**This project uses Hyprland 0.56.2 native Lua.**

- Do NOT write `.conf` syntax. It is deprecated in 0.56.2.
- Do NOT invent a "Hyprland Lua" API that does not exist. Verify against `hyprctl repl`.
- The `hl.*` library (`lib.lua`) wraps native dispatchers. Use it.

```lua
-- CORRECT
hl.config({ decoration = { rounding = 10 } })
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Window: Close" })

-- WRONG — .conf syntax in a .lua context
-- bind = SUPER, Q, killactive
```

### Window rules

Define in `~/.config/hypr/hyprland/rules.lua`:

```lua
hl.add_window_rule("float", "class:^(pavucontrol)$")
hl.add_window_rule("float", "class:^(nm-connection-editor)$")
hl.add_window_rule("suppress_event", "class:^(xwayland_app)$")
hl.add_window_rule("no_auto_hdr", "class:^(mpv)$")
hl.add_window_rule("opacity 0.92 override 0.88 override", "class:^(kitty)$")
```

Rules for opacity/transparency must maintain readable contrast. See §18.

### Layer rules

```lua
hl.add_layer_rule("blur", "quickshell")
hl.add_layer_rule("ignorezero", "quickshell")
```

### Workspace model

- 10 workspaces per group (configurable via `workspace_in_group(i)` function in `lib.lua`)
- Special workspace `special:special` used as scratchpad
- Workspace IDs are relative (`r+1`, `r-1`) to support dynamic groups
- Monitor-relative workspace switching via `m+1`/`m-1`

### Event automation

Use `hl.on(event, handler)`. Do NOT use polling loops.

```lua
hl.on("window.opened", function(win)
    -- React to new windows event-driven
end)

hl.on("monitor.disconnected", function(mon)
    -- Migrate workspaces to primary monitor
end)
```

---

## 7. Authoritative Keymap

**File:** [`keybinds.lua`](file:///home/loliconhihi/Documents/Project/ralsei-dotfile-private/keybinds.lua) — This is the single source of truth for all keybindings.

> [!CAUTION]
> Never introduce a new binding without first scanning `keybinds.lua` for conflicts. Duplicate bindings on the same modifier+key combination cause silent shadowing.

### Keymap summary (extracted from keybinds.lua)

**Shell / Quickshell IPC signals:**

| Binding | Signal / Action | Description |
|---|---|---|
| `SUPER + SUPER_L/R` | `quickshell:searchToggleRelease` | Toggle search/overview |
| `SUPER + Tab` | `quickshell:overviewWorkspacesToggle` | Toggle workspace overview |
| `SUPER + V` | `quickshell:overviewClipboardToggle` | Toggle clipboard viewer |
| `SUPER + Period` | `quickshell:overviewEmojiToggle` | Toggle emoji picker |
| `SUPER + A / B / O` | `quickshell:sidebarLeftToggle` | Toggle left sidebar |
| `SUPER + ALT + A` | `quickshell:sidebarLeftToggleDetach` | Detach left sidebar |
| `SUPER + N` | `quickshell:sidebarRightToggle` | Toggle right sidebar |
| `SUPER + Slash` | `quickshell:cheatsheetToggle` | Toggle cheatsheet |
| `SUPER + K` | `quickshell:oskToggle` | Toggle on-screen keyboard |
| `SUPER + M` | `quickshell:mediaControlsToggle` | Toggle media controls |
| `SUPER + G` | `quickshell:overlayToggle` | Toggle widget overlay |
| `CTRL + ALT + Delete` | `quickshell:sessionToggle` | Toggle session menu |
| `SUPER + J` | `quickshell:barToggle` | Toggle bar visibility |
| `CTRL + SUPER + T` | `quickshell:wallpaperSelectorToggle` | Open wallpaper selector |
| `CTRL + SUPER + ALT + T` | `quickshell:wallpaperSelectorRandom` | Random wallpaper |
| `CTRL + SUPER + SHIFT + D` | `quickshell:toggleLightDark` | Toggle light/dark mode |
| `CTRL + SUPER + R` | (restart qs) | Restart Quickshell |
| `CTRL + SUPER + P` | `quickshell:panelFamilyCycle` | Cycle panel family |
| `SUPER + SHIFT + S` | `quickshell:regionScreenshot` | Screen snip |
| `SUPER + SHIFT + A` | `quickshell:regionSearch` | Google Lens region |
| `SUPER + SHIFT + X` | `quickshell:regionOcr` | OCR to clipboard |
| `SUPER + SHIFT + T` | `quickshell:screenTranslate` | Screen translation |
| `SUPER + SHIFT + R` | `quickshell:regionRecord` | Record region |

**Media:**

| Binding | Action |
|---|---|
| `XF86AudioRaiseVolume` | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5` |
| `XF86AudioLowerVolume` | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-` |
| `XF86AudioMute` | `wpctl set-mute @DEFAULT_SINK@ toggle` |
| `XF86AudioMicMute` / `SUPER + ALT + M` | Toggle microphone mute |
| `SUPER + SHIFT + P` / `XF86AudioPlay` | `playerctl play-pause` |
| `SUPER + SHIFT + N` / `XF86AudioNext` | `playerctl next` |
| `SUPER + SHIFT + B` / `XF86AudioPrev` | `playerctl previous` |
| `XF86MonBrightnessUp/Down` | `qs ipc call brightness increment/decrement` |

**Window management:**

| Binding | Action |
|---|---|
| `SUPER + Q` | Close window |
| `SUPER + SHIFT + ALT + Q` | Force kill (`hyprctl kill`) |
| `SUPER + Arrows` | Focus direction |
| `SUPER + SHIFT + Arrows` | Move window direction |
| `SUPER + ALT + Space` | Toggle float/tile |
| `SUPER + D` | Toggle maximized |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + ALT + F` | Fullscreen spoof (client reports fullscreen) |
| `SUPER + P` | Pin window |
| `SUPER + Minus / Equal` | Zoom out/in (cursor zoom) |

**Workspace switching:**

| Binding | Action |
|---|---|
| `SUPER + 1..0` | Focus workspace 1–10 (group-relative) |
| `SUPER + code:10..19` | Same via raw keycodes |
| `CTRL + SUPER + Left/Right` | Focus workspace left/right |
| `SUPER + Page_Down/Up` | Focus workspace left/right |
| `SUPER + Scroll` | Focus workspace |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + ALT + 1..0` | Send window to workspace |
| `SUPER + SHIFT + Page_Up/Down` | Send window to workspace left/right |

**Session:**

| Binding | Action |
|---|---|
| `SUPER + L` | Lock session (`loginctl lock-session`) |
| `SUPER + SHIFT + L` | Suspend |
| `CTRL + ALT + Delete` | Session menu (or wlogout fallback) |
| `CTRL + SHIFT + ALT + SUPER + Delete` | Power off |

**Apps:**

| Binding | App variable |
|---|---|
| `SUPER + Return` / `SUPER + T` / `CTRL + ALT + T` | `terminal` |
| `SUPER + E` | `fileManager` |
| `SUPER + W` | `browser` |
| `SUPER + C` | `codeEditor` |
| `SUPER + X` | `textEditor` |
| `CTRL + SUPER + V` | `volumeMixer` |
| `SUPER + I` | `settingsApp` |
| `CTRL + SHIFT + Escape` | `taskManager` |

**Utilities:**

| Binding | Action |
|---|---|
| `SUPER + SHIFT + C` | Color picker (`hyprpicker -a`) |
| `Print` | Screenshot to clipboard |
| `CTRL + Print` | Screenshot to file + clipboard |
| `CTRL + ALT + R` | Record fullscreen (no sound) |
| `SUPER + SHIFT + ALT + R` | Record fullscreen (with sound) |
| `SUPER + ALT + F11/F12` | Test notifications |
| `SUPER + ALT + F1` | Toggle virtual machine submap |
| `SUPER + SHIFT + ALT + mouse:273` | AI summary for selected text |

**Virtual machine submap:**

- `SUPER + ALT + F1` — enter/exit VM submap (all keybinds disabled inside)

### Keybind conflict detection rules

Before adding a new binding:

1. `grep -n "SUPER + <KEY>" keybinds.lua` — check for exact modifier match
2. Check for `ignore_mods = true` bindings (e.g. `SUPER_L`) that may shadow others
3. Check submap context — binds inside `hl.define_submap()` do not conflict with global binds
4. Check `release = true` bindings — they use the key-release event, not key-press
5. Check `transparent = true` bindings — they pass the event through
6. Check `non_consuming = true` — event is not consumed after handling
7. Check `locked = true` — binding works even on lock screen
8. Document every new binding with `{ description = "Category: Action" }`

### Fallback pattern

The keymap uses a dual-dispatch pattern for every major Quickshell signal:

```lua
-- Primary: Quickshell IPC
hl.bind("SUPER + V", hl.dsp.global("quickshell:overviewClipboardToggle"))
-- Fallback: native command if Quickshell is not alive
hl.bind("SUPER + V", hl.dsp.exec_cmd(
    qsIsAlive .. " || pkill fuzzel || cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"
))
```

**Always maintain this pattern.** New bindings that call Quickshell IPC must have a graceful fallback.

---

## 8. Quickshell Architecture

> [!IMPORTANT]
> Read `.agentskill/quickshell/SKILL.md` completely before writing any QML. That skill is authoritative for all Quickshell/QML decisions.

### Configuration variable

The active Quickshell config is selected by the `$qsConfig` environment variable.

```lua
-- keybinds.lua
local qsScripts = "$HOME/.config/quickshell/$qsConfig/scripts"
local qsIpcCall = "qs -c $qsConfig ipc call"
local qsIsAlive = qsIpcCall .. " TEST_ALIVE"
```

Always reference scripts via `$qsConfig`. Never hardcode a config name.

### Shell surface model

```
Quickshell surfaces (layer-shell):
├── TopBar          — top, exclusive zone = bar height
├── BottomBar       — bottom, exclusive zone = bar height
├── Overview        — full screen, keyboard interactive
├── Launcher        — centered overlay, keyboard interactive
├── SidebarLeft     — left edge, slides in/out
├── SidebarRight    — right edge, slides in/out
├── SessionMenu     — centered overlay
├── SubtitleOverlay — top of screen, pass-through input
└── ScreenTranslate — full screen, pass-through input
```

### IPC signal registry

All signals that Hyprland can send to Quickshell via `qs ipc call`:

```
quickshell:searchToggleRelease
quickshell:workspaceNumber
quickshell:overviewWorkspacesToggle
quickshell:overviewClipboardToggle
quickshell:overviewEmojiToggle
quickshell:sidebarLeftToggle
quickshell:sidebarLeftToggleDetach
quickshell:sidebarRightToggle
quickshell:cheatsheetToggle
quickshell:oskToggle
quickshell:mediaControlsToggle
quickshell:overlayToggle
quickshell:sessionToggle
quickshell:barToggle
quickshell:wallpaperSelectorToggle
quickshell:wallpaperSelectorRandom
quickshell:toggleLightDark
quickshell:panelFamilyCycle
quickshell:regionScreenshot
quickshell:regionSearch
quickshell:regionOcr
quickshell:screenTranslate
quickshell:regionRecord
TEST_ALIVE                           ← Used as health check; must always respond
brightness increment
brightness decrement
```

When implementing a new feature that requires a keybind-to-Quickshell call, register a new signal name in this list and implement the IPC handler in `shell.qml` or a dedicated `Scope`.

### Restart command

```lua
-- keybinds.lua
hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("killall ydotool qs quickshell; qs -c $qsConfig &"))
```

Quickshell restarts cleanly. Ephemeral UI state is intentionally discarded. Persistent state must be written to disk before restart.

---

## 9. QML Architecture

> [!IMPORTANT]
> Read `.agentskill/quickshell/SKILL.md` sections 13–17 for the authoritative component architecture.

### Module layout

```
shell.qml          # Empty orchestrator — mounts services and per-screen variants
services/          # Headless pragma Singleton QML files
components/        # Pure UI primitives — no business logic
widgets/           # Domain UI — reads from services, emits signals up
panels/            # PanelWindow assemblies — mounts widgets
scripts/           # Shell scripts called from QML via Process
```

### Dependency direction (enforced)

```
System (sockets, processes, DBus)
    ↓
Service (singleton: owns state, exposes properties/functions)
    ↓
Widget (reads service properties, emits user action signals)
    ↓
Panel (assembles widgets into layer-shell window)
    ↓
shell.qml (mounts panels via Variants { model: Quickshell.screens })
```

**FORBIDDEN:** A Service directly modifying a Panel by ID. A Widget owning a Process.

### Theme singleton

```qml
// services/Theme.qml
pragma Singleton
import QtQuick

QtObject {
    // Material Design 3 semantic tokens — all populated by Matugen output
    property color primary:           "#006494"
    property color onPrimary:         "#FFFFFF"
    property color primaryContainer:  "#C7E7FF"
    property color secondary:         "#4A6174"
    property color surface:           "#F7FAFE"
    property color surfaceContainer:  "#EBF2F9"
    property color surfaceVariant:    "#DCE4ED"
    property color onSurface:         "#181C1F"
    property color outline:           "#70787E"
    property color error:             "#BA1A1A"

    // Design system tokens
    property int   radius:            12
    property int   spacing:           8
    property real  opacity:           0.92
    property int   animDuration:      220
    property string fontFamily:       "Inter"
}
```

Never write a color literal anywhere except `Theme.qml`. Reference as `color: Theme.primary`.

### Multi-monitor boilerplate (required)

```qml
// Any panel that must appear on all monitors
Variants {
    model: Quickshell.screens
    delegate: Component {
        TopBar {
            required property var modelData
            screen: modelData
        }
    }
}
```

Move all `Process`, state, and timers to a global `Scope` or singleton. See `.agentskill/quickshell/SKILL.md` §6.

### Process execution rules

```qml
// CORRECT — array form, no shell injection
Process { command: ["playerctl", "next"]; running: true }

// WRONG — shell injection vector, spawns extra sh process
Process { command: ["bash", "-c", "playerctl next"]; running: true }
```

Exception: Complex piping that cannot be expressed as an array may use `["bash", "-c", "..."]` only when the argument is a **static string literal**, never user input.

---

## 10. Theme Architecture

### Material Design 3 token flow

```
1. User selects wallpaper (via wallpaper selector or script)
2. matugen image <wallpaper_path> generates color palette
3. Generated tokens written to ~/.config/matugen/colors.json (or equivalent)
4. Theme engine script reads tokens and distributes to all subsystems:
   a. Quickshell Theme.qml → runtime property update via FileView watcher
   b. Hyprland decoration colors → hyprctl keyword or config reload
   c. Terminal (kitty/foot) → generated color scheme file, SIGHUP
   d. CAVA → generated config section, SIGHUP or restart
   e. GTK → generated ~/.config/gtk-3.0/colors.css
5. No full desktop restart required
```

### Dark / light mode

Toggled via `CTRL + SUPER + SHIFT + D` → `quickshell:toggleLightDark`.

The Theme singleton exposes `property bool isDark: true`. Matugen supports both dark and light schemes. The toggle regenerates the appropriate palette without re-running wallpaper extraction.

### Color token usage rules

| Token name | Semantic purpose |
|---|---|
| `primary` | Main interactive element color |
| `onPrimary` | Text/icon on primary color |
| `primaryContainer` | Tinted container for primary content |
| `secondary` | Secondary interactive elements |
| `surface` | Default window/panel background |
| `surfaceContainer` | Slightly elevated surfaces (cards) |
| `surfaceVariant` | Chip backgrounds, input fills |
| `onSurface` | Default text color |
| `outline` | Borders, dividers |
| `error` | Error states |

Do NOT invent new semantic tokens unless documenting them here.

### Transparency rules

- Terminal: `opacity 0.92 active, 0.88 inactive` (window rule)
- Bars: background `color: Qt.rgba(r, g, b, 0.85)` with blur
- Overlays: `color: Qt.rgba(r, g, b, 0.72)` with blur
- Text must always satisfy WCAG 2.1 AA contrast (minimum 4.5:1 ratio)
- Do NOT apply transparency to text content areas

---

## 11. Wallpaper Architecture

### Backend detection

```bash
# Priority order
command -v swww     && WALLPAPER_BACKEND=swww
command -v hyprpaper && WALLPAPER_BACKEND=hyprpaper
command -v mpvpaper  && WALLPAPER_BACKEND=mpvpaper
command -v glpaper   && WALLPAPER_BACKEND=glpaper
# Fail gracefully if none available
```

### Wallpaper change flow

```bash
# scripts/colors/switchwall.sh (called by Quickshell or keybind fallback)
#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="$1"

# 1. Apply wallpaper via detected backend
case "$WALLPAPER_BACKEND" in
    swww)     swww img "$WALLPAPER" --transition-type grow ;;
    hyprpaper) hyprctl hyprpaper wallpaper ",$WALLPAPER" ;;
    mpvpaper)  pkill mpvpaper; mpvpaper - "$WALLPAPER" & ;;
esac

# 2. Run Matugen
matugen image "$WALLPAPER" --config ~/.config/matugen/config.toml

# 3. Notify Quickshell to reload theme
qs -c "$QS_CONFIG" ipc call themeReloaded || true

# 4. Reload CAVA (SIGHUP or restart)
pkill -SIGHUP cava 2>/dev/null || true

# 5. Reload terminal theme (SIGHUP kitty)
pkill -SIGUSR1 kitty 2>/dev/null || true
```

> [!CAUTION]
> Never call this script more than once per wallpaper selection event. Matugen is CPU-intensive.

### Wallpaper selector (Quickshell)

- Opened via `CTRL + SUPER + T` → `quickshell:wallpaperSelectorToggle`
- Random wallpaper via `CTRL + SUPER + ALT + T` → `quickshell:wallpaperSelectorRandom`
- Reads from `~/Pictures/Wallpapers/` by default
- Supports PNG, JPG, WEBP, GIF
- Animated wallpapers: detected by extension or metadata; routed to mpvpaper if available
- Thumbnail grid using `Image { fillMode: Image.PreserveAspectCrop }`
- Applies via `Process { command: [script, wallpaperPath] }`

---

## 12. CAVA Integration

CAVA reads from PipeWire and renders an ASCII/braille spectrum.

### Configuration generation

CAVA color configuration must be **generated** by the theme engine, never hand-edited:

```ini
# Generated section in ~/.config/cava/config
[color]
gradient = 1
gradient_count = 2
gradient_color_1 = '#<primary_hex>'
gradient_color_2 = '#<secondary_hex>'
```

After Matugen runs, extract primary/secondary hex values and overwrite the `[color]` section. Send `SIGHUP` to CAVA to reload without restart.

### Audio-reactive subtitle integration

CAVA can output to a named pipe or stdout in raw format. The Quickshell Subtitle overlay reads this data for audio-reactive animations:

```bash
# CAVA raw output mode for IPC to Quickshell
cava -p ~/.config/cava/config-pipe
```

The subtitle overlay uses this as a low-frequency amplitude signal, not raw PCM. Update rate should be 30Hz maximum. The QML animation layer translates amplitude to scale/glow properties.

---

## 13. AI Desktop Integration

### Provider architecture

```
AI Panel (Quickshell sidebar)
    │
    ├─ Gemini provider (HTTP REST, async Process)
    │       └─ API key: $GEMINI_API_KEY (environment only, never in QML)
    │
    └─ Ollama provider (HTTP REST to localhost:11434)
            └─ Capability check: GET /api/tags
```

### Ollama capability detection

```qml
// services/AI.qml
Process {
    id: ollamaCheck
    command: ["curl", "-sf", "--max-time", "2", "http://localhost:11434/api/tags"]
    running: true
    stdout: StdioCollector {
        onStreamFinished: {
            if (this.text.trim() !== "") {
                parent.parent.ollamaAvailable = true
                // Parse installed models from JSON
            }
        }
    }
}
```

Perform this check at shell startup and after `TEST_ALIVE` responses. Do not poll continuously.

### Gemini credential safety

```qml
// WRONG — never do this
property string apiKey: "AIzaSy..."

// CORRECT — read from environment
Process {
    command: ["sh", "-c", "echo $GEMINI_API_KEY"]
    // ...
}
```

Or use `Quickshell.Io.FileView` to read from `~/.config/ai/credentials` (with `chmod 600`).

### Keybind

- `SUPER + SHIFT + ALT + mouse:273` — AI summary for selected text (via `scripts/ai/primary-buffer-query.sh`)
- Left sidebar toggles AI panel: `SUPER + A`

### Network failure handling

All AI calls must implement:
- 10-second timeout
- Error state display in the panel
- Retry button
- No blocking of the Qt event loop (all calls via asynchronous `Process`)

---

## 14. Subtitle and Media Overlay

### Architecture overview

```
YouTube/Media Player
    ↓ (subtitle data — see adapters below)
Adapter Layer
    ↓
SubtitleService.qml (singleton)
    ↓
SubtitleOverlay.qml (top-of-screen PanelWindow, input-passthrough)
    ↓ (audio amplitude from CAVA)
Audio-reactive animation
```

### Subtitle adapter options (choose based on availability)

| Adapter | Mechanism | Limitations |
|---|---|---|
| Browser extension + native messaging | WebExtension API → local socket → Quickshell | Requires browser extension install |
| yt-dlp subtitle fetch | `yt-dlp --write-subs --skip-download <url>` → parse VTT | One-time fetch, not live sync |
| mpv with script | `mpv --script=subtitle-ipc.lua` → socket | Only works when mpv is the player |
| playerctl metadata | `playerctl metadata` MPRIS fields | Limited — not all players expose subtitles |

**The system must use an adapter pattern.** The `SubtitleService.qml` receives normalized subtitle events regardless of source:

```qml
signal subtitleChanged(string text, int duration)
signal subtitleCleared()
```

### CTRL + SHIFT + Y feature

When `CTRL + SHIFT + Y` is pressed (add this binding to `keybinds.lua` if not present):

```lua
hl.bind("CTRL + SHIFT + Y", hl.dsp.global("quickshell:subtitleMusicModeToggle"),
    { description = "Shell: Toggle subtitle/music visualization mode" })
```

This activates:
1. SubtitleOverlay in music visualization mode
2. CAVA audio-reactive animation connects to subtitle text elements
3. Text elements pulse, scale, and glow with audio amplitude
4. Animation is GPU-accelerated via QML `Behavior` and `NumberAnimation`

### Audio-reactive subtitle animation rules

```qml
// GOOD — GPU-accelerated property animation
Text {
    property real amplitude: SubtitleService.amplitude // 0.0 to 1.0 from CAVA

    scale: 1.0 + amplitude * 0.15
    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

    layer.enabled: amplitude > 0.3
    layer.effect: GlowEffect { radius: amplitude * 12 }
}

// BAD — JavaScript per-frame update
Timer {
    interval: 16; running: true; repeat: true
    onTriggered: {
        subtitle.scale = calculateScaleFromAudio() // Kills battery
    }
}
```

Update CAVA amplitude at maximum 30Hz. QML animations handle smooth interpolation at native framerate.

---

## 15. Screen Translation and OCR

### Workflow

```
SUPER + SHIFT + T → quickshell:screenTranslate
    → Quickshell invokes grim + slurp for region selection
    → grim captures region to /tmp/translate_<timestamp>.png
    → tesseract performs OCR
    → Translation API call (local or remote)
    → Result displayed in Quickshell overlay
    → Overlay dismisses on Escape or click-outside
```

### OCR binding (existing)

```lua
-- keybinds.lua line 74-81
hl.bind("SUPER + SHIFT + X", hl.dsp.global("quickshell:regionOcr"))
-- Fallback: grim + slurp + tesseract + wl-copy
```

### Translation provider detection

```bash
command -v argos-translate && TRANSLATE_ENGINE=argos  # Local
command -v trans           && TRANSLATE_ENGINE=trans   # translate-shell (remote)
# TRANSLATE_ENGINE is exported, Quickshell reads it
```

Do not hardcode a translation provider. Support graceful fallback to clipboard-only if no translation engine is available.

---

## 16. Google Lens Integration

### Binding

```lua
-- keybinds.lua line 71-72
hl.bind("SUPER + SHIFT + A", hl.dsp.global("quickshell:regionSearch"))
-- Fallback: hyprScripts .. "/snip_to_search.sh"
```

### Script contract

`scripts/snip_to_search.sh` must:
1. Launch `slurp` for region selection
2. Run `grim -g "$(slurp)" /tmp/lens_<timestamp>.png`
3. Upload only the selected region (never the full screen)
4. Open `https://lens.google.com/upload?...` or equivalent endpoint
5. Clean up the temporary image after upload

The user must explicitly select the region. Automatic full-screen capture is forbidden.

---

## 17. Security Architecture

> [!CAUTION]
> Security rules are non-negotiable. Violating them is worse than an incomplete feature.

### Absolute prohibitions

- Never hardcode API keys, passwords, tokens, or secrets in any file
- Never store plaintext credentials anywhere
- Never pipe user-controlled input directly to `bash -c`
- Never execute commands parsed from window titles (injection risk)
- Never bypass PAM or weaken hyprlock authentication
- Never disable the actual system lock screen
- Never download and execute scripts from the internet (no `curl | bash`)
- Never commit files containing secrets (even accidentally)

### Credential storage

| Type | Storage location | Access method |
|---|---|---|
| API keys | Environment variables | `$GEMINI_API_KEY` etc. |
| Long-term secrets | `~/.config/ai/credentials` (chmod 600) | `FileView` in QML |
| Session tokens | System keyring (`secret-tool`) | Via `Process` command array |

### Shell command security in QML

```qml
// LETHAL — songName could be "; rm -rf ~"
command: ["bash", "-c", "playerctl play-pause " + songName]

// SAFE — array, OS handles argument separation
command: ["playerctl", "play-pause", songName]
```

### Window title injection

```lua
-- VULNERABLE
hl.on("window.opened", function(win)
    hl.exec_cmd("notify-send " .. win.title) -- shell injection
end)

-- SAFE
hl.on("window.opened", function(win)
    hl.exec_cmd({"notify-send", win.title}) -- array form where available
end)
```

### Hyprlock / authentication

- Authentication failure reaction (§19) must be implemented as a **post-failure visual overlay**, not a replacement authentication mechanism
- PAM configuration must never be weakened
- `clear_crashed_lockscreen()` is only for emergency recovery from a crashed hyprlock, not to bypass authentication
- The lockout overlay must not prevent the user from successfully authenticating after the cooldown

---

## 18. Anti-Flashbang System

### Problem

Applications with bright white backgrounds (e.g., browser on a dark theme) cause sudden bright exposure when opened.

### Implementation approach

Using `hl.on("window.opened", ...)` in Hyprland Lua:

```lua
-- hyprland/rules.lua or a dedicated antiflasbang.lua
local bright_apps = {
    ["google-chrome"] = true,
    ["chromium"] = true,
    ["firefox"] = true,
    -- extend via custom/variables.lua
}

hl.on("window.opened", function(win)
    if bright_apps[win.class] then
        -- Apply temporary opacity reduction for 1 second via Hyprland rule
        -- This uses window-specific opacity, not a compositor overlay
        hl.add_window_rule("opacity 0.0 override", "address:" .. win.address)
        -- Schedule removal (Hyprland Lua timer or hl.exec_cmd after delay)
    end
end)
```

### Constraints

- Do NOT rely on pixel scraping to detect brightness
- Use compositor window metadata (`win.class`, `win.title`, `win.address`)
- Allow user to extend the `bright_apps` table in `custom/variables.lua`
- The effect must clear automatically; it must never permanently reduce opacity
- Do NOT apply to already-open windows on startup

---

## 19. Authentication Failure Reaction

> [!IMPORTANT]
> This is a **cosmetic visual reaction**, not a security mechanism. It must not interfere with authentication.

### Architecture

- Monitor hyprlock PAM failure events via journald or PAM hooks
- After **3 consecutive failures**, trigger a 5-minute visual lockout overlay via Quickshell
- The overlay displays a configurable humorous image (furry/femboy — user-configurable)
- Authentication remains fully functional through hyprlock; this overlay is cosmetic only
- After 5 minutes, the overlay auto-dismisses

### Implementation

```bash
# scripts/security/auth-failure-hook.sh
# Called by PAM fail hook or journald watcher
FAIL_COUNT=$(cat /tmp/auth_fail_count 2>/dev/null || echo 0)
FAIL_COUNT=$((FAIL_COUNT + 1))
echo "$FAIL_COUNT" > /tmp/auth_fail_count

if [ "$FAIL_COUNT" -ge 3 ]; then
    qs -c "$QS_CONFIG" ipc call "security:authFailureLockout" || true
    echo 0 > /tmp/auth_fail_count
fi
```

Quickshell reacts to `security:authFailureLockout` by showing the overlay for 300 seconds.

On successful authentication, emit `security:authSuccess` to dismiss the overlay immediately.

### Constraints

- The configurable image lives in `~/.config/hypr/assets/lockout/` (gitignore user-specific images)
- The overlay must be `layer: "overlay"` with `exclusionZone: -1`
- Input must pass through to hyprlock (input-passthrough mode)
- This feature must be disabled by default; opt-in via `custom/variables.lua`

---

## 20. Fish Shell Architecture

### Principle

Do NOT put everything into `config.fish`. Fish auto-sources `conf.d/*.fish` and autoloads `functions/*.fish`.

### Structure

```
~/.config/fish/
├── config.fish          # Minimal: set PATH, export critical env vars, source nothing else
├── conf.d/
│   ├── 00-env.fish      # Environment variables (XDG, Wayland, Qt, etc.)
│   ├── 01-aliases.fish  # Command aliases
│   ├── 02-prompt.fish   # Starship/Tide initialization
│   ├── 03-keybindings.fish  # Fish keybindings
│   ├── 04-completions.fish  # Completion loading
│   └── 99-local.fish    # Machine-local overrides (gitignored)
├── functions/
│   ├── wallpaper.fish   # wallpaper [path] — wrapper for switchwall.sh
│   ├── theme.fish       # theme [dark|light] — wrapper for toggle
│   ├── qs-restart.fish  # Quick Quickshell restart helper
│   └── dotfiles.fish    # dotfiles [doctor|validate|update|rollback]
└── completions/
    └── dotfiles.fish    # Completions for dotfiles command
```

### Environment variable exports (conf.d/00-env.fish)

```fish
set -gx WAYLAND_DISPLAY wayland-0
set -gx QT_QPA_PLATFORM "wayland;xcb"
set -gx QT_WAYLAND_DISABLE_WINDOWDECORATION 1
set -gx GDK_BACKEND "wayland,x11"
set -gx MOZ_ENABLE_WAYLAND 1
set -gx ELECTRON_OZONE_PLATFORM_HINT "auto"
set -gx XDG_CURRENT_DESKTOP Hyprland
set -gx XDG_SESSION_TYPE wayland
set -gx QS_CONFIG "default"  # Quickshell config name
```

### Idempotency

All Fish configuration must be idempotent. Running `source config.fish` twice must not duplicate `PATH` entries, alias registrations, or environment exports.

---

## 21. Installation

### install.sh contract

The installer must be idempotent. Running it N times must produce the same result as running it once.

```bash
./install.sh             # Full install
./install.sh --dry-run   # Show what would change, touch nothing
./install.sh --minimal   # Core only (Hyprland + Fish), no AI/subtitle features
./install.sh --full      # All optional features
./install.sh --uninstall # Remove symlinks, restore backups
```

### Installer phases

```
Phase 1: System detection
    detect_os()       → /etc/os-release
    detect_pkgman()   → pacman / apt / dnf / yay / paru
    detect_gpu()      → lspci | grep VGA
    detect_hyprland() → hyprctl version
    detect_qs()       → qs --version
    detect_audio()    → wpctl status

Phase 2: Dependency verification
    check_required()  → hyprland, quickshell, fish, matugen, cava, pipewire
    check_recommended() → grim, slurp, wl-clipboard, hyprpicker, playerctl
    check_optional()  → tesseract, swww, mpvpaper, yt-dlp, argos-translate

Phase 3: Backup
    backup_existing() → copies ~/.config/<component> to ~/.config/<component>.bak.<timestamp>
    NEVER rm -rf

Phase 4: Link
    link_config()     → create symlinks from repo to ~/.config/
    link_keymap()     → keybinds.lua → ~/.config/hypr/hyprland/keybinds.lua

Phase 5: Initialize
    init_theme()      → run matugen with default wallpaper
    init_wallpaper()  → detect backend, set default wallpaper
    init_fish()       → fish_config initialize if needed

Phase 6: Validate
    validate_hyprland() → hyprctl reload (check exit code)
    validate_qs()       → qs -c $QS_CONFIG --check (if supported)
    print_summary()     → what was installed, what was skipped
```

### Backup strategy

```bash
backup_dir="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

for component in hypr quickshell fish cava matugen; do
    if [ -d "$HOME/.config/$component" ]; then
        cp -r "$HOME/.config/$component" "$backup_dir/$component"
    fi
done

echo "Backup created: $backup_dir"
```

---

## 22. Dependency Management

### Classification

**Required** (desktop will not start without these):
- `hyprland` (0.56.2)
- `quickshell`
- `fish`
- `pipewire` + `wireplumber`
- `xdg-desktop-portal-hyprland`
- `polkit-kde-agent`

**Recommended** (major features will be absent):
- `matugen` (theming)
- `cava` (audio visualization)
- `swww` or `hyprpaper` (wallpaper)
- `grim` + `slurp` (screenshots, OCR, Google Lens)
- `wl-clipboard` (`wl-copy`, `wl-paste`)
- `hyprpicker` (color picker)
- `playerctl` (media control)
- `cliphist` (clipboard history)
- `brightnessctl` (brightness control)
- `hypridle` + `hyprlock` (idle/lock)

**Optional** (specific features):
- `tesseract` (OCR — SUPER+SHIFT+X)
- `translate-shell` or `argos-translate` (screen translation)
- `mpvpaper` or `glpaper` (animated wallpapers)
- `ydotool` (some interaction scripts)
- `ollama` (local AI)
- `yt-dlp` (subtitle extraction)
- `hyprshot` (screenshot fallback)
- `fuzzel` (launcher fallback when Quickshell is not alive)
- `wlogout` (session menu fallback)

### Capability checking pattern

```bash
require_cmd() {
    if ! command -v "$1" &>/dev/null; then
        echo "ERROR: Required command '$1' not found. Install it first." >&2
        exit 1
    fi
}

optional_cmd() {
    if ! command -v "$1" &>/dev/null; then
        echo "WARNING: Optional command '$1' not found. Feature '${2}' will be unavailable."
        return 1
    fi
    return 0
}
```

---

## 23. Environment Detection

### GPU detection

```bash
detect_gpu() {
    if lspci 2>/dev/null | grep -qi "nvidia"; then
        echo "nvidia"
    elif lspci 2>/dev/null | grep -qi "amd\|radeon"; then
        echo "amd"
    elif lspci 2>/dev/null | grep -qi "intel"; then
        echo "intel"
    else
        echo "unknown"
    fi
}
```

### Hyprland version check

```bash
detect_hyprland_version() {
    hyprctl version 2>/dev/null | grep -oP 'v\K[\d.]+' | head -1
}
```

### Wayland detection

```bash
[ "$WAYLAND_DISPLAY" != "" ] || [ "$XDG_SESSION_TYPE" = "wayland" ]
```

### Distribution detection

```bash
. /etc/os-release
echo "$ID"  # arch, ubuntu, fedora, etc.
```

---

## 24. Multi-Monitor Support

### Hyprland side

```lua
-- monitors.lua — never use static monitor names in main config
hl.on("monitor.added", function(mon)
    -- Apply per-monitor rules
    if mon.name:match("^eDP") then
        -- Laptop internal display
        hl.set_monitor_scale(mon.name, 1.5)
    end
end)

hl.on("monitor.disconnected", function(mon)
    -- Move workspaces to primary monitor
end)
```

### Quickshell side

Always use `Variants { model: Quickshell.screens }`. Never hardcode a monitor name.

Processes and services live in global `Scope`, never inside per-screen delegates.

### Bar positioning

```qml
PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: 36  // Exclusive zone
}
```

### DPI and fractional scaling

- Qt scales automatically when `QT_SCALE_FACTOR` or Wayland scaling is set
- Use `Math.round(Theme.baseSize * screen.devicePixelRatio)` for pixel-precise sizes
- Do NOT hardcode pixel values

---

## 25. Performance Engineering

### Performance budgets

| Metric | Target |
|---|---|
| Quickshell idle CPU | < 0.1% |
| Quickshell RAM | < 150 MB |
| Shell startup to first paint | < 500 ms |
| Wallpaper switch latency | < 3 s (including Matugen) |
| Theme token propagation | < 500 ms after Matugen finishes |
| Overview open latency | < 200 ms |
| Animation FPS | 60 fps minimum at all times |

### Profiling tools

```bash
# CPU usage
pidstat -u 1 -p $(pgrep qs) 10

# RAM
cat /proc/$(pgrep qs)/status | grep VmRSS

# GPU (AMD)
radeontop -d -

# GPU (NVIDIA)
nvidia-smi dmon -i 0

# GPU (Intel)
intel_gpu_top

# Hyprland rendering
hyprctl getoption decoration:blur:enabled
```

### Event-driven rule

If you are adding a `Timer` with `running: true` to periodically query a system state, you MUST first prove that no event-based mechanism exists (DBus signal, Wayland event, Quickshell service singleton). Polling is allowed only as a **documented last resort**, at a minimum interval of 5 seconds, and only when the system is active.

---

## 26. Low-RAM Mode

### Profile switching

Exposed as a variable in `custom/variables.lua`:

```lua
-- custom/variables.lua
performance_profile = "balanced" -- "performance" | "balanced" | "beautiful"
```

### Profile effects

| Feature | performance | balanced | beautiful |
|---|---|---|---|
| Blur | disabled | reduced (size 3, passes 1) | full (size 8, passes 3) |
| Shadows | disabled | subtle | full |
| Animation duration | 80ms | 200ms | 350ms |
| Window previews in overview | static thumbnails | cached | live |
| Inactive widget polling | paused | 5s interval | 2s interval |
| CAVA bars | 32 | 64 | 128 |
| Wallpaper backend | hyprpaper (static) | swww | mpvpaper |

Quickshell reads `$PERFORMANCE_PROFILE` at startup and configures itself accordingly.

---

## 27. Hardware Adaptation

### NVIDIA

Per `.agentskill/hyprland/SKILL.md` §26:
- Kernel parameter: `nvidia_drm.modeset=1`
- Environment: `__GLX_VENDOR_LIBRARY_NAME=nvidia`
- Do NOT use `WLR_NO_HARDWARE_CURSORS` (Aquamarine, not wlroots)
- Explicit sync is handled natively by Aquamarine

### AMD

- Open-source `mesa` + `amdgpu` (no proprietary driver needed for most use cases)
- VRR: constrain to fullscreen-only to prevent desktop flickering

### Intel

- `i915.enable_psr=0` kernel parameter if panel self-refresh causes artifacts

### Automatic adaptation example (in Hyprland Lua)

```lua
-- hyprland/execs.lua or hyprland.lua
local gpu = hl.exec_cmd_sync("detect_gpu.sh") -- returns "nvidia"|"amd"|"intel"

if gpu == "nvidia" then
    hl.config({ decoration = { blur = { enabled = true, size = 5, passes = 2 } } })
elseif gpu == "intel" then
    hl.config({ decoration = { blur = { enabled = false } } })
else
    hl.config({ decoration = { blur = { enabled = true, size = 8, passes = 3 } } })
end
```

---

## 28. Update Compatibility

### Hyprland update procedure

```bash
# Before updating
dotfiles validate        # check current config is valid
git -C ~/.config/hypr stash  # save current state

# After updating
hyprctl version          # confirm new version
hyprctl reload           # test config loads
# If broken:
git -C ~/.config/hypr stash pop   # restore previous
hyprctl reload
```

### Version detection in config

```lua
-- hyprland.lua
local ver = hl.version()  -- if API exists in 0.56.2+
-- Or parse: hl.exec_cmd_sync("hyprctl version")
```

### Deprecated options to watch

- `.conf` files: fully deprecated in 0.56.2 — migrate to Lua
- `wlroots`-specific env vars: not applicable with Aquamarine
- Legacy `bind = ...` syntax: replaced by `hl.bind()`

### Migration checklist (after upstream update)

1. `hyprctl reload` — watch for Lua parse errors
2. `hyprctl repl` — interactively test changed APIs
3. Check `$XDG_RUNTIME_DIR/hypr/` logs for deprecation warnings
4. Update `.agentskill/hyprland/SKILL.md` with new API knowledge

---

## 29. Configuration Validation and Rollback

### Validation before reload

```bash
# dotfiles validate script
#!/usr/bin/env bash
errors=0

# Lua syntax check
for f in ~/.config/hypr/**/*.lua; do
    luac -p "$f" 2>&1 || errors=$((errors + 1))
done

# Quickshell check
qs -c "$QS_CONFIG" --check 2>&1 || errors=$((errors + 1))

# Dependency check
for cmd in hyprland qs fish matugen cava grim slurp; do
    command -v "$cmd" &>/dev/null || echo "WARNING: $cmd not found"
done

echo "Validation complete. Errors: $errors"
exit $errors
```

### Rollback architecture

```
~/.config/hypr/
├── hyprland.lua        (current)
└── .rollback/
    └── hyprland.lua.2026-09-28T12:00:00  (previous known-good)
```

```bash
# Before any Hyprland config change:
cp ~/.config/hypr/hyprland.lua \
   ~/.config/hypr/.rollback/hyprland.lua.$(date -Iseconds)

# If reload fails:
cp ~/.config/hypr/.rollback/hyprland.lua.<latest> \
   ~/.config/hypr/hyprland.lua
hyprctl reload
```

### Emergency recovery

```bash
# TTY recovery (Ctrl+Alt+F2)
hyprctl repl              # Interactive Lua REPL — fix syntax on the fly
hyprctl clear_crashed_lockscreen  # If hyprlock is stuck (0.56.2 API)
```

---

## 30. Logging and Diagnostics

### Log locations

| Subsystem | Log location |
|---|---|
| Hyprland | `$XDG_RUNTIME_DIR/hypr/hyprland.log` |
| Quickshell | stderr when run from terminal; `journalctl --user -u quickshell` |
| Installer | `~/.local/log/ralsei-install.log` |
| AI service | `~/.local/log/ralsei-ai.log` |
| Wallpaper/theme | `~/.local/log/ralsei-theme.log` |
| CAVA | stderr |

### Quickshell console prefix convention

```qml
console.log("[TopBar] Rendering workspace", workspaceId)
console.warn("[SubtitleService] Provider unavailable")
console.error("[AIService] Network timeout after 10s")
```

### dotfiles doctor command

```bash
dotfiles doctor  # Runs all diagnostic checks and reports status
```

Output format:
```
[OK]      hyprland 0.56.2
[OK]      quickshell
[OK]      pipewire
[WARN]    matugen not found — theming unavailable
[WARN]    tesseract not found — OCR unavailable
[ERROR]   Quickshell config parse error (see below)
```

---

## 31. Testing Strategy

### Static validation

```bash
# Lua syntax
luac -p keybinds.lua
luac -p ~/.config/hypr/**/*.lua

# QML parse (requires Qt tools)
qmlformat --dry-run <file>.qml

# Shell scripts
shellcheck scripts/**/*.sh

# Fish
fish -n ~/.config/fish/conf.d/*.fish
```

### Runtime validation matrix

| Feature | Test action | Expected result |
|---|---|---|
| Overview | `SUPER + Tab` | Overview opens, workspaces visible |
| Wallpaper selector | `CTRL + SUPER + T` | Thumbnail grid appears |
| Theme switch | Select wallpaper | Colors update across all subsystems |
| Clipboard | `SUPER + V` | Clipboard history shows |
| Screenshot | `SUPER + SHIFT + S` | Region selection cursor appears |
| OCR | `SUPER + SHIFT + X` | Text copied to clipboard |
| Google Lens | `SUPER + SHIFT + A` | Browser opens with image |
| AI panel | `SUPER + A` | Left sidebar opens with AI input |
| Session menu | `CTRL + ALT + Delete` | Session options shown |
| Monitor hotplug | Plug/unplug monitor | Bar appears/disappears, no zombie |
| Quickshell restart | `CTRL + SUPER + R` | Shell restarts, all bars re-appear |
| Lock | `SUPER + L` | hyprlock activates |

### Failure simulation

| Failure | Expected behavior |
|---|---|
| Quickshell not running | Keybinds fall back to native commands |
| Matugen not installed | Wallpaper changes, but colors stay at default |
| Ollama unavailable | AI panel shows "Ollama not available" state |
| Gemini key missing | AI panel shows "API key not configured" state |
| Monitor disconnected | Bars gracefully removed via Variants lifecycle |
| Broken Lua syntax | `hyprctl reload` fails, TTY REPL available for recovery |
| CAVA crash | Audio visualization stops; no shell crash |
| Translation engine absent | OCR text copied but not translated |

---

## 32. Development Workflow

### Before editing

```
1. Read skill.md (this file)
2. Read relevant .agentskill/ skill
3. Read keybinds.lua if touching bindings
4. Create a git branch for the change
5. Run: dotfiles validate
```

### After editing

```
1. Run: dotfiles validate
2. For Hyprland: hyprctl reload
3. For Quickshell: CTRL+SUPER+R (or restart qs manually)
4. Run through the Runtime Validation Matrix relevant to your change
5. Commit with message: "<Component>: <what changed and why>"
```

### Branch naming

```
feature/<component>/<description>
fix/<component>/<description>
perf/<component>/<description>
```

---

## 33. Extension Guidelines

### Adding a new Quickshell panel

1. Create `panels/NewPanel.qml`
2. Define `PanelWindow` with correct anchors and exclusive zone
3. Create a new IPC signal name: `quickshell:newPanelToggle`
4. Register signal handler in `shell.qml`
5. Add to IPC signal registry in §8 of this document
6. Add keybinding to `keybinds.lua` (check for conflicts first)
7. Add fallback command for when Quickshell is not alive
8. Add to Runtime Validation Matrix in §31

### Adding a new service

1. Create `services/NewService.qml` as `pragma Singleton`
2. Expose only typed properties and functions — no raw process references
3. Mount in `shell.qml` inside the global `Scope`
4. Document dependencies and failure modes

### Adding a new keybinding

1. Check `keybinds.lua` for conflicts (§7 conflict detection rules)
2. Use `{ description = "Category: Action" }` metadata
3. Implement dual-dispatch (Quickshell IPC + fallback command)
4. Document in the keymap summary table (§7)
5. Update `quickshell:cheatsheetToggle` data source if it reads from the description metadata

### Adding a new theme token

1. Add to `services/Theme.qml` only
2. Document semantic purpose in the color token table (§10)
3. Never add a token without a clear semantic role

---

## 34. Anti-Patterns

The following patterns are **forbidden** in this codebase:

| Anti-pattern | Why forbidden | Correct approach |
|---|---|---|
| `.conf` Hyprland syntax | Deprecated in 0.56.2 | Use `hl.config({...})` Lua API |
| Hardcoded colors in QML | Theme cannot update | Use `Theme.<token>` |
| Hardcoded monitor names | Breaks multi-monitor | Use `Quickshell.screens` Variants |
| Hardcoded `$HOME/...` paths in QML | Not portable | Use QML `StandardPaths` or service |
| Hardcoded API keys | Security breach | Environment variables |
| `Timer` polling a process | CPU/battery waste | Event-based (DBus, socket, hl.on) |
| `bash -c "<dynamic string>"` | Shell injection | Process array form |
| `Process` inside monitor delegate | Per-monitor duplication | Global Scope singleton |
| `while true; sleep 0.1; end` in Lua | Blocks compositor thread | Use `hl.on()` events |
| Mixing `.conf` with `.lua` | Syntax collision | Lua only |
| Giant monolithic QML files | Unmaintainable | Split into components/widgets/panels |
| Global mutable QML variables | State confusion | Singleton services |
| `rm -rf ~/.config` in installer | Destroys user data | Backup-then-link |
| Duplicate keybindings | Silent shadowing | Check before adding |
| `curl \| bash` | Arbitrary code execution | Review scripts before running |
| Storing passwords anywhere | Security | System keyring only |
| Polling `hyprctl` more than 1/s | Performance | Hyprland IPC events |
| Sending entire screen to Google Lens | Privacy | Region selection only |

---

## 35. Visual Design Language

> [!NOTE]
> Read `.agentskill/ui/SKILL.md` and `.agentskill/ux/SKILL(3).md` for detailed guidance. This section defines desktop-specific additions.

### Design vocabulary

The visual language is:

```
Material Design 3
  + Soft glassmorphism (blur + transparency)
  + Smooth spring-motion animations
  + Consistent 8px spacing grid
  + Dynamic wallpaper-derived accent colors
  + Dark-first design with light mode support
```

### Spacing system

```qml
// All spacing is a multiple of Theme.spacing (default: 8)
padding: Theme.spacing      // 8px
padding: Theme.spacing * 2  // 16px
// Never: padding: 13
```

### Animation principles

- Use `Behavior on <property>` for implicit animations
- Easing: `Easing.OutCubic` for movement, `Easing.InOutQuad` for fade
- Duration: `Theme.animDuration` (220ms balanced, 80ms performance, 350ms beautiful)
- Never animate properties that update at display refresh rate (GPU usage, CPU%)

### Typography

- Primary font: Inter (or system sans-serif fallback)
- Code font: JetBrains Mono (or system monospace fallback)
- Minimum readable body size: 13px
- Maintain WCAG AA contrast (4.5:1 minimum for body text)

### Accessibility

- All interactive elements: minimum 44×44 px touch target
- Keyboard navigation: Tab / Arrow / Enter / Escape
- Reduced motion mode: `property bool reducedMotion` in Theme — set `animDuration: 0`
- High contrast mode: override surface tokens with higher contrast variants
- Do not use color as the only indicator (pair with icon or text label)

---

## 36. Definition of Done

A feature is complete only when **all** of the following are true:

- [ ] Architecture is documented (updated in this skill.md if cross-cutting)
- [ ] Dependencies are declared (§22 updated if new)
- [ ] Keybindings checked for conflicts (§7 consulted)
- [ ] Failure cases are handled (graceful degradation)
- [ ] Performance is within budget (§25)
- [ ] Configuration is reloadable without full restart
- [ ] Feature can be disabled via `custom/variables.lua`
- [ ] Console logs are useful but not noisy
- [ ] Security rules followed (§17)
- [ ] Multi-monitor behavior verified (§24)
- [ ] Environment differences handled (§23)
- [ ] Installation reproducible (§21 updated if needed)

---

## 37. Engineering Checklist

- [ ] Read all `.agentskill/` skills relevant to this change
- [ ] Read `keybinds.lua` before adding any binding
- [ ] Verified no duplicate bindings via grep
- [ ] New features follow dual-dispatch pattern (IPC + fallback)
- [ ] New QML code follows dependency direction (System → Service → Widget → Panel)
- [ ] No `Process` inside monitor delegate
- [ ] No hardcoded colors — all from `Theme.*`
- [ ] No hardcoded monitor names
- [ ] No polling timers where events are available
- [ ] All process invocations use array form
- [ ] Lua code follows `snake_case` / `PascalCase` / `UPPERCASE` conventions
- [ ] `pcall` wrapping for Lua code that may fail at runtime
- [ ] Git branch created, commit messages follow convention

---

## 38. Performance Checklist

- [ ] Quickshell idle CPU < 0.1% verified with `pidstat`
- [ ] No new `Timer` nodes without documented justification
- [ ] No per-monitor processes duplicated (moved to global Scope)
- [ ] No QML binding to large JSON objects when only one field is needed
- [ ] No properties animated at display refresh rate
- [ ] CAVA amplitude data capped at 30Hz to Quickshell
- [ ] Matugen called only once per wallpaper change
- [ ] Overview uses cached/throttled window previews
- [ ] Shell startup time < 500ms verified
- [ ] Low-RAM mode profile documented for this feature

---

## 39. Security Checklist

- [ ] No API keys in any committed file
- [ ] No plaintext credentials anywhere
- [ ] All dynamic process arguments use array form (no `bash -c <variable>`)
- [ ] Window title is never used as a shell argument
- [ ] AI credentials loaded from environment or `chmod 600` file
- [ ] Google Lens only sends explicitly selected region
- [ ] Authentication failure reaction does not bypass PAM
- [ ] hyprlock configuration not weakened
- [ ] `install.sh` does not blindly overwrite user files
- [ ] No `curl | bash` in any script

---

## 40. Compatibility Checklist

- [ ] Hyprland version confirmed as 0.56.2 (`hyprctl version`)
- [ ] No `.conf` syntax anywhere in Hyprland config
- [ ] No `wlroots`-specific environment variables
- [ ] No assumptions about which wallpaper backend is installed
- [ ] No assumptions about which translation engine is installed
- [ ] No assumptions about GPU vendor
- [ ] Fish functions are idempotent
- [ ] Installer is idempotent (run 3× gives same result)
- [ ] XWayland apps handled gracefully (scaling, `suppress_event` rule)
- [ ] XDG portal is `xdg-desktop-portal-hyprland` only (no conflicting portals)

---

## 41. UI/UX Checklist

- [ ] New UI component follows 8px spacing grid
- [ ] Colors from `Theme.*` only — no literals
- [ ] Minimum touch target 44×44 px
- [ ] Keyboard navigation: Tab, Arrow, Enter, Escape work
- [ ] WCAG AA contrast verified (4.5:1 minimum)
- [ ] Animations use `Behavior on property` (not JavaScript timers)
- [ ] Animation duration uses `Theme.animDuration`
- [ ] Reduced motion mode: `Theme.reducedMotion` respected
- [ ] Loading indicator shown for async operations > 200ms
- [ ] Error state is visually distinct and provides recovery action
- [ ] Dismissable overlays respond to Escape key
- [ ] Panel does not obscure other panels unnecessarily
- [ ] Tested on primary monitor and secondary monitor

---

## 42. Pre-Commit Checklist

- [ ] `dotfiles validate` passes with zero errors
- [ ] No secrets or credentials in staged files (`git diff --staged | grep -i "api_key\|password\|secret"`)
- [ ] `keybinds.lua` conflict check done if any binding was modified
- [ ] New dependencies documented in §22
- [ ] Commit message: `<Component>: <what and why>`
- [ ] If this is a new feature: §36 Definition of Done reviewed

---

## 43. Pre-Reload Checklist

- [ ] Lua syntax check: `luac -p <file>.lua`
- [ ] Git commit (or stash) of current state before reload
- [ ] TTY available (Ctrl+Alt+F2) in case reload breaks display
- [ ] `dotfiles validate` run and passing
- [ ] For Hyprland reload: `hyprctl reload`
- [ ] For Quickshell restart: `CTRL+SUPER+R` or `killall qs; qs -c $QS_CONFIG &`
- [ ] Monitor that Quickshell responds to `TEST_ALIVE` after restart
- [ ] Verify overview, launcher, and bar render correctly on all monitors

---

## 44. Pre-Release Checklist

- [ ] All items in Engineering Checklist ✓
- [ ] All items in Performance Checklist ✓
- [ ] All items in Security Checklist ✓
- [ ] All items in Compatibility Checklist ✓
- [ ] All items in UI/UX Checklist ✓
- [ ] Runtime Validation Matrix (§31) fully passing
- [ ] Failure simulation tests (§31) pass gracefully
- [ ] `install.sh --dry-run` produces correct output
- [ ] `install.sh` runs idempotently (run 3× same result)
- [ ] `dotfiles doctor` reports no errors
- [ ] README / documentation updated if user-facing behavior changed
- [ ] `.agentskill/` skills updated if architectural decisions changed
- [ ] `skill.md` (this file) updated if cross-cutting rules changed
- [ ] Git tag created: `v<YYYY-MM-DD>-<brief-description>`

---

*End of Ralsei Dotfile Root Orchestrator Skill*

*Generated from repository inspection of `.agentskill/hyprland/SKILL.md`, `.agentskill/lua/SKILL.md`, `.agentskill/quickshell/SKILL.md`, `.agentskill/ui/SKILL.md`, `.agentskill/ux/SKILL(3).md`, and the authoritative `keybinds.lua`.*
