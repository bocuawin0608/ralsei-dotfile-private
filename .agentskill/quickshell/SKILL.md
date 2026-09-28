# Quickshell Engineering Standard (skill.md)

**Author:** Niko, Principal Desktop Shell Architect
**Purpose:** High-authority engineering knowledge base for building, debugging, reviewing, refactoring, and architecting production-grade Quickshell configurations.
**Target Audience:** AI Coding Agents and Senior Engineers.

## 1. Quickshell Architecture
Quickshell is a Wayland/X11 shell toolkit based on QtQuick and QML. It is not a configuration file for a pre-built bar (like Waybar); it is a runtime environment executing a full UI framework.

*   **Qt Runtime & QML Engine:** The core is the Qt event loop. QML provides a declarative object tree. JavaScript executes synchronously within this event loop.
*   **Component Tree:** UI and logic are instantiated as a tree of QObjects.
*   **Lifecycle & Hot Reload:** Quickshell supports dynamic hot reloading. When `shell.qml` changes, the engine destroys the old tree and constructs a new one. State *inside* the QML tree is lost unless explicitly persisted.
*   **Reactive Updates:** Bound properties update automatically when their dependencies change.
*   **Object Ownership:** Objects are owned by their QML parent. Dynamically created objects (via `Component.createObject` or `Variants`) must be managed carefully to avoid memory leaks.

## 2. Mental Model
Do not write imperative Qt/C++ logic disguised as QML.
*   **Declarative > Imperative:** Describe *what* the UI should look like based on state, not *how* to change the UI.
*   **Source of Truth:** State must have a single owner. UI components reflect state; they do not store copies of it.
*   **One-Way Data Flow:** Services/System -> State -> QML Properties -> UI. Events flow up (callbacks/signals), state flows down (bindings).
*   **Side Effects:** Visual components (`PanelWindow`, `Rectangle`) must *never* spawn raw system processes or hold heavy logic. Side effects belong in headless `Scope` components or dedicated Service Singletons.

## 3. QML Fundamentals Required for Quickshell
To write Quickshell, you must master QML idiosyncrasies:
*   **Property Bindings:** `width: parent.width / 2` is a binding. If `parent.width` changes, `width` updates automatically.
*   **Binding Breakage:** Assigning a value imperatively (`item.width = 100`) destroys the declarative binding forever. **Never do this** unless intentionally breaking a binding.
*   **Aliases:** `property alias text: label.text` exposes an internal property without breaking encapsulation.
*   **Object IDs:** `id` is resolved at component scope. Do not use global IDs across different files.
*   **Attached Properties:** Properties attached by context (e.g., `Component.onCompleted`).

## 4. Quickshell Modules and APIs
Do not hallucinate APIs. Use the following core modules correctly:
*   **`import Quickshell`**: Provides core shell types.
    *   `PanelWindow`: A layer-shell window used for bars, docks, and overlays.
    *   `FloatingWindow`: A standard desktop window.
    *   `Scope`: A non-visual container for grouping logical components (models, processes, timers).
    *   `Variants`: Dynamically instantiates a `Component` for every item in a model (crucial for multi-monitor support).
    *   `Quickshell.screens`: A reactive list of active monitors.
*   **`import Quickshell.Io`**: Provides system I/O capabilities.
    *   `Process`: Spawns external processes.
    *   `StdioCollector`: Reads `stdout`/`stderr` from a `Process`.
    *   `FileView`: Reads and watches files for changes.
*   **Services**: `Quickshell.Services.Pipewire`, `Quickshell.Services.Notifications`, etc., handle specialized system states.

## 5. Shell Surface Architecture
Wayland layer-shell governs how components interact with the compositor.
*   **Anchors:** Use `anchors { top: true; left: true; right: true }` in `PanelWindow` to attach a bar to screen edges.
*   **Exclusive Zones:** `implicitHeight` / `implicitWidth` on an anchored `PanelWindow` tells the compositor to reserve screen space so regular windows don't overlap it.
*   **Focus & Keyboard:** Layer surfaces do not receive keyboard focus by default. If you build an app launcher, you must explicitly configure keyboard interactivity.

