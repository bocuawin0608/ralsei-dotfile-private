import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../services" as Services

Item {
    id: volumeWidget
    implicitWidth:  volRow.implicitWidth + 8
    implicitHeight: parent.height

    RowLayout {
        id:             volRow
        anchors.centerIn: parent
        spacing:        4

        // Speaker icon (text-based)
        Text {
            text: {
                if (Services.AudioService.muted || Services.AudioService.volume === 0) return "🔇"
                if (Services.AudioService.volume < 33)  return "🔈"
                if (Services.AudioService.volume < 66)  return "🔉"
                return "🔊"
            }
            font.pixelSize: 13
            color:          Services.Theme.onSurface

            MouseArea {
                anchors.fill: parent
                onClicked:    Services.AudioService.setMuted(!Services.AudioService.muted)
                // Scroll to change volume
                onWheel: function(wheel) {
                    var delta = wheel.angleDelta.y > 0 ? 2 : -2
                    Services.AudioService.setVolume(Services.AudioService.volume + delta)
                }
            }
        }

        Text {
            text:           Services.AudioService.muted ? "mute" : (Services.AudioService.volume + "%")
            color:          Services.AudioService.muted ? Services.Theme.onSurfaceVariant : Services.Theme.onSurface
            font.pixelSize: 12
            font.family:    Services.Theme.fontFamily
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
            var delta = wheel.angleDelta.y > 0 ? 2 : -2
            Services.AudioService.setVolume(Services.AudioService.volume + delta)
        }
    }
}
