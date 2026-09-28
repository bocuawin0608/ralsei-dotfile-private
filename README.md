# 🌸 Ralsei Hyprland Dotfiles

A production-grade, modular Linux desktop environment built on **Hyprland 0.56.2 (Native Lua)**, **Quickshell (QtQuick/QML)**, **Matugen (Material Design 3)**, **CAVA**, and **Fish Shell**.

---

## 🌟 Overview

This repository is an engineered desktop environment designed to feel like a cohesive, fluid operating system rather than a fragmented collection of scripts.

```
                  ┌─────────────────────────────────────┐
                  │          Hyprland 0.56.2            │
                  │ (Compositor, Window Rules, Native Lua)│
                  └──────────────────┬──────────────────┘
                                     │
                  ┌──────────────────┴──────────────────┐
                  │             Quickshell              │
                  │   (Top/Bottom Bars, Overview, AI,   │
                  │  Subtitles, Control Center, Overlays)│
                  └──────────────────┬──────────────────┘
                                     │
                  ┌──────────────────┴──────────────────┐
                  │            Theme Engine             │
                  │    (Wallpaper → Matugen MD3 →       │
                  │   Quickshell / CAVA / Kitty / GTK)  │
                  └─────────────────────────────────────┘
```

---

## ✨ Features

- **Native Lua Architecture**: Runs natively on Hyprland 0.56.2's Lua execution engine via the custom `hl.*` API library.
- **Quickshell-First Desktop**: Modern QML shell surfaces for panels, overview, launcher, control center, AI sidebar, and notifications.
- **Material Design 3 Dynamic Theming**: Instant color synchronization across Quickshell, CAVA, Kitty, and GTK using Matugen 4 color extraction.
- **Desktop Overview & Search**: Conceptually inspired by GNOME & macOS Mission Control — live window tiles, workspace navigation, application launcher, and built-in calculator (`2 + 2`).
- **Audio-Reactive Subtitle Overlay**: Synchronized MPRIS subtitles with PipeWire/CAVA audio spectrum reactivity (`CTRL + SHIFT + Y`).
- **AI Integration**: Dual AI provider panel (Local Ollama LLMs + Google Gemini API) with selected text summarization (`SUPER + SHIFT + ALT + RightClick`).
- **OCR, Translation & Google Lens**: Screen region OCR (`SUPER + SHIFT + X`), live screen translation overlay (`SUPER + SHIFT + T`), and Google Lens visual search (`SUPER + SHIFT + A`).
- **Anti-Flashbang System**: Automatic temporary dimming/opacity reduction for newly opened bright windows.
- **Multi-Tier Performance Profiles**: Seamlessly switch between `performance`, `balanced`, and `beautiful` rendering profiles to match your GPU/hardware capabilities.
- **Idempotent Installer & Diagnostics**: Production `./install.sh` installer with `--dry-run` and built-in `dotfiles doctor` diagnostic suite.

---

## 📂 Directory Structure