## 6. Multi-Monitor Architecture
This is where amateurs fail. Do not hardcode monitors.
*   **The Rule:** A shell must react to hotplugging without restarting.
*   **The Pattern:** Use `Variants` with `Quickshell.screens`.
*   **Avoiding Duplicate State:** If you put a `Process` inside the `PanelWindow` delegate, it will spawn a new process *per monitor*. This wastes CPU and causes race conditions. Move state and processes to a global `Scope`.

```qml
// GOOD MULTI-MONITOR ARCHITECTURE
Scope {
    id: globalState
    property string time: ""

    // 1. One process, global state
    Process {
        command: ["date"]
        running: true
        stdout: StdioCollector { onStreamFinished: globalState.time = this.text.trim() }
    }

    // 2. Reactively map state to UI per-screen
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData // Binds to the specific monitor
                
                Text { text: globalState.time }
            }
        }
    }
}
```

## 7. Hyprland Integration
Hyprland operates via IPC sockets.
*   **Native vs Command:** Prefer native Quickshell integration singletons (e.g., `Quickshell.Hyprland` if available in your version) over spawning `socat` manually.
*   **Subscriptions:** Listen to Hyprland's event socket (active window changes, workspace changes). **Do not poll `hyprctl`.**
*   **State Separation:** Maintain an internal QML model of workspaces based on IPC events rather than re-querying the whole state on every click.

## 8. Wayland Integration
*   **Layer Shell vs XDG Shell:** `PanelWindow` uses `wlr-layer-shell` (backgrounds, panels, overlays). `FloatingWindow` uses `xdg-shell` (standard apps).
*   **Outputs:** Wayland outputs (monitors) can appear and disappear at any time. Bind strictly to `modelData` provided by `Quickshell.screens`.

## 9. External Processes
Process management is the #1 cause of performance death in custom shells.
*   **Array Commands:** `command: ["brightnessctl", "g"]`. NEVER use `bash -c "..."` unless absolutely necessary (e.g., complex piping).
*   **No Shell Injection:** Arrays prevent shell injection and avoid spawning unnecessary `sh` wrappers.
*   **Process Lifecycle:** A `Process` is tied to its parent QObject. If the parent is destroyed, the process is terminated. 
*   **Zombies:** Ensure long-running processes (like `journalctl -f`) are killed when the shell unloads/reloads.

## 10. IPC Architecture
*   **Avoid Polling:** If a system exposes a socket, DBus interface, or event stream, use it. Polling is a last resort.
*   **Request/Response vs Streams:** Use simple `Process` executions for one-off actions (e.g., `volume up`). Use persistent `Process` with a `StdioCollector` or DBus for event streams (e.g., `volume changed by another app`).

## 11. State Management
*   **Local State:** `property bool isOpen: false` inside a Popup. Safe.
*   **Global State:** Should live in headless `Scope` or QML `pragma Singleton` files.
*   **Derived State:** Use QML bindings. If `volume` is 0, `property bool isMuted: volume === 0` is derived state. Do not create a separate process or function to calculate `isMuted`.

## 12. Reactive Architecture
*   **BAD (The imperative trap):** 
    ```qml
    Timer { 
        interval: 1000; running: true; repeat: true
        onTriggered: process.run() // Burns CPU, battery dies.
    }
    ```
*   **GOOD (The reactive way):**
    Subscribe to a DBus signal or Wayland event. Update the property. The UI automatically repaints.

## 13. Component Architecture
Adapt SOLID to QML:
*   **Single Responsibility:** A widget should display data, not fetch it. 
*   **Interface Segregation:** Pass exactly what a component needs. Don't pass the entire `Hyprland` object if the component only needs `activeWorkspaceId`.
*   **Dependency Injection:** Define `property string volumeLevel` in your UI component. Let the parent inject the value from the Service.

## 14. Project Structure
A production-grade shell is modular.
```text
shell/
├── shell.qml          # Entry point, mounts globals and screens
├── services/          # Headless singletons (Audio, Network, Hyprland)
├── components/        # Dumb UI primitives (Buttons, Sliders, Cards)
├── widgets/           # Smart UI components (VolumeSlider, Workspaces)
├── panels/            # Top-level window assemblies (TopBar, Dock)
└── assets/            # Fonts, Icons, SVG
```

