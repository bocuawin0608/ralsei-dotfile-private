import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services" as Services

PanelWindow {
    id: sidebarLeft

    property bool isVisible: false
    property int  activeTab: 0  // 0 = AI, 1 = Media

    visible:   true
    width:     340
    anchors {
        top:    true
        bottom: true
        left:   true
    }
    color:          "transparent"
    exclusionMode:  isVisible ? ExclusionMode.Exclusive : ExclusionMode.Ignore
    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // ──────────────────────────────────────────────────────────────
    //  Public API
    // ──────────────────────────────────────────────────────────────
    function toggle()    { isVisible = !isVisible }
    function detach()    { isVisible = true }
    function showMedia() { isVisible = true; activeTab = 1 }

    // ──────────────────────────────────────────────────────────────
    //  Slide animation
    // ──────────────────────────────────────────────────────────────
    property real slideX: isVisible ? 0 : -width
    Behavior on slideX { NumberAnimation { duration: Services.Theme.animDuration; easing.type: Easing.OutCubic } }

    Rectangle {
        x:            sidebarLeft.slideX
        width:        parent.width
        height:       parent.height
        color:        Services.Theme.surfaceContainer
        radius:       0

        ColumnLayout {
            anchors { fill: parent; margins: 0 }
            spacing: 0

            // ── Tab bar ────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height:           44
                color:            Services.Theme.surfaceContainerHigh

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: ["AI Assistant", "Media"]
                        delegate: ItemDelegate {
                            Layout.fillWidth: true
                            height:           44
                            text:             modelData
                            font.pixelSize:   13
                            contentItem: Text {
                                text:              modelData
                                color:             index === sidebarLeft.activeTab
                                    ? Services.Theme.primary : Services.Theme.onSurfaceVariant
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment:   Text.AlignVCenter
                                font.pixelSize:      13
                                font.weight:         index === sidebarLeft.activeTab ? Font.Medium : Font.Normal
                            }
                            background: Rectangle {
                                color: "transparent"
                                Rectangle {
                                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                                    height:  2
                                    color:   index === sidebarLeft.activeTab
                                        ? Services.Theme.primary : "transparent"
                                    Behavior on color { ColorAnimation { duration: Services.Theme.animDuration } }
                                }
                            }
                            onClicked: sidebarLeft.activeTab = index
                        }
                    }
                }
            }

            // ── AI Tab ─────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                visible: sidebarLeft.activeTab === 0
                Layout.margins: Services.Theme.spacing

                // Provider selector
                RowLayout {
                    spacing: 4
                    Text {
                        text:  "Provider:"
                        color: Services.Theme.onSurfaceVariant
                        font.pixelSize: 12
                    }
                    ComboBox {
                        model:          ["ollama", "gemini"]
                        currentIndex:   Services.AIService.currentProvider === "gemini" ? 1 : 0
                        onActivated:    Services.AIService.currentProvider = model[currentIndex]
                        font.pixelSize: 12
                        background: Rectangle {
                            color:  Services.Theme.surfaceContainerHigh
                            radius: Services.Theme.radius / 2
                        }
                        contentItem: Text {
                            text:  parent.displayText
                            color: Services.Theme.onSurface
                            font.pixelSize: 12
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                    }
                }

                // Model selector (only for ollama)
                ComboBox {
                    Layout.fillWidth: true
                    visible:          Services.AIService.currentProvider === "ollama"
                    model:            Services.AIService.ollamaModels
                    currentIndex:     Services.AIService.ollamaModels.indexOf(Services.AIService.selectedModel)
                    onActivated:      Services.AIService.selectedModel = model[currentIndex]
                    font.pixelSize:   12
                    background: Rectangle {
                        color:  Services.Theme.surfaceContainerHigh
                        radius: Services.Theme.radius / 2
                    }
                    contentItem: Text {
                        text:  parent.displayText
                        color: Services.Theme.onSurface
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 8
                    }
                }

                // Response area
                ScrollView {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    clip: true

                    Rectangle {
                        width:  parent.width
                        height: Math.max(responseText.implicitHeight + 16, parent.height)
                        color:  Services.Theme.surfaceContainerLow
                        radius: Services.Theme.radius / 2

                        Text {
                            id: responseText
                            anchors { fill: parent; margins: 8 }
                            text:       Services.AIService.loading
                                ? "Thinking…"
                                : (Services.AIService.error !== ""
                                    ? "Error: " + Services.AIService.error
                                    : Services.AIService.response || "Ask me anything…")
                            color:      Services.AIService.error !== ""
                                ? Services.Theme.error : Services.Theme.onSurface
                            font.pixelSize: 13
                            font.family:    Services.Theme.fontFamily
                            wrapMode:       Text.WordWrap
                        }
                    }
                }

                // Prompt input
                Rectangle {
                    Layout.fillWidth: true
                    height:           80
                    radius:           Services.Theme.radius / 2
                    color:            Services.Theme.surfaceContainerHigh

                    TextArea {
                        id:           promptInput
                        anchors.fill: parent
                        anchors.margins: 8
                        placeholderText: "Type a prompt… (Ctrl+Enter to send)"
                        color:        Services.Theme.onSurface
                        font.pixelSize: 13
                        wrapMode:     TextArea.Wrap
                        background:   Item {}

                        Keys.onPressed: function(ev) {
                            if (ev.key === Qt.Key_Return && (ev.modifiers & Qt.ControlModifier)) {
                                Services.AIService.query(text)
                                ev.accepted = true
                            }
                        }
                    }
                }

                // Action buttons
                RowLayout {
                    spacing: 4
                    Button {
                        text:    "Send"
                        enabled: !Services.AIService.loading && promptInput.text.length > 0
                        onClicked: Services.AIService.query(promptInput.text)
                        background: Rectangle {
                            color:  parent.enabled ? Services.Theme.primary : Services.Theme.surfaceVariant
                            radius: Services.Theme.radius / 2
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        contentItem: Text {
                            text:  parent.text
                            color: parent.enabled ? Services.Theme.onPrimary : Services.Theme.onSurfaceVariant
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:   Text.AlignVCenter
                        }
                    }
                    Button {
                        text: "Copy"
                        enabled: Services.AIService.response !== ""
                        onClicked: {
                            copyProc.command = ["bash", "-c",
                                "echo " + JSON.stringify(Services.AIService.response) + " | wl-copy"]
                            copyProc.running = true
                        }
                        background: Rectangle {
                            color:  Services.Theme.secondaryContainer
                            radius: Services.Theme.radius / 2
                        }
                        contentItem: Text {
                            text:  parent.text
                            color: Services.Theme.onSecondaryContainer
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:   Text.AlignVCenter
                        }
                        Process { id: copyProc; running: false; command: [] }
                    }
                    Button {
                        text: "Clear"
                        onClicked: { Services.AIService.clearResponse(); promptInput.text = "" }
                        background: Rectangle {
                            color:  Services.Theme.errorContainer
                            radius: Services.Theme.radius / 2
                        }
                        contentItem: Text {
                            text:  parent.text
                            color: Services.Theme.onErrorContainer
                            font.pixelSize: 13
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment:   Text.AlignVCenter
                        }
                    }
                }
            }

            // ── Media Tab ──────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                Layout.margins:    Services.Theme.spacing
                visible: sidebarLeft.activeTab === 1
                spacing: Services.Theme.spacing

                // Album art
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width:   200; height: 200
                    radius:  Services.Theme.radius
                    color:   Services.Theme.surfaceContainerHigh
                    clip:    true

                    Image {
                        anchors.fill: parent
                        source:       Services.MediaService.artUrl || ""
                        fillMode:     Image.PreserveAspectCrop
                        visible:      Services.MediaService.artUrl !== ""
                    }
                    Text {
                        anchors.centerIn: parent
                        visible:          Services.MediaService.artUrl === ""
                        text:             "♪"
                        color:            Services.Theme.onSurfaceVariant
                        font.pixelSize:   64
                    }
                }

                // Track info
                Text {
                    Layout.fillWidth: true
                    text:            Services.MediaService.title || "No media playing"
                    color:           Services.Theme.onSurface
                    font.pixelSize:  15
                    font.weight:     Font.Medium
                    wrapMode:        Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    Layout.fillWidth: true
                    text:            Services.MediaService.artist
                    color:           Services.Theme.onSurfaceVariant
                    font.pixelSize:  12
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    Layout.fillWidth: true
                    text:            Services.MediaService.album
                    color:           Services.Theme.outline
                    font.pixelSize:  11
                    horizontalAlignment: Text.AlignHCenter
                }

                // Progress bar
                Slider {
                    Layout.fillWidth: true
                    from:             0
                    to:               Math.max(1, Services.MediaService.duration)
                    value:            Services.MediaService.position
                    onMoved:          Services.MediaService.seek(value)
                    background: Rectangle {
                        x:      parent.leftPadding
                        y:      parent.topPadding + parent.availableHeight / 2 - height / 2
                        width:  parent.availableWidth
                        height: 4
                        radius: 2
                        color:  Services.Theme.surfaceContainerHigh

                        Rectangle {
                            width:  parent.width * (parent.parent.visualPosition)
                            height: parent.height
                            radius: parent.radius
                            color:  Services.Theme.primary
                        }
                    }
                    handle: Rectangle {
                        x:      parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y:      parent.topPadding + parent.availableHeight / 2 - height / 2
                        width:  12; height: 12
                        radius: 6
                        color:  Services.Theme.primary
                    }
                }

                // Controls
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    ToolButton {
                        icon.name:  "media-skip-backward"
                        icon.color: Services.Theme.onSurface
                        onClicked:  Services.MediaService.previous()
                    }
                    ToolButton {
                        icon.name:  Services.MediaService.playing
                            ? "media-playback-pause" : "media-playback-start"
                        icon.color: Services.Theme.primary
                        icon.width: 28; icon.height: 28
                        onClicked:  Services.MediaService.playPause()
                    }
                    ToolButton {
                        icon.name:  "media-skip-forward"
                        icon.color: Services.Theme.onSurface
                        onClicked:  Services.MediaService.next()
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
