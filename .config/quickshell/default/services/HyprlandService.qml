pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: hyprlandSvc

    // ──────────────────────────────────────────────────────────────
    //  Public state
    // ──────────────────────────────────────────────────────────────
    property int    activeWorkspace:    1
    property string activeWindow:       ""
    property string activeWindowClass:  ""
    property var    workspaces:         []
    property var    clients:            []

    // ──────────────────────────────────────────────────────────────
    //  Hyprland IPC event socket listener
    // ──────────────────────────────────────────────────────────────
    property string _hyprSocket: {
        var instance = Qt.getenv("HYPRLAND_INSTANCE_SIGNATURE")
        return instance ? ("/tmp/hypr/" + instance + "/.socket2.sock") : ""
    }

    // Poll workspaces/clients on start via hyprctl
    Process {
        id: workspacesProc
        running: false
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    hyprlandSvc.workspaces = data.map(function(ws) {
                        return { id: ws.id, name: ws.name, windows: ws.windows }
                    })
                } catch(e) {}
            }
        }
    }

    Process {
        id: clientsProc
        running: false
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    hyprlandSvc.clients = JSON.parse(text)
                } catch(e) {}
            }
        }
    }

    Process {
        id: activeWindowProc
        running: false
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    hyprlandSvc.activeWindow       = data.title       || ""
                    hyprlandSvc.activeWindowClass  = data.class       || ""
                    hyprlandSvc.activeWorkspace     = data.workspace ? data.workspace.id : hyprlandSvc.activeWorkspace
                } catch(e) {}
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  IPC event socket reader (line-by-line via SplitParser)
    // ──────────────────────────────────────────────────────────────
    Process {
        id: ipcListener
        running: hyprlandSvc._hyprSocket !== ""
        command: ["socat", "-u", ("UNIX-CONNECT:" + hyprlandSvc._hyprSocket), "STDIO"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                hyprlandSvc._handleEvent(line.trim())
            }
            onStreamFinished: {
                // Reconnect on close
                Qt.callLater(function() { ipcListener.running = true })
            }
        }
    }

    function _handleEvent(line) {
        if (!line) return
        var sep = line.indexOf(">>");
        if (sep < 0) return
        var ev   = line.substring(0, sep)
        var data = line.substring(sep + 2)

        switch (ev) {
        case "workspace":
            activeWorkspace = parseInt(data) || activeWorkspace
            workspacesProc.running = true
            break
        case "focusedmon":
            // data: monitorName,workspaceId
            var parts = data.split(",")
            if (parts.length >= 2) activeWorkspace = parseInt(parts[1]) || activeWorkspace
            break
        case "activewindow":
            var wp = data.split(",")
            activeWindowClass = wp[0] || ""
            activeWindow      = wp.slice(1).join(",") || ""
            break
        case "openwindow":
        case "closewindow":
        case "movewindow":
            clientsProc.running = true
            workspacesProc.running = true
            break
        case "destroyworkspace":
        case "createworkspace":
            workspacesProc.running = true
            break
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Public API
    // ──────────────────────────────────────────────────────────────
    function focusWorkspace(id) {
        _dispatchProc.command = ["hyprctl", "dispatch", "workspace", String(id)]
        _dispatchProc.running = true
    }

    function moveToWorkspace(id) {
        _dispatchProc.command = ["hyprctl", "dispatch", "movetoworkspace", String(id)]
        _dispatchProc.running = true
    }

    Process {
        id: _dispatchProc
        running: false
        command: []
    }

    Component.onCompleted: {
        workspacesProc.running = true
        clientsProc.running    = true
        activeWindowProc.running = true
    }
}
