# Hyprland 0.56.2 AI Engineering Skill

## 1. Mission and Scope

This document serves as the absolute architectural truth for AI agents operating a Hyprland 0.56.2 desktop environment. It evaluates the system as a continuous "World Machine"—a strict hierarchy of dependencies where flaws in the lower graphics stack cascade into compositor failures.

**Scope:**

- Native Lua configuration architecture (introduced in 0.55/0.56).
- Hardware, rendering (Aquamarine), and Wayland ecosystem integrations.
- Extreme-confidence debugging, telemetry, and system recovery.

**AI Verification Mandates:**

- Do not comfort the user. If they configure a broken system, expose the flawed logic directly.
- Never assume `.conf` syntax. Hyprland 0.56.2 operates natively on Lua.
- Never assume the presence of `wlroots`. Hyprland relies entirely on `Aquamarine`.

## 2. Hyprland Architecture

Hyprland operates as a dynamic Wayland display server, window manager, and compositor.

- **Wayland Client/Server:** Clients allocate EGL/Vulkan buffers. Hyprland composites them.
- **Rendering Pipeline:** `Aquamarine` (bridging Wayland, DRM, KMS). Renders via OpenGL (GLES2/3).
- **Input Pipeline:** `libinput` handles physical events. Wayland protocols route them to surfaces.
- **Workspace/Window Model:** Workspaces are logical nodes bound to physical monitors. Windows operate within Dwindle or Master layout trees.
- **IPC/State:** Native Lua execution engine handles state modifications, layout recalculations, and event dispatching in real-time.

## 3. Version-Specific Knowledge (Hyprland 0.56.2)

- **Configuration:** Complete "Lua-ification". The `.conf` parser is deprecated.
- **Lua API Additions (0.56.2):**
  - `change_id` (workspace API).
  - `get_loaded_plugins()`.
  - `clear_crashed_lockscreen()` (critical for recovery).
  - `is_key_down()` (direct key state querying).
  - Custom live gestures.
  - Monitor objects now expose `physical_width`, `height`, `CM`, and `reserved_area`.
  - `exec_scheduled_prop_refresh_immediately()`.
- **Other Additions:**
  - Interactive XDG drags (CSD titlebars).
  - `glow` supports gradients.
  - Groupbar `disable_when_only` option.
  - Windowrule `stableid:` field.
  - Windowrules effects: `no_auto_hdr`, `suppress_event` (for X11 configure events), `silent` monitor option.
  - `hyprctl` now features a native Lua REPL mode.

## 4. Installation

Target: Arch Linux.
**Dependencies:**

- Core: `pacman -S hyprland xdg-desktop-portal-hyprland`
- Rendering: `mesa` (AMD/Intel) or `nvidia nvidia-utils egl-wayland` (NVIDIA).
- Authentication: `polkit-kde-agent`

**Verification:**
Execute `hyprctl version`. Confirm version `0.56.2` and ensure `Aquamarine` is present in the linked libraries.

## 5. Session Startup

Lifecycle: `systemd-boot` → `greetd` / `TTY` → `PAM` → `systemd user session` → `Hyprland` → `D-Bus` → Desktop Services.
Variables must be exported before the Lua engine fully initializes GUI clients. `dbus-update-activation-environment` must be called to sync the Wayland environment to user services.

## 6. Configuration System

Hyprland 0.56.2 utilizes standard Lua 5.1/5.2 JIT conventions.
**Directory Structure:**

```
~/.config/hypr/
├── hyprland.lua       (Main entry)
├── workspaces.lua     (nwg-displays support)
├── monitors.lua
├── hyprland/          (Core abstractions)
│   ├── lib.lua
│   ├── env.lua
│   ├── execs.lua
│   ├── rules.lua
│   └── keybinds.lua
└── custom/            (User overrides)
    ├── env.lua
    └── rules.lua

```

**Architecture Pattern:**

```
-- hyprland.lua
require("hyprland.lib")
require("hyprland.env")
if is_file_exists(HOME .. "/.config/hypr/custom/env.lua") then
    require("custom.env")
end

hl.config({
    decoration = {
        rounding = 10,
        blur = { enabled = true, size = 3, passes = 1 }
    }
})

hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5")
end)

```

## 7. Complete Configuration Reference