## 15. Service Layer
Services abstract the system. A `VolumeService.qml` singleton should:
1.  Run the necessary `Process` or DBus calls.
2.  Parse the stdout/events.
3.  Expose `property int currentVolume`.
4.  Expose `function setVolume(val)`.
The UI *only* talks to `currentVolume` and `setVolume`.

## 16. Model Layer
When listing data (Workspaces, Notifications, Wi-Fi networks), use QML `ListModel` or array models.
*   Transform raw JSON/Process output into an array of objects.
*   Assign to a `ListView` or `Repeater` model.
*   Delegate handles rendering.

## 17. UI Architecture
Keep `shell.qml` empty except for mounting dependencies.
```qml
// shell.qml
import Quickshell
import "panels"
import "services"

Scope {
    ServicesRoot {} // Initializes DBus, IPC, State
    
    Variants {
        model: Quickshell.screens
        delegate: Component { TopBar { screen: modelData } }
    }
}
```

## 18. Animation Architecture
*   Use `Behavior on property { NumberAnimation { duration: 200 } }` for implicit animations.
*   **Avoid Animation Storms:** Do not animate properties that update at 60Hz (like CPU usage percentage), as it will constantly invalidate the render tree.

## 19. Performance Engineering
Quickshell runs 24/7. Leaks and CPU burn are catastrophic.
*   **Target:** Idle CPU must be < 0.1%.
*   **No Unnecessary Bindings:** Do not bind a UI property to a massive JSON object if you only need one field. QML will re-evaluate the binding every time *any* part of the JSON object changes.
*   **Asset Memory:** Use standard SVG/PNG sizes. QML will cache them.

## 20. Memory Management
*   **Dynamic Objects:** If you use `Qt.createQmlObject()`, you *must* call `.destroy()` when done.
*   **Variants Lifecycle:** Objects created by `Variants` are destroyed automatically when the item is removed from the `model`. This safely handles monitor hotplugging.

## 21. Concurrency and Asynchronous Programming
*   QML JavaScript is strictly synchronous.
*   If a `Process` takes 2 seconds to run, *do not block*. The `Process` API is asynchronous. Handle the result in `onStreamFinished`.
*   Avoid race conditions: If a user clicks "Volume Up" 10 times rapidly, ensure your service batches the requests or uses a non-blocking IPC message rather than spawning 10 `Process` instances.

## 22. Error Handling
*   If a command fails, `StdioCollector` might receive an empty string or error message. Handle `undefined` and `""` safely.
*   **Fallback UI:** If the network service crashes, the Wi-Fi icon should show a disconnected state, not crash the entire shell.

## 23. Logging and Diagnostics
*   Use `console.log()`, `console.warn()`, and `console.error()`.
*   Prefix logs by subsystem: `console.log("[HyprlandService] Workspace event:", data)`.
*   Silence repetitive logs in production. Do not log "CPU updated" every second.

## 24. Security
You are building software with the user's desktop privileges.
*   **Command Injection:** 
    *   *Lethal:* `command: ["bash", "-c", "playerctl play-pause " + songName]` (If `songName` is `"; rm -rf ~"`, the system dies).
    *   *Safe:* `command: ["playerctl", "play-pause", songName]`.
*   **Secrets:** Never write API keys or passwords in QML files. Load them via environment variables or secure credential stores.

## 25. Configuration Management
*   Configs live in `~/.config/quickshell/`.
*   Use `Quickshell.Io.FileView` to dynamically load and parse `.json` or `.ini` files. This allows changing themes without recompiling or reloading the whole shell.

## 26. Theming System
Use a Singleton for theming.
```qml
// Theme.qml
pragma Singleton
import QtQuick

QtObject {
    property color bg: "#1E1E2E"
    property color fg: "#CDD6F4"
    property color accent: "#89B4FA"
    property int radius: 8
}
```
*   Reference as `color: Theme.bg`. Never hardcode `#1E1E2E` in a widget.

## 27. Responsive Desktop Shell Design
*   Bars must scale. Use `Math.round(Theme.baseSize * scalingFactor)` or rely on Qt's built-in font metrics instead of hardcoded pixel values like `width: 300`.
*   Handle varying screen widths: A top bar on a 1080p screen and an ultrawide require `Layout.fillWidth: true` and flexible spacers, not fixed widths.

