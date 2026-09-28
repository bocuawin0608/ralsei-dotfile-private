import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../services" as Services

PanelWindow {
    id: sidebarRight

    property bool isVisible: false

    visible:   true
    width:     320
    anchors {
        top:    true
        bottom: true
        right:  true
    }
    color:         "transparent"
    exclusionMode: isVisible ? ExclusionMode.Exclusive : ExclusionMode.Ignore
    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    function toggle() { isVisible = !isVisible }

    property real slideX: isVisible ? 0 : width
    Behavior on slideX { NumberAnimation { duration: Services.Theme.animDuration; easing.type: Easing.OutCubic } }

    NotificationServer { id: notifServer }

    Rectangle {
        x:      sidebarRight.slideX
        width:  parent.width
        height: parent.height
        color:  Services.Theme.surfaceContainer

        ColumnLayout {
            anchors { fill: parent; margins: Services.Theme.spacing }
            spacing: Services.Theme.spacing

            // ── Section header ────────────────────────────────────
            Text {
                text:  "Notifications"
                color: Services.Theme.onSurface
                font.pixelSize:  14
                font.weight:     Font.Medium
            }

            // ── Notification list ─────────────────────────────────
            ListView {
                Layout.fillWidth:  true
                Layout.preferredHeight: Math.min(contentHeight, 280)
                clip:    true
                spacing: 4
                model:   notifServer.trackedNotifications

                delegate: Rectangle {
                    width:   ListView.view.width
                    height:  notifCol.implicitHeight + 16
                    radius:  Services.Theme.radius / 2
                    color:   Services.Theme.surfaceContainerHigh

                    ColumnLayout {
                        id: notifCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                        spacing: 2

                        Text {
                            text:  modelData.summary || ""
                            color: Services.Theme.onSurface
                            font.pixelSize: 13
                            font.weight:    Font.Medium
                            wrapMode:       Text.WordWrap
                            Layout.fillWidth: true
                        }
                        Text {
                            text:    modelData.body || ""
                            color:   Services.Theme.onSurfaceVariant
                            font.pixelSize: 12
                            wrapMode:       Text.WordWrap
                            visible:        modelData.body !== ""
                            Layout.fillWidth: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked:    modelData.dismiss()
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible:          notifServer.trackedNotifications.length === 0
                    text:             "No notifications"
                    color:            Services.Theme.onSurfaceVariant
                    font.pixelSize:   13
                }
            }

            // ── Quick toggles ─────────────────────────────────────
            Text {
                text:  "Quick Toggles"
                color: Services.Theme.onSurface
                font.pixelSize: 14
                font.weight:    Font.Medium
            }

            RowLayout {
                spacing: 8
                Repeater {
                    model: [
                        { label: "WiFi",       icon: "network-wireless",    cmd: ["nmcli", "radio", "wifi", "toggle"] },
                        { label: "BT",         icon: "bluetooth",           cmd: ["bash", "-c", "bluetoothctl power on || bluetoothctl power off"] },
                        { label: "Night",      icon: "night-light",         cmd: ["bash", "-c", "gammastep -O 4000 || pkill gammastep"] }
                    ]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height:           52
                        radius:           Services.Theme.radius
                        color:            Services.Theme.surfaceContainerHigh

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                text:  modelData.icon.substring(0, 2) // simple emoji fallback
                                color: Services.Theme.primary
                                font.pixelSize: 18
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text:  modelData.label
                                color: Services.Theme.onSurface
                                font.pixelSize: 10
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                toggleProc.command = modelData.cmd
                                toggleProc.running = true
                            }
                        }
                        Process { id: toggleProc; running: false; command: [] }
                    }
                }
            }

            // ── Volume slider ──────────────────────────────────────
            Text { text: "Volume"; color: Services.Theme.onSurfaceVariant; font.pixelSize: 12 }
            RowLayout {
                spacing: 8
                Text { text: "🔈"; color: Services.Theme.onSurface }
                Slider {
                    Layout.fillWidth: true
                    from: 0; to: 150
                    value: Services.AudioService.volume
                    stepSize: 1
                    onMoved: Services.AudioService.setVolume(value)
                    background: Rectangle {
                        x:      parent.leftPadding
                        y:      parent.topPadding + parent.availableHeight / 2 - height / 2
                        width:  parent.availableWidth; height: 4; radius: 2
                        color:  Services.Theme.surfaceVariant
                        Rectangle {
                            width:  parent.width * parent.parent.visualPosition
                            height: parent.height; radius: parent.radius
                            color:  Services.Theme.primary
                        }
                    }
                    handle: Rectangle {
                        x:      parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y:      parent.topPadding + parent.availableHeight / 2 - height / 2
                        width:  14; height: 14; radius: 7
                        color:  Services.Theme.primary
                    }
                }
                Text {
                    text:  Services.AudioService.volume + "%"
                    color: Services.Theme.onSurface
                    font.pixelSize: 12
                    width: 36
                }
            }

            // ── Brightness slider ──────────────────────────────────
            Text { text: "Brightness"; color: Services.Theme.onSurfaceVariant; font.pixelSize: 12 }
            RowLayout {
                spacing: 8
                Text { text: "🔆"; color: Services.Theme.onSurface }
                Slider {
                    id: brightnessSlider
                    Layout.fillWidth: true
                    from: 1; to: 100
                    value: 80
                    stepSize: 1
                    onMoved: {
                        brightnessSetProc.command = ["brightnessctl", "s", Math.round(value) + "%"]
                        brightnessSetProc.running = true
                    }
                    background: Rectangle {
                        x:      parent.leftPadding
                        y:      parent.topPadding + parent.availableHeight / 2 - height / 2
                        width:  parent.availableWidth; height: 4; radius: 2
                        color:  Services.Theme.surfaceVariant
                        Rectangle {
                            width:  parent.width * parent.parent.visualPosition
                            height: parent.height; radius: parent.radius
                            color:  Services.Theme.tertiary
                        }
                    }
                    handle: Rectangle {
                        x:      parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y:      parent.topPadding + parent.availableHeight / 2 - height / 2
                        width:  14; height: 14; radius: 7
                        color:  Services.Theme.tertiary
                    }
                    Process { id: brightnessSetProc; running: false; command: [] }
                }
            }

            // ── Theme toggle ───────────────────────────────────────
            RowLayout {
                Text { text: "Theme:"; color: Services.Theme.onSurfaceVariant; font.pixelSize: 12 }
                Switch {
                    checked: Services.Theme.isDark
                    onToggled: {
                        Services.Theme.isDark = checked
                        Services.Theme.reload()
                    }
                }
                Text {
                    text:  Services.Theme.isDark ? "Dark" : "Light"
                    color: Services.Theme.onSurface
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
