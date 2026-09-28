import QtQuick
import QtQuick.Controls
import "../services" as Services

Item {
    id: clockWidget
    implicitWidth:  clockCol.implicitWidth + 16
    implicitHeight: parent.height

    property bool hovered: clockArea.containsMouse

    // Minute-tick timer (acceptable — no event mechanism for time)
    Timer {
        interval: 60000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            timeText.text = Qt.formatTime(now, "HH:mm")
            dateText.text = Qt.formatDate(now, "ddd, MMM d")
        }
    }

    Column {
        id:       clockCol
        anchors.centerIn: parent
        spacing:  0

        Text {
            id:             timeText
            text:           Qt.formatTime(new Date(), "HH:mm")
            color:          Services.Theme.onSurface
            font.pixelSize: 15
            font.weight:    Font.Medium
            font.family:    Services.Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            id:             dateText
            text:           Qt.formatDate(new Date(), "ddd, MMM d")
            color:          Services.Theme.onSurfaceVariant
            font.pixelSize: 11
            font.family:    Services.Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
            visible:        clockWidget.hovered

            Behavior on opacity { NumberAnimation { duration: 120 } }
            opacity: clockWidget.hovered ? 1.0 : 0.0
        }
    }

    MouseArea {
        id:           clockArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
