import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services" as Services

FloatingWindow {
    id: sessionMenu

    property bool isVisible: false
    visible:  isVisible
    width:    360
    height:   240
    title:    "Session"

    x: (screen.width  - width)  / 2
    y: (screen.height - height) / 2

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    function toggle() { isVisible = !isVisible }

    Keys.onEscapePressed: isVisible = false

    Rectangle {
        anchors.fill: parent
        color:        Services.Theme.surfaceContainer
        radius:       Services.Theme.radius

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Services.Theme.spacing * 2
            width: parent.width - Services.Theme.spacing * 4

            Text {
                Layout.alignment: Qt.AlignHCenter
                text:  "Session"
                color: Services.Theme.onSurface
                font.pixelSize: 20
                font.weight:    Font.Medium
            }

            GridLayout {
                Layout.fillWidth: true
                columns:  2
                rowSpacing:    Services.Theme.spacing
                columnSpacing: Services.Theme.spacing

                Repeater {
                    model: [
                        { label: "Lock",     icon: "🔒", color: Services.Theme.secondary,  cmd: ["loginctl", "lock-session"] },
                        { label: "Sleep",    icon: "💤", color: Services.Theme.tertiary,   cmd: ["systemctl", "suspend"]     },
                        { label: "Restart",  icon: "🔄", color: Services.Theme.primary,    cmd: ["systemctl", "reboot"]      },
                        { label: "Shutdown", icon: "⏻",  color: Services.Theme.error,      cmd: ["systemctl", "poweroff"]    }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 60
                        radius: Services.Theme.radius
                        color:  btnHover.containsMouse
                            ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.2)
                            : Services.Theme.surfaceContainerHigh

                        Behavior on color { ColorAnimation { duration: 120 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text:  modelData.icon
                                font.pixelSize: 22
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text:  modelData.label
                                color: Services.Theme.onSurface
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id:           btnHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                sessionActionProc.command = modelData.cmd
                                sessionActionProc.running = true
                                sessionMenu.isVisible = false
                            }
                        }
                    }
                }
            }

            Button {
                Layout.fillWidth: true
                text: "Cancel  (Esc)"
                onClicked: sessionMenu.isVisible = false
                background: Rectangle {
                    color:  Services.Theme.surfaceContainerHigh
                    radius: Services.Theme.radius / 2
                }
                contentItem: Text {
                    text:  parent.text
                    color: Services.Theme.onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                    font.pixelSize: 13
                }
            }
        }
    }

    Process { id: sessionActionProc; running: false; command: [] }

    Behavior on opacity { NumberAnimation { duration: Services.Theme.animDuration } }
    opacity: isVisible ? 1.0 : 0.0
}