```text
ralsei-dotfile-private/
├── keybinds.lua                     # Authoritative root keymap (symlinked to hypr)
├── install.sh                       # Production idempotent installer
├── skill.md                         # Repository constitution & AI orchestrator skill
├── README.md                        # Project documentation & usage guide
│
├── .config/
│   ├── hypr/
│   │   ├── hyprland.lua             # Main Hyprland Lua entry point
│   │   ├── custom/                  # Machine-local overrides (gitignored)
│   │   └── hyprland/
│   │       ├── lib.lua              # Core hl.* API library
│   │       ├── variables.lua        # Default app & shell variables
│   │       ├── env.lua              # Wayland, Qt, GTK, Electron environment
│   │       ├── execs.lua            # Autostart daemon manager
│   │       ├── rules.lua            # Windowrulev2 & layer rules
│   │       ├── animations.lua       # Bezier curves & motion settings
│   │       ├── decorations.lua      # Blur, rounding, shadow rules
│   │       ├── input.lua            # Touchpad & input device setup
│   │       ├── workspaces.lua       # Dwindle layout & gap rules
│   │       ├── monitors.lua         # Monitor hotplug & scaling rules
│   │       ├── performance.lua      # Profile profile switcher
│   │       ├── antiflasbang.lua     # Anti-flashbang protection logic
│   │       └── scripts/             # Subsystem bash scripts
│   │
│   ├── quickshell/default/
│   │   ├── shell.qml                # Quickshell entry point & IPC server
│   │   ├── services/                # Headless singletons (Theme, Hyprland, Audio, AI, etc.)
│   │   ├── panels/                  # Layer-shell assemblies (TopBar, BottomBar, Overview, etc.)
│   │   ├── components/              # Reusable UI widgets
│   │   └── scripts/                 # Wallpaper & video recording scripts
│   │
│   ├── fish/
│   │   ├── config.fish              # Minimal bootstrap
│   │   ├── conf.d/                  # Environment, aliases, prompt modules
│   │   ├── functions/               # Autoloaded functions (wallpaper, theme, dotfiles)
│   │   └── completions/             # Command tab-completions
│   │
│   ├── matugen/
│   │   ├── config.toml              # Matugen 4 configuration
│   │   └── templates/colors.json    # MD3 token JSON template
│   │
│   └── cava/
│       ├── config                   # Base 60fps CAVA audio visualizer config
│       └── config-pipe              # 30fps raw binary stream for Quickshell
```

---

## 🚀 Quick Start

### 1. Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/bocuawin0608/ralsei-dotfile-private.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

#### Installer Options

```bash
./install.sh --dry-run    # Preview all actions without modifying files
./install.sh --minimal    # Install core Hyprland, Quickshell, and Fish only
./install.sh --full       # Install all recommended & optional dependencies (default)
./install.sh --uninstall  # Safely revert symlinks to previous backups
```

> [!NOTE]
> The installer **never destroys user data**. Existing configurations are automatically backed up to `~/.config_backup_<TIMESTAMP>/` before symlinks are created.

### 2. First Boot & Theme Setup

1. Add your wallpapers to `~/Pictures/Wallpapers/`
2. Apply a wallpaper and generate your initial Material Design 3 color palette:
   ```fish
   wallpaper --random
   ```
3. Run the diagnostic suite to verify system health:
   ```fish
   dotfiles doctor
   ```

---

## ⌨️ Keybindings Reference

