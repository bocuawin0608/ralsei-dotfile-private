import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services" as Services

PanelWindow {
    id: overview

    // ──────────────────────────────────────────────────────────────
    //  State
    // ──────────────────────────────────────────────────────────────
    property bool isVisible:        false
    property int  mode:             0          // 0=search+workspace, 1=workspace, 2=clipboard, 3=emoji
    property string searchText:     ""
    property int    selectedIndex:  0

    visible: isVisible

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // ──────────────────────────────────────────────────────────────
    //  Public API (called from IPC handlers in shell.qml)
    // ──────────────────────────────────────────────────────────────
    function toggle()           { isVisible = !isVisible; if (isVisible) { mode = 0; searchText = "" } }
    function toggleWorkspaces() { isVisible = !isVisible; if (isVisible) { mode = 1; searchText = "" } }
    function toggleClipboard()  { isVisible = !isVisible; if (isVisible) { mode = 2; searchText = "" } }
    function toggleEmoji()      { isVisible = !isVisible; if (isVisible) { mode = 3; searchText = "" } }
    function close()            { isVisible = false }

    // ──────────────────────────────────────────────────────────────
    //  Calculator process
    // ──────────────────────────────────────────────────────────────
    property string calcResult: ""
    Process {
        id: calcProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: { overview.calcResult = text.trim() }
        }
    }

    function evaluateExpr(expr) {
        // Static array form only – strip non-math chars for safety
        var safe = expr.replace(/[^0-9+\-*/.() %]/g, "")
        if (!safe) return
        calcProc.command = ["bash", "-c", "echo \"" + safe + "\" | bc -l"]
        calcProc.running = true
    }

    // ──────────────────────────────────────────────────────────────
    //  Filtered window / app lists
    // ──────────────────────────────────────────────────────────────
    property var filteredClients: {
        if (!searchText) return Services.HyprlandService.clients
        var q = searchText.toLowerCase()
        return Services.HyprlandService.clients.filter(function(c) {
            return (c.title  && c.title.toLowerCase().indexOf(q)  >= 0) ||
                   (c.class  && c.class.toLowerCase().indexOf(q)  >= 0)
        })
    }

    property bool isCalcMode: searchText.length > 0 &&
        /^[\d\s+\-*/.()%^]+$/.test(searchText.charAt(0))

    // ──────────────────────────────────────────────────────────────
    //  Background overlay
    // ──────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        Qt.rgba(
            Services.Theme.background.r,
            Services.Theme.background.g,
            Services.Theme.background.b, 0.88)

        MouseArea {
            anchors.fill: parent
            onClicked:    overview.close()
        }

        // ── Content column ─────────────────────────────────────────
        ColumnLayout {
            anchors {
                top:              parent.top
                left:             parent.left
                right:            parent.right
                topMargin:        60
                leftMargin:       parent.width * 0.1
                rightMargin:      parent.width * 0.1
            }
            spacing: Services.Theme.spacing * 2

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                height:           48
                radius:           Services.Theme.radius
                color:            Services.Theme.surfaceContainerHigh

                RowLayout {
                    anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                    Text {
                        text:  "⌕"
                        color: Services.Theme.onSurfaceVariant
                        font.pixelSize: 20
                    }
                    TextInput {
                        id:              searchInput
                        Layout.fillWidth: true
                        color:            Services.Theme.onSurface
                        font.pixelSize:   16
                        font.family:      Services.Theme.fontFamily
                        text:             overview.searchText
                        focus:            overview.isVisible && overview.mode === 0

                        onTextChanged: {
                            overview.searchText   = text
                            overview.selectedIndex = 0
                            if (overview.isCalcMode) overview.evaluateExpr(text)
                        }

                        Keys.onEscapePressed: overview.close()
                        Keys.onReturnPressed: {
                            if (overview.filteredClients.length > 0) {
                                var c = overview.filteredClients[overview.selectedIndex]
                                if (c) {
                                    focusWindowProc.command = ["hyprctl", "dispatch", "focuswindow",
                                        "address:" + c.address]
                                    focusWindowProc.running = true
                                    overview.close()
                                }
                            }
                        }
                        Keys.onUpPressed:   overview.selectedIndex = Math.max(0, overview.selectedIndex - 1)
                        Keys.onDownPressed: overview.selectedIndex = Math.min(
                            overview.filteredClients.length - 1, overview.selectedIndex + 1)

                        Process {
                            id: focusWindowProc
                            running: false
                            command: []
                        }
                    }

                    // Calculator result
                    Text {
                        visible: overview.isCalcMode && overview.calcResult !== ""
                        text:    "= " + overview.calcResult
                        color:   Services.Theme.primary
                        font.pixelSize: 16
                    }
                }
            }

            // ── Workspace grid (mode 0 or 1) ───────────────────────
            Flickable {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                contentHeight:     wsGrid.implicitHeight
                clip:              true
                visible:           overview.mode === 0 || overview.mode === 1

                Grid {
                    id:       wsGrid
                    width:    parent.width
                    columns:  Math.max(1, Math.floor(parent.width / 260))
                    spacing:  Services.Theme.spacing

                    Repeater {
                        model: Services.HyprlandService.workspaces

                        delegate: Rectangle {
                            width:   (wsGrid.width - wsGrid.spacing * (wsGrid.columns - 1)) / wsGrid.columns
                            height:  140
                            radius:  Services.Theme.radius
                            color:   modelData.id === Services.HyprlandService.activeWorkspace
                                ? Qt.rgba(Services.Theme.primary.r, Services.Theme.primary.g,
                                          Services.Theme.primary.b, 0.2)
                                : Services.Theme.surfaceContainerHigh

                            Behavior on color { ColorAnimation { duration: Services.Theme.animDuration } }

                            ColumnLayout {
                                anchors { fill: parent; margins: 8 }
                                Text {
                                    text:  "WS " + modelData.name
                                    color: Services.Theme.onSurface
                                    font.pixelSize: 13
                                    font.weight:    Font.Medium
                                }

                                // Window chips in this workspace
                                Repeater {
                                    model: overview.filteredClients.filter(function(c) {
                                        return c.workspace && c.workspace.id === modelData.id
                                    })
                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        height:  24
                                        radius:  Services.Theme.radius / 2
                                        color:   overview.selectedIndex === index
                                            ? Services.Theme.primaryContainer
                                            : Services.Theme.surfaceContainerHighest
                                        Behavior on color { ColorAnimation { duration: 80 } }

                                        Text {
                                            anchors { left: parent.left; right: parent.right; margins: 6; verticalCenter: parent.verticalCenter }
                                            text:  modelData.title || modelData.class || "Window"
                                            color: Services.Theme.onSurface
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                focusWindowProc.command = ["hyprctl", "dispatch", "focuswindow",
                                                    "address:" + modelData.address]
                                                focusWindowProc.running = true
                                                overview.close()
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill:  parent
                                z: -1
                                onClicked: {
                                    Services.HyprlandService.focusWorkspace(modelData.id)
                                    overview.close()
                                }
                            }
                        }
                    }
                }
            }

            // ── Clipboard mode placeholder ─────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height:           300
                radius:           Services.Theme.radius
                color:            Services.Theme.surfaceContainerHigh
                visible:          overview.mode === 2
                Text {
                    anchors.centerIn: parent
                    text:  "Clipboard history\n(cliphist integration)"
                    color: Services.Theme.onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // ── Emoji mode placeholder ─────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height:           300
                radius:           Services.Theme.radius
                color:            Services.Theme.surfaceContainerHigh
                visible:          overview.mode === 3
                Text {
                    anchors.centerIn: parent
                    text:  "Emoji picker"
                    color: Services.Theme.onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    // ── Open/close animation ────────────────────────────────────────
    Behavior on opacity { NumberAnimation { duration: Services.Theme.animDuration } }
    opacity: isVisible ? 1.0 : 0.0
}
