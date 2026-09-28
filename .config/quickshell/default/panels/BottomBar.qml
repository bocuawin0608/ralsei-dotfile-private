import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../services" as Services
import "../components" as Components

PanelWindow {
    id: bottomBar

    anchors {
        bottom: true
        left:   true
        right:  true
    }
    height:         48
    color:          "transparent"
    exclusionMode:  ExclusionMode.Exclusive
    WlrLayershell.layer:        WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
        anchors.fill: parent
        color:        Services.Theme.surfaceAlpha60
        radius:       0

        RowLayout {
            anchors {
                fill:        parent
                leftMargin:  Services.Theme.spacing * 2
                rightMargin: Services.Theme.spacing * 2
            }
            spacing: Services.Theme.spacing

            // ── App dock shortcuts ─────────────────────────────────
            DockButton { icon: "utilities-terminal";  command: ["bash", "-c", "$TERMINAL || kitty"] }
            DockButton { icon: "web-browser";         command: ["bash", "-c", "$BROWSER || firefox"] }
            DockButton { icon: "system-file-manager"; command: ["bash", "-c", "$FILE_MANAGER || nautilus"] }
            DockButton { icon: "code";                command: ["bash", "-c", "$CODE_EDITOR || code"] }

            Item { Layout.fillWidth: true }

            // ── Media controls (center) ────────────────────────────
            RowLayout {
                visible: Services.MediaService.title !== ""
                spacing: 4

                ToolButton {
                    icon.name:   "media-skip-backward"
                    icon.color:  Services.Theme.onSurface
                    onClicked:   Services.MediaService.previous()
                }
                ToolButton {
                    icon.name:   Services.MediaService.playing
                        ? "media-playback-pause" : "media-playback-start"
                    icon.color:  Services.Theme.primary
                    onClicked:   Services.MediaService.playPause()
                }
                ToolButton {
                    icon.name:   "media-skip-forward"
                    icon.color:  Services.Theme.onSurface
                    onClicked:   Services.MediaService.next()
                }
            }

            Item { Layout.fillWidth: true }

            // ── Quick actions ──────────────────────────────────────
            ToolButton {
                icon.name:  "camera-photo"
                icon.color: Services.Theme.onSurface
                ToolTip.text: "Screenshot region"
                ToolTip.visible: hovered
                onClicked: {
                    screenshotProc.running = false
                    screenshotProc.running = true
                }
                Process {
                    id: screenshotProc
                    running: false
                    command: ["hyprshot", "--freeze", "--clipboard-only", "--mode", "region", "--silent"]
                }
            }

            ToolButton {
                icon.name:  "color-picker"
                icon.color: Services.Theme.onSurface
                ToolTip.text: "Pick color"
                ToolTip.visible: hovered
                onClicked: {
                    colorPickerProc.running = false
                    colorPickerProc.running = true
                }
                Process {
                    id: colorPickerProc
                    running: false
                    command: ["hyprpicker", "-a"]
                }
            }
        }
    }

    // ── Inline dock button component ──────────────────────────────
    component DockButton: ToolButton {
        property string icon: ""
        property var    command: []

        icon.name:  icon
        icon.color: Services.Theme.onSurface
        implicitWidth:  40
        implicitHeight: 40

        background: Rectangle {
            radius:  Services.Theme.radius / 2
            color:   parent.hovered
                ? Qt.rgba(Services.Theme.primary.r, Services.Theme.primary.g, Services.Theme.primary.b, 0.15)
                : "transparent"
            Behavior on color { ColorAnimation { duration: Services.Theme.animDuration } }
        }

        onClicked: {
            dockProc.command = command
            dockProc.running = true
        }
        Process {
            id: dockProc
            running: false
            command: []
        }
    }
}