## 28. Accessibility
*   Maintain WCAG contrast ratios for text.
*   Ensure critical status indicators (battery low, network disconnected) do not rely solely on color (use distinct icons).

## 29. Testing
*   **Unit Logic:** Test complex JavaScript functions externally using Node or Qt's QJS engine.
*   **Smoke Testing:** Run Quickshell from a terminal. If it throws a parse error or QML binding loop warning in the console on startup, *reject the code*.

## 30. Debugging Methodology
When a widget breaks:
1.  Check Quickshell terminal output for `Binding loop detected` or `ReferenceError`.
2.  Isolate: Remove half the QML file. Does it still break?
3.  Check system source: Run the CLI tool you are wrapping. Is it returning what you expect?
4.  NEVER guess. Follow the data flow.

## 31. Common Anti-Patterns
*   **Giant `shell.qml`:** Putting 1000 lines of UI in one file. *Breaks maintainability.*
*   **Polling Everything:** Using `Timer` to run `date` or `free -m`. *Kills battery.*
*   **Duplicated Global State:** Putting `Process` inside a monitor delegate. *Causes redundant CPU load and sync bugs*.
*   **UI Owning Logic:** Writing parsing logic inside an `onClicked` handler. *Breaks separation of concerns.*

## 32. Production Architecture Patterns
**The Standard Modular Shell:**
*   **App.qml** (Mounts Services and variants).
*   **Services/Hyprland.qml** (Singleton, owns socket/events).
*   **Panels/TopBar.qml** (Assembles widgets).
*   **Widgets/Workspaces.qml** (Reads from `Services/Hyprland.qml`).

## 33. Dependency Direction
Dependencies must point inward toward the system, never outward.
*   `UI` depends on `Model`.
*   `Model` depends on `Service`.
*   `Service` depends on `System` (Process/Sockets).
*   **FORBIDDEN:** A `Service` modifying a `UI` component directly by ID.

## 34. Code Review Rules
When reviewing AI-generated or human code, enforce:
1.  Are there any `Timer` nodes polling a process? (Reject if an event-based alternative exists).
2.  Are processes spawned safely using arrays?
3.  Is state duplicated?
4.  Does it support multiple monitors automatically via `Variants`?
5.  Are there QML binding loops?

## 35. AI Coding Rules
When generating Quickshell code:
1.  **Read existing structure:** Use provided services; do not invent new ones.
2.  **Avoid hallucination:** If you do not know the exact Quickshell API, use standard QtQuick QML elements.
3.  **No `bash -c`:** Always use array formatting for commands.
4.  **Prioritize Event-Driven:** Default to subscriptions, not polling.
5.  **Respect Multi-Monitor:** Always wrap panels in `Variants { model: Quickshell.screens }`.

## 36. Refactoring Rules
*   Extract pure functions to `.js` files.
*   Extract duplicated UI blocks into reusable QML components.
*   Move `Process` and data-fetching logic out of UI files into singletons.

## 37. Performance Budgets
*   **Idle CPU:** < 0.1%.
*   **RAM:** < 150MB for the entire shell framework (excluding heavy image assets).
*   **Startup Time:** < 500ms to first paint.

## 38. Production Readiness Checklist
- [ ] Multi-monitor hotplug tested (no zombie bars, no duplicate processes).
- [ ] Zero `bash -c` commands.
- [ ] Zero polling for properties that expose event sockets.
- [ ] Terminal output is free of QML `ReferenceError` and `Binding loop` warnings.
- [ ] Theming is centralized in a Singleton, no hardcoded colors.

## 39. Quick Reference

**Core Imports:**
```qml
import QtQuick
import Quickshell
import Quickshell.Io
```

**Safe Process Execution:**
```qml
Process {
    command: ["playerctl", "next"]
    running: true
}
```

**Multi-Monitor Bootstrapping:**
```qml
Scope {
    Variants {
        model: Quickshell.screens
        delegate: Component {
            PanelWindow {
                required property var modelData
                screen: modelData
            }
        }
    }
}
```

## References
1. Quickshell Official Documentation & Types
2. Quickshell Architecture & Multi-Monitor Guide
3. LobeHub Quickshell Dotfiles/Skill Marketplace Notes
4. QtQuick QML Language Reference
