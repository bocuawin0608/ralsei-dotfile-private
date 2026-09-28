import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services" as Services
import "../components" as Components

PanelWindow {
    id: topBar

    // screen is set by Variants delegate in shell.qml
    property alias screen: topBar.screen

    anchors {
        top:   true
        left:  true
        right: true
    }
    height:          36
    color:           "transparent"
    exclusionMode:   ExclusionMode.Exclusive
    WlrLayershell.layer:    WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color:        Services.Theme.surfaceAlpha85
        radius:       0

        RowLayout {
            anchors {
                fill:           parent
                leftMargin:     Services.Theme.spacing
                rightMargin:    Services.Theme.spacing
            }
            spacing: Services.Theme.spacing

            // ── Workspaces ─────────────────────────────────────────
            Components.WorkspaceWidget { id: workspaceWidget }

            // ── Active window title ─────────────────────────────────
            Components.ActiveWindowWidget {}

            Item { Layout.fillWidth: true }

            // ── Media ───────────────────────────────────────────────
            Components.MediaWidget { visible: Services.MediaService.title !== "" }

            Item { Layout.fillWidth: true }

            // ── Clock ───────────────────────────────────────────────
            Components.ClockWidget {}

            Item { Layout.fillWidth: true }

            // ── System stats ────────────────────────────────────────
            Components.SystemStatsWidget {}

            // ── Network ─────────────────────────────────────────────
            Components.NetworkWidget {}

            // ── Volume ──────────────────────────────────────────────
            Components.VolumeWidget {}

            // ── Notification indicator ──────────────────────────────
            Components.NotificationIndicator {}
        }
    }
}
