import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../services" as Services

FloatingWindow {
    id: wallpaperSelector

    property bool isVisible: false
    visible:  isVisible
    width:    800
    height:   600
    title:    "Wallpaper Selector"

    // Center on screen
    x: (screen.width  - width)  / 2
    y: (screen.height - height) / 2

    WlrLayershell.layer:         WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ──────────────────────────────────────────────────────────────
    //  State
    // ──────────────────────────────────────────────────────────────
    property string searchText:      ""
    property int    selectedIndex:   0
    property var    allWallpapers:   []
    property var    filteredWalls: {
        if (!searchText) return allWallpapers
        var q = searchText.toLowerCase()
        return allWallpapers.filter(function(w) { return w.toLowerCase().indexOf(q) >= 0 })
    }
    property string currentWallpaper: ""

    // ──────────────────────────────────────────────────────────────
    //  Public API
    // ──────────────────────────────────────────────────────────────
    function toggle() {
        isVisible = !isVisible
        if (isVisible) loadWallpapers()
    }

    function pickRandom() {
        if (allWallpapers.length === 0) { loadWallpapers(); return }
        var idx = Math.floor(Math.random() * allWallpapers.length)
        applyWallpaper(allWallpapers[idx])
    }

    function loadWallpapers() {
        lsProc.running = false
        lsProc.running = true
    }

    function applyWallpaper(path) {
        currentWallpaper = path
        applyProc.command = ["bash", "-c",
            "$HOME/.config/quickshell/default/scripts/colors/switchwall.sh " + JSON.stringify(path)]
        applyProc.running = true
    }

    // ──────────────────────────────────────────────────────────────
    //  Processes
    // ──────────────────────────────────────────────────────────────
    Process {
        id: lsProc
        running: false
        command: ["bash", "-c",
            "find $HOME/Pictures/Wallpapers -maxdepth 2 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) " +
            "| sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperSelector.allWallpapers = text.trim().split("\n").filter(function(l) { return l !== "" })
                wallpaperSelector.selectedIndex  = 0
            }
        }
    }

    Process { id: applyProc; running: false; command: [] }

    // ──────────────────────────────────────────────────────────────
    //  UI
    // ──────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color:        Services.Theme.surfaceContainer
        radius:       Services.Theme.radius

        ColumnLayout {
            anchors { fill: parent; margins: Services.Theme.spacing * 2 }
            spacing: Services.Theme.spacing

            // Title bar
            RowLayout {
                Text { text: "Wallpaper Selector"; color: Services.Theme.onSurface; font.pixelSize: 18; font.weight: Font.Medium }
                Item { Layout.fillWidth: true }
                ToolButton {
                    text: "✕"
                    onClicked: wallpaperSelector.isVisible = false
                    contentItem: Text { text: parent.text; color: Services.Theme.onSurface; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { color: parent.hovered ? Services.Theme.errorContainer : "transparent"; radius: 4 }
                }
            }

            // Search bar
            Rectangle {
                Layout.fillWidth: true; height: 40
                radius: Services.Theme.radius / 2
                color:  Services.Theme.surfaceContainerHigh
                RowLayout {
                    anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                    Text { text: "⌕"; color: Services.Theme.onSurfaceVariant }
                    TextInput {
                        Layout.fillWidth: true
                        color: Services.Theme.onSurface
                        font.pixelSize: 14
                        onTextChanged: { wallpaperSelector.searchText = text; wallpaperSelector.selectedIndex = 0 }
                        Keys.onEscapePressed: wallpaperSelector.isVisible = false
                        Keys.onReturnPressed: {
                            if (wallpaperSelector.filteredWalls.length > wallpaperSelector.selectedIndex)
                                wallpaperSelector.applyWallpaper(wallpaperSelector.filteredWalls[wallpaperSelector.selectedIndex])
                        }
                        Keys.onLeftPressed:  wallpaperSelector.selectedIndex = Math.max(0, wallpaperSelector.selectedIndex - 1)
                        Keys.onRightPressed: wallpaperSelector.selectedIndex = Math.min(wallpaperSelector.filteredWalls.length - 1, wallpaperSelector.selectedIndex + 1)
                        Keys.onUpPressed:    wallpaperSelector.selectedIndex = Math.max(0, wallpaperSelector.selectedIndex - cols)
                        Keys.onDownPressed:  wallpaperSelector.selectedIndex = Math.min(wallpaperSelector.filteredWalls.length - 1, wallpaperSelector.selectedIndex + cols)
                        property int cols: Math.floor((wallpaperSelector.width - 48) / 156)
                    }
                }
            }

            // Thumbnail grid
            ScrollView {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                clip: true

                GridView {
                    id:          wallGrid
                    width:       parent.width
                    cellWidth:   156
                    cellHeight:  110
                    model:       wallpaperSelector.filteredWalls

                    delegate: Rectangle {
                        width:  150; height: 104
                        radius: Services.Theme.radius / 2
                        color:  wallpaperSelector.selectedIndex === index
                            ? Services.Theme.primaryContainer
                            : Services.Theme.surfaceContainerHigh
                        clip: true

                        Image {
                            anchors.fill:  parent
                            source:        "file://" + modelData
                            fillMode:      Image.PreserveAspectCrop
                            asynchronous:  true
                        }

                        // Current wallpaper indicator
                        Rectangle {
                            visible: modelData === wallpaperSelector.currentWallpaper
                            anchors { top: parent.top; right: parent.right; margins: 4 }
                            width: 16; height: 16; radius: 8
                            color: Services.Theme.primary
                            Text { anchors.centerIn: parent; text: "✓"; color: Services.Theme.onPrimary; font.pixelSize: 10 }
                        }

                        Text {
                            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; margins: 4 }
                            text:   modelData.split("/").pop()
                            color:  "white"
                            font.pixelSize: 9
                            elide:  Text.ElideLeft
                            Rectangle {
                                anchors.fill: parent; anchors.margins: -2
                                color:  Qt.rgba(0,0,0,0.5); radius: 2; z: -1
                            }
                        }

                        MouseArea {
                            anchors.fill:    parent
                            onClicked:       wallpaperSelector.selectedIndex = index
                            onDoubleClicked: wallpaperSelector.applyWallpaper(modelData)
                        }
                    }
                }
            }

            // Bottom buttons
            RowLayout {
                spacing: 8
                Button {
                    text: "Apply"
                    enabled: wallpaperSelector.filteredWalls.length > wallpaperSelector.selectedIndex
                    onClicked: wallpaperSelector.applyWallpaper(wallpaperSelector.filteredWalls[wallpaperSelector.selectedIndex])
                    background: Rectangle { color: parent.enabled ? Services.Theme.primary : Services.Theme.surfaceVariant; radius: Services.Theme.radius / 2 }
                    contentItem: Text { text: parent.text; color: parent.enabled ? Services.Theme.onPrimary : Services.Theme.onSurfaceVariant; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Button {
                    text: "Random"
                    onClicked: wallpaperSelector.pickRandom()
                    background: Rectangle { color: Services.Theme.secondaryContainer; radius: Services.Theme.radius / 2 }
                    contentItem: Text { text: parent.text; color: Services.Theme.onSecondaryContainer; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Close"
                    onClicked: wallpaperSelector.isVisible = false
                    background: Rectangle { color: Services.Theme.surfaceContainerHigh; radius: Services.Theme.radius / 2 }
                    contentItem: Text { text: parent.text; color: Services.Theme.onSurface; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }

    Keys.onEscapePressed: isVisible = false
    Component.onCompleted: loadWallpapers()
}
