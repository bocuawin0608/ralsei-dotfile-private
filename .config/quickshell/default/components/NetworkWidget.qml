import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../services" as Services

Item {
    id: networkWidget
    implicitWidth:  netRow.implicitWidth + 8
    implicitHeight: parent.height

    property bool hovered: netArea.containsMouse

    RowLayout {
        id:             netRow
        anchors.centerIn: parent
        spacing:        4

        Text {
            text: {
                if (!Services.NetworkService.connected) return "⊗"
                if (Services.NetworkService.ethernet)   return "🖧"
                if (Services.NetworkService.wifi)       return "📶"
                return "⊙"
            }
            font.pixelSize: 13
            color: Services.NetworkService.connected
                ? Services.Theme.onSurface
                : Services.Theme.error
        }

        Text {
            visible:        networkWidget.hovered
            text:           Services.NetworkService.ssid || Services.NetworkService.ipAddress || "offline"
            color:          Services.Theme.onSurfaceVariant
            font.pixelSize: 11
            font.family:    Services.Theme.fontFamily

            Behavior on opacity { NumberAnimation { duration: 120 } }
            opacity: networkWidget.hovered ? 1.0 : 0.0
        }
    }

    MouseArea {
        id:           netArea
        anchors.fill: parent
        hoverEnabled: true
    }

    ToolTip {
        visible:  networkWidget.hovered
        text:     "Network: " + (Services.NetworkService.ssid || "wired") +
                  "\nIP: " + (Services.NetworkService.ipAddress || "—")
    }
}
