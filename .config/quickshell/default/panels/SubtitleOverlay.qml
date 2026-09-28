import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../services" as Services

PanelWindow {
    id: subtitleOverlay

    property bool isVisible: false

    // Show when subtitle active OR music mode active
    visible: Services.SubtitleService.active || Services.SubtitleService.musicModeActive

    anchors {
        top:   true
        left:  true
        right: true
    }
    height:         80
    color:          "transparent"
    exclusionMode:  ExclusionMode.Ignore
    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function toggle() { Services.SubtitleService.active = !Services.SubtitleService.active }

    // ──────────────────────────────────────────────────────────────
    //  Animated text
    // ──────────────────────────────────────────────────────────────
    property real amplitudeScale: 1.0 + Services.SubtitleService.amplitude * 0.15
    property real amplitudeOpacity: 0.7 + Services.SubtitleService.amplitude * 0.3

    Behavior on amplitudeScale   { NumberAnimation { duration: 80 } }
    Behavior on amplitudeOpacity { NumberAnimation { duration: 80 } }

    Item {
        anchors.fill: parent

        Text {
            id: subtitleText
            anchors.centerIn: parent
            text:        Services.SubtitleService.currentText
            color:       Services.Theme.onBackground
            font.pixelSize:  22
            font.family:     Services.Theme.fontFamily
            font.weight:     Font.SemiBold
            style:       Text.Outline
            styleColor:  Services.Theme.background
            horizontalAlignment: Text.AlignHCenter
            wrapMode:    Text.WordWrap

            scale:   subtitleOverlay.amplitudeScale
            opacity: Services.SubtitleService.musicModeActive
                ? subtitleOverlay.amplitudeOpacity : 1.0

            Behavior on scale   { NumberAnimation { duration: 80 } }
            Behavior on opacity { NumberAnimation { duration: 80 } }
        }
    }

    // Fade in/out
    Behavior on opacity { NumberAnimation { duration: Services.Theme.animDuration } }
    opacity: (Services.SubtitleService.active || Services.SubtitleService.musicModeActive) ? 1.0 : 0.0
}
