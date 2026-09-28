import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../services" as Services

Item {
    id: mediaWidget
    implicitWidth:  mediaRow.implicitWidth + 8
    implicitHeight: parent.height

    visible: Services.MediaService.title !== ""

    RowLayout {
        id:             mediaRow
        anchors.centerIn: parent
        spacing:        6

        Text {
            text:           Services.MediaService.playing ? "▶" : "⏸"
            color:          Services.Theme.primary
            font.pixelSize: 11
        }

        Column {
            spacing: 0
            Text {
                text:           Services.MediaService.title
                color:          Services.Theme.onSurface
                font.pixelSize: 12
                font.family:    Services.Theme.fontFamily
                elide:          Text.ElideRight
                maximumLineCount: 1
                width:          Math.min(implicitWidth, 160)
            }
            Text {
                text:           Services.MediaService.artist
                color:          Services.Theme.onSurfaceVariant
                font.pixelSize: 10
                font.family:    Services.Theme.fontFamily
                elide:          Text.ElideRight
                maximumLineCount: 1
                width:          Math.min(implicitWidth, 160)
                visible:        Services.MediaService.artist !== ""
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked:    Services.MediaService.playPause()
    }
}