- **Decoration:** `hl.config({ decoration = { rounding = 10, drop_shadow = true } })`
- **Animations:** `hl.config({ animations = { enabled = true } })`
- **Input:** `hl.config({ input = { kb_layout = "us", follow_mouse = 1 } })`
- **Misc:** `hl.config({ misc = { disable_hyprland_logo = true } })`
- *VERIFY AGAINST HYPRLAND 0.56.2 for nested table structures if undocumented.*

## 8. Monitors

Monitor management relies on the Lua API, exposing exact physical properties.

```
local monitors = hl.get_monitors()
for _, mon in ipairs(monitors) do
    if mon.name == "DP-1" then
        hl.set_monitor_scale("DP-1", 1.5)
        print("Physical Width: " .. mon.physical_width)
    end
end

```

Failure Modes: Fractional scaling blurs XWayland applications. Monitor hotplugging must be handled via `hl.on("monitor.added", ...)` rather than static configuration.

## 9. GPU and Rendering Stack

**NVIDIA:**

- Requires `nvidia_drm.modeset=1` in kernel parameters.
- Explicit sync is natively handled by Aquamarine. Do not attempt legacy X11 sync fixes.
  **AMD/Intel:**
- Requires open-source `mesa` drivers. `amdgpu` handles VRR and power states natively.

## 10. Input System

Uses `libinput`.

```
hl.config({
    input = {
        touchpad = { natural_scroll = true, disable_while_typing = true }
    }
})

```

Lua API `is_key_down()` allows for precise macro scripting and dynamic layer switching without invoking external binaries.

## 11. Keybinds and Dispatchers

Keybinds are registered natively via Lua functions.

```
hl.bind("SUPER", "Q", function()
    hl.dispatch("killactive")
end)

hl.bind("SUPER", "RETURN", function()
    hl.exec_cmd("kitty")
end)

```

Dispatchers (`workspace`, `movetoworkspace`, `togglefloating`) are called via `hl.dispatch(command, args)`.

## 12. Window Rules

Window rules map window classes/titles to behaviors.

```
hl.add_window_rule("float", "class:^(pavucontrol)$")
hl.add_window_rule("stableid:terminal_1", "class:^(kitty)$")
hl.add_window_rule("suppress_event", "class:^(xwayland_app)$")
hl.add_window_rule("no_auto_hdr", "class:^(mpv)$")

```

The `suppress_event` effect prevents legacy X11 configure events from breaking Wayland compositor scaling.

## 13. Layer Rules

Control Wayland layer-shell applications (Waybar, Rofi).

```
hl.add_layer_rule("blur", "waybar")
hl.add_layer_rule("ignorezero", "waybar")

```

## 14. Workspaces

Workspaces are manipulated via raw `set_` functions and the `change_id` API in 0.56.2.

```
hl.on("workspace.changed", function(new_ws)
    -- Telemetry or dynamic background change
end)

```

Special workspaces act as scratchpads, toggled via `hl.dispatch("togglespecialworkspace")`.

## 15. Layouts

- **Dwindle:** Spiraling Fibonacci algorithm. Ideal for general-purpose multitasking.
- **Master:** Stack-based. Ideal for code reading.
- Lua scripts can seamlessly query layout state and reposition nodes using `hl.dispatch("layoutmsg", "swapwithmaster")`.

## 16. Decorations

Visual effects processed by Aquamarine.

- **Blur:** High GPU VRAM bandwidth cost.
- **Glow:** Now supports gradients in 0.56.2.
- Disable animations and blur entirely when profiling GPU bottlenecks.

## 17. Animations

Bezier curves are defined and attached to window lifecycle events.

```
hl.config({
    animations = {
        enabled = true,
        beziers = {
            { name = "overshot", x1 = 0.05, y1 = 0.9, x2 = 0.1, y2 = 1.05 }
        },
        animations = {
            { name = "windows", enabled = 1, speed = 7, curve = "overshot" }
        }
    }
})

```

## 18. XWayland

X11 compatibility layer.

- XWayland applications are unaware of fractional scaling and will render internally at 1x, resulting in blur when upscaled by the compositor.
- Legacy dragging is superseded by XDG interactive drags where applicable.

## 19. IPC and Automation

Native Lua event registering eliminates the need for `socat` polling.

```
hl.on("window.opened", function(win)
    if win.class == "Steam" then
        hl.exec_cmd("notify-send 'Gaming Mode Active'")
    end
end)

```

## 20. Systemd User Services

