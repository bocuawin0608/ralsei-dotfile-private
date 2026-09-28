import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./services" as Services

FloatingWindow {
    id: welcomeWindow

    property bool isVisible: true
    visible:  isVisible
    width:    640
    height:   500
    title:    "Quickshell — Key Shortcuts"

    x: 100
    y: 100

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    function toggle() { isVisible = !isVisible }

    Keys.onEscapePressed: isVisible = false

    Rectangle {
        anchors.fill: parent
        color:        Services.Theme.surfaceContainer
        radius:       Services.Theme.radius

        ColumnLayout {
            anchors { fill: parent; margins: Services.Theme.spacing * 2 }
            spacing: Services.Theme.spacing

            // Title bar
            RowLayout {
                Text { text: "⌨  Key Shortcuts"; color: Services.Theme.onSurface; font.pixelSize: 20; font.weight: Font.Medium }
                Item { Layout.fillWidth: true }
                ToolButton {
                    text: "✕"
                    onClicked: welcomeWindow.isVisible = false
                    background: Rectangle { color: parent.hovered ? Services.Theme.errorContainer : "transparent"; radius: 4 }
                    contentItem: Text { text: parent.text; color: Services.Theme.onSurface; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }

            ScrollView {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                clip: true

                GridLayout {
                    width: parent.width
                    columns:     2
                    columnSpacing: Services.Theme.spacing * 2
                    rowSpacing:  4

                    Repeater {
                        model: [
                            { key: "SUPER + SUPER",       desc: "Toggle search / overview"     },
                            { key: "SUPER + Tab",         desc: "Overview workspaces"           },
                            { key: "SUPER + V",           desc: "Clipboard history"             },
                            { key: "SUPER + Period",      desc: "Emoji picker"                  },
                            { key: "SUPER + A",           desc: "Left sidebar (AI/Media)"       },
                            { key: "SUPER + N",           desc: "Right sidebar (Notifs)"        },
                            { key: "SUPER + Slash",       desc: "Cheatsheet (this window)"      },
                            { key: "SUPER + M",           desc: "Media controls"                },
                            { key: "SUPER + G",           desc: "Widget overlay"                },
                            { key: "CTRL+ALT+Delete",     desc: "Session menu"                  },
                            { key: "SUPER + J",           desc: "Toggle bars"                   },
                            { key: "CTRL+SUPER+T",        desc: "Wallpaper selector"            },
                            { key: "CTRL+SUPER+ALT+T",    desc: "Random wallpaper"              },
                            { key: "CTRL+SUPER+SHIFT+D",  desc: "Toggle dark/light"             },
                            { key: "CTRL+SUPER+P",        desc: "Cycle panel family"            },
                            { key: "CTRL+SUPER+R",        desc: "Restart shell"                 },
                            { key: "SUPER+SHIFT+S",       desc: "Screenshot region"             },
                            { key: "SUPER+SHIFT+A",       desc: "Google Lens region"            },
                            { key: "SUPER+SHIFT+X",       desc: "OCR region → clipboard"       },
                            { key: "SUPER+SHIFT+T",       desc: "Translate screen"              },
                            { key: "SUPER+SHIFT+R",       desc: "Record region"                 },
                            { key: "SUPER + L",           desc: "Lock session"                  },
                            { key: "SUPER + Q",           desc: "Close window"                  },
                            { key: "SUPER + F",           desc: "Fullscreen"                    },
                            { key: "SUPER + D",           desc: "Maximize"                      },
                            { key: "SUPER + Return",      desc: "Terminal"                      },
                            { key: "SUPER + W",           desc: "Browser"                       },
                            { key: "SUPER + E",           desc: "File manager"                  },
                        ]
                        delegate: RowLayout {
                            spacing: 8
                            Rectangle {
                                width:  180; height: 22
                                radius: 4
                                color:  Services.Theme.surfaceContainerHigh
                                Text {
                                    anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                                    text:           modelData.key
                                    color:          Services.Theme.primary
                                    font.pixelSize: 11
                                    font.family:    "monospace"
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                }
                            }
                            Text {
                                text:           modelData.desc
                                color:          Services.Theme.onSurface
                                font.pixelSize: 12
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Press Esc or SHIFT+SUPER+ALT+/ to close"
                color: Services.Theme.onSurfaceVariant
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
