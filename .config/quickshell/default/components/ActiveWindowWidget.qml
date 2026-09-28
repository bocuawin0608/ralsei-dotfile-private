import QtQuick
import QtQuick.Controls
import "../services" as Services

Item {
    id: activeWindowWidget
    implicitWidth:  Math.min(winText.implicitWidth + 8, 300)
    implicitHeight: parent.height

    Text {
        id:             winText
        anchors.centerIn: parent
        width:          parent.width - 8
        text:           Services.HyprlandService.activeWindow || ""
        color:          Services.Theme.onSurfaceVariant
        font.pixelSize: 12
        font.family:    Services.Theme.fontFamily
        elide:          Text.ElideRight
        horizontalAlignment: Text.AlignHCenter

        ToolTip.text:    Services.HyprlandService.activeWindow
        ToolTip.visible: hoverArea.containsMouse && Services.HyprlandService.activeWindow.length > 30
    }

    MouseArea {
        id:           hoverArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