Hyprland must integrate with `systemd --user`.

- Launch Waybar, Dunst, and Polkit via `systemd` units bound to `hyprland-session.target`.
- Avoid placing persistent daemons in `hl.on("hyprland.start", ...)`. Let `systemd` handle crash recovery.

## 21. Desktop Ecosystem

- **Status:** Waybar, Quickshell.
- **Launchers:** Rofi-Wayland.
- **Idle/Lock:** `hypridle`, `hyprlock`. (Use `clear_crashed_lockscreen` via REPL in emergencies).
- **Wallpaper:** `swww` or `hyprpaper`.

## 22. Portals

`xdg-desktop-portal-hyprland` provides the D-Bus interface for file picking and screen casting.
If screen sharing fails, ensure `xdg-desktop-portal-gnome` or `wlr` are removed, as multiple portals will conflict.

## 23. Audio

PipeWire handles all audio routing.
Use `wpctl status` to diagnose node graphs. Hyprland configuration only interacts with audio via repeating volume keybinds (`hl.binde(...)`).

## 24. Screen Sharing

Requires: WebRTC enabled in browser → PipeWire video node → `xdg-desktop-portal-hyprland` → Aquamarine buffer capture.

## 25. Power Management

Configured via `hypridle`.
If `hyprlock` crashes and traps the user in a black screen, swap to TTY and execute `hyprctl clear_crashed_lockscreen` (0.56.2 feature) to recover the session securely.

## 26. NVIDIA-Specific Troubleshooting

- **Symptom:** Flickering. **Fix:** Verify explicit sync is active.
- **Symptom:** Black Screen. **Fix:** Ensure `nvidia_drm.modeset=1` is loaded (`cat /sys/module/nvidia_drm/parameters/modeset`). Ensure `__GLX_VENDOR_LIBRARY_NAME=nvidia` is exported.

## 27. AMD-Specific Troubleshooting

- **Symptom:** VRR flickering on desktop. **Fix:** Constrain VRR to fullscreen only. Check `dmesg | grep amdgpu` for ring timeouts.

## 28. Intel-Specific Troubleshooting

- **Symptom:** Visual artifacts on laptop displays. **Fix:** Disable Panel Self Refresh (`i915.enable_psr=0` in kernel parameters).

## 29. Application Compatibility

Force applications to native Wayland where possible:

- Electron: `--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations`
- Qt: `QT_QPA_PLATFORM=wayland;xcb`

## 30. Performance Engineering

Monitor frame scheduling via GPU metrics.
Do not blindly disable VSync. Utilize `hl.dispatch("exec_scheduled_prop_refresh_immediately")` to force state updates if debugging input lag in custom Lua loops.

## 31. Debugging Methodology

1. **Reproduce:** Identify exact sequence.
2. **Scope:** Wayland, Aquamarine, DRM, or Client?
3. **Collect Evidence:** `journalctl --user`, `hyprctl repl`.
4. **Test:** Apply the smallest safe Lua change.
5. **Verify:** Monitor system behavior.

## 32. Logging

- **Hyprland logs:** `$XDG_RUNTIME_DIR/hypr/`
- **Service logs:** `journalctl -u systemd-logind` or `journalctl --user -u waybar`.

## 33. Crash Analysis

Use `coredumpctl info` to analyze compositor segfaults.
A crash in `Aquamarine` usually indicates a kernel-level GPU driver panic or memory leak.

## 34. Safe Recovery

Hyprland 0.56.2 introduces a REPL mode.
If the config is broken, switch to TTY2, run `hyprctl repl`, and dynamically unload broken Lua modules or fix syntax on the fly without killing the XDG session.

## 35. Configuration Management

Keep configurations highly modular. Isolate `.config/hypr/monitors.lua` from `.config/hypr/rules.lua` so parsing failures in user rules do not break display output logic.

## 36. Dotfiles Architecture

Use Git. Symlink `~/.dotfiles/hypr/` to `~/.config/hypr/`. Keep `custom/` directories in `.gitignore` to allow for machine-specific local overrides.

## 37. Security

Do not blindly execute shell commands parsed from window titles.
Example: `hl.exec_cmd("notify-send " .. win.title)` is vulnerable to shell injection if a user visits a malicious website with a crafted title.

## 38. Backup and Rollback

Before applying complex Lua loops, stage the changes in Git. If `hyprland.lua` hangs, rebooting into a previous snapshot prevents absolute system lockout.

