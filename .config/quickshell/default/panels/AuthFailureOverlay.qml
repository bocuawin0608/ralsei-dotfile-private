import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../services" as Services

PanelWindow {
    id: authFailureOverlay

    property bool isShown: false

    // Only show if env vars are set
    readonly property bool featureEnabled: {
        var a = Qt.getenv("AUTH_FAILURE_REACTION_ENABLED")
        var b = Qt.getenv("ANTIFLASBANG_ENABLED")
        return (a !== "" && a !== "0" && a !== "false") ||
               (b !== "" && b !== "0" && b !== "false")
    }

    visible: isShown && featureEnabled

    anchors { top: true; bottom: true; left: true; right: true }
    color:          "transparent"
    exclusionMode:  ExclusionMode.Ignore
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ──────────────────────────────────────────────────────────────
    //  Public API
    // ──────────────────────────────────────────────────────────────
    function show() {
        if (!featureEnabled) return
        isShown = true
        autoDismissTimer.restart()
    }

    function dismiss() {
        isShown = false
        autoDismissTimer.stop()
    }

    Timer {
        id: autoDismissTimer
        interval: 300000   // 300 seconds
        repeat:   false
        onTriggered: authFailureOverlay.dismiss()
    }

    // ──────────────────────────────────────────────────────────────
    //  Lockout image
    // ──────────────────────────────────────────────────────────────
    readonly property string lockoutDir: StandardPaths.writableLocation(
        StandardPaths.HomeLocation) + "/.config/hypr/assets/lockout/"

    Process {
        id: findImageProc
        running: authFailureOverlay.isShown
        command: ["bash", "-c",
            "find " + authFailureOverlay.lockoutDir +
            " -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.gif' \\) | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim()
                if (p) overlayImage.source = "file://" + p
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color:        "#E8000000"

        Image {
            id:           overlayImage
            anchors.centerIn: parent
            fillMode:     Image.PreserveAspectFit
            width:        Math.min(parent.width * 0.6, 800)
        }
    }

    Behavior on opacity { NumberAnimation { duration: Services.Theme.animDuration } }
    opacity: isShown ? 1.0 : 0.0
}