The keymap is defined in [`keybinds.lua`](file:///home/loliconhihi/Documents/Project/ralsei-dotfile-private/keybinds.lua).

### Shell & Quickshell Controls

| Shortcut | Action | Description |
|---|---|---|
| `SUPER` (release) | Toggle Search / Overview | Open application launcher |
| `SUPER + Tab` | Workspace Overview | Toggle desktop workspace overview |
| `SUPER + V` | Clipboard History | Open clipboard viewer |
| `SUPER + Period` | Emoji Picker | Open emoji selector |
| `SUPER + A` / `B` / `O` | Left Sidebar | Open AI panel & media controls |
| `SUPER + N` | Right Sidebar | Open notification center & quick settings |
| `SUPER + Slash` | Cheatsheet | Display keybinding cheatsheet |
| `SUPER + M` | Media Controls | Toggle media overlay |
| `SUPER + G` | Widget Overlay | Toggle desktop widget canvas |
| `CTRL + ALT + Delete` | Session Menu | Lock, Sleep, Restart, Shutdown |
| `SUPER + J` | Toggle Bar | Show / hide Quickshell top & bottom bars |
| `CTRL + SUPER + T` | Wallpaper Selector | Open graphical wallpaper grid |
| `CTRL + SUPER + ALT + T` | Random Wallpaper | Apply a random wallpaper from library |
| `CTRL + SUPER + SHIFT + D` | Light/Dark Mode | Toggle desktop light/dark theme |
| `CTRL + SUPER + R` | Restart Widgets | Restart Quickshell process |
| `CTRL + SHIFT + Y` | Subtitle/Music Mode | Toggle audio-reactive subtitle visualizer |

### Applications

| Shortcut | Application |
|---|---|
| `SUPER + Return` / `SUPER + T` | Terminal (`kitty`) |
| `SUPER + E` | File Manager (`nautilus`) |
| `SUPER + W` | Web Browser (`firefox`) |
| `SUPER + C` | Code Editor (`code`) |
| `SUPER + X` | Text Editor (`gedit`) |
| `CTRL + SUPER + V` | Volume Mixer (`pavucontrol`) |
| `SUPER + I` | Settings (`gnome-control-center`) |
| `CTRL + SHIFT + Escape` | Task Manager (`gnome-system-monitor`) |

### Desktop Utilities

| Shortcut | Utility |
|---|---|
| `SUPER + SHIFT + S` | Screen Region Snip → Clipboard |
| `SUPER + SHIFT + X` | OCR Region → Clipboard |
| `SUPER + SHIFT + T` | Screen Region Translation |
| `SUPER + SHIFT + A` | Google Lens Visual Search |
| `SUPER + SHIFT + C` | Color Picker (`hyprpicker`) |
| `Print` | Fullscreen Screenshot → Clipboard |
| `CTRL + Print` | Fullscreen Screenshot → File & Clipboard |
| `SUPER + SHIFT + R` | Record Screen Region (No sound) |
| `SUPER + SHIFT + ALT + R` | Record Screen Region (With sound) |
| `CTRL + ALT + R` | Record Fullscreen |
| `SUPER + SHIFT + ALT + RightClick` | AI Summarize Selected Text |

### Window & Workspace Management

| Shortcut | Action |
|---|---|
| `SUPER + Q` | Close Active Window |
| `SUPER + SHIFT + ALT + Q` | Force Kill Window (`hyprctl kill`) |
| `SUPER + Arrow Keys` | Focus Window in Direction |
| `SUPER + SHIFT + Arrow Keys` | Move Window in Direction |
| `SUPER + ALT + Space` | Toggle Floating / Tiling |
| `SUPER + D` | Toggle Maximized |
| `SUPER + F` | Toggle Fullscreen |
| `SUPER + P` | Pin Window (Visible on all workspaces) |
| `SUPER + 1..0` | Focus Workspace 1–10 |
| `SUPER + ALT + 1..0` | Move Window to Workspace 1–10 |
| `SUPER + S` | Toggle Scratchpad |
| `SUPER + Equal / Minus` | Desktop Zoom In / Out |

---

## 🛠️ Diagnostics & CLI Tools

The dotfiles include a command-line tool accessible from Fish:

```fish
dotfiles doctor    # Run diagnostic health checks on all dependencies
dotfiles validate  # Check syntax of all Lua, TOML, Bash, and Fish files
dotfiles reload    # Reload Hyprland and restart Quickshell
dotfiles restart   # Restart Quickshell shell widgets
wallpaper [path]   # Switch wallpaper and update theme
theme [dark|light] # Toggle dark/light mode
```

---

## 🎨 Performance Profiles

You can adjust visual effects based on your hardware performance:

Edit `~/.config/hypr/custom/variables.lua`:

```lua
performance_profile = "balanced" -- Options: "performance" | "balanced" | "beautiful"
```

- **`performance`**: Disables blur & shadows, 80ms fast animations. Recommended for low-end GPUs / laptops.
- **`balanced`**: Moderate blur (passes=1), subtle shadows, 220ms smooth animations. Default balance.
- **`beautiful`**: High-quality blur (passes=3), deep shadows, 350ms spring animations.

---

## 🛡️ Security & Privacy

- **No Plaintext Secrets**: API keys are loaded strictly from environment variables (`$GEMINI_API_KEY`).
- **Safe Shell Invocations**: Quickshell and scripts use array-based subprocess execution to eliminate shell injection vulnerabilities.
- **Region-Limited Captures**: Tools like Google Lens and OCR only send user-selected regions, never the entire screen.
- **PAM Integration**: The optional authentication failure lockout reaction operates purely as a visual overlay and never interferes with PAM or system authentication.

---

## 📄 License

This repository is licensed under the [MIT License](LICENSE).