## 39. Automation

Use `hl.on` for event-driven architecture.

```
hl.on("monitor.disconnected", function(mon)
    -- Move all critical workspaces to primary monitor
end)

```

## 40. Advanced IPC Automation

Instead of external Python daemons, write native Lua modules inside `~/.config/hypr/`. The engine processes state synchronously with the compositor tick, eliminating IPC latency.

## 41. DO NOT DO THIS

- **Anti-pattern:** Writing `while true do sleep(1) end` in `hyprland.lua`. This blocks the main compositor thread.
- **Anti-pattern:** Mixing `.conf` files with `.lua` files. Commit to Lua.
- **Anti-pattern:** Assuming `wlroots` environment variables (like `WLR_NO_HARDWARE_CURSORS`) do anything.

## 42. TROUBLESHOOTING MATRIX

| Symptom            | Layer      | Diagnostic Command                                    | Likely Cause                   | Fix                                       |
| ------------------ | ---------- | ----------------------------------------------------- | ------------------------------ | ----------------------------------------- |
| Lockscreen frozen  | Compositor | `hyprctl clear_crashed_lockscreen`                    | `hyprlock` PAM failure         | Clear lockscreen via TTY, check PAM logs. |
| Lua parse error    | Config     | `hyprctl repl`                                        | Syntax error in `hyprland.lua` | Fix syntax via REPL or TTY.               |
| No screen share    | Portals    | `systemctl --user status xdg-desktop-portal-hyprland` | D-Bus environment missing      | Run `dbus-update-activation-environment`. |
| Flickering windows | XWayland   | `hyprctl clients`                                     | Missing explicit sync          | Verify NVIDIA drivers/Aquamarine sync.    |

## 43. DIAGNOSTIC COMMAND REFERENCE

- `hyprctl repl`: Interactive Lua debugging.
- `hyprctl get_loaded_plugins()`: List active memory injections.
- `journalctl -k`: Kernel ring buffer.
- `wpctl status`: PipeWire node graphs.

## 44. AI DECISION TREES

**"Hyprland starts to a red screen (or default fallback)"**

1. Check syntax of `hyprland.lua`.
2. Did a required module (e.g., `require("custom.env")`) fail to load?
3. Review `$XDG_RUNTIME_DIR/hypr/` logs for Lua stack traces.
4. Correct the file and use `hyprctl reload`.

## 45. VERIFICATION RULES

A configuration is not valid until it runs. Syntax validation in Lua does not guarantee runtime safety. The AI must instruct the user to verify module loading via `hyprctl repl`.

## 46. CHANGE MANAGEMENT

Isolate changes. If the user wants to add a keybind, modify `keybinds.lua` only. Do not touch `monitors.lua` unless requested.

## 47. ENGINEERING PRINCIPLES

The "World Machine" requires rigid structural integrity.

- **KISS:** Don't write complex Lua state machines if a simple window rule works.
- **DRY:** Use Lua tables to iterate over repetitive workspace generation.

## 48. COMMAND SAFETY

- **SAFE:** `hyprctl repl`, `hyprctl clients`.
- **CAUTION:** Reloading Lua modules in real-time.
- **DESTRUCTIVE:** `rm -rf ~/.config/hypr/*`.

## 49. CONFIGURATION EXAMPLES

**Iterative Workspace Generation (Lua):**

```
for i = 1, 9 do
    hl.bind("SUPER", tostring(i), function() hl.dispatch("workspace", tostring(i)) end)
    hl.bind("SUPER SHIFT", tostring(i), function() hl.dispatch("movetoworkspace", tostring(i)) end)
end

```

## 50. PRODUCTION CHECKLIST

- [ ] Base `.lua` modules correctly imported.
- [ ] `systemd` user targets handle daemons.
- [ ] Polkit authentication agent verified.
- [ ] Explicit sync confirmed on external monitors.

## 51. AI OPERATING RULES

1. **Strict Honesty:** If the user's Lua code is inefficient, tell them exactly why.
2. **No Hand-Holding:** Provide the exact solution and explain the architectural flaw. Do not flatter their setup.
3. **Target Accuracy:** Ground all logic in the Hyprland 0.56.2 API (Lua, Aquamarine, explicit sync).
4. **Reject Flawed Premises:** If a user requests an X11 solution for a Wayland problem, deny the request and explain the Wayland architecture.
