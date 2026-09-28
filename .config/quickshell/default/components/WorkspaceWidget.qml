import QtQuick
import QtQuick.Layouts
import "../services" as Services

Item {
    id: workspaceWidget
    implicitWidth:  wsRow.implicitWidth + 8
    implicitHeight: parent.height

    RowLayout {
        id:             wsRow
        anchors.centerIn: parent
        spacing:        4

        Repeater {
            model: Services.HyprlandService.workspaces

            delegate: Rectangle {
                property bool isActive: modelData.id === Services.HyprlandService.activeWorkspace
                property bool hasWindows: modelData.windows > 0

                width:  isActive ? 20 : (hasWindows ? 8 : 6)
                height: isActive ? 8  : (hasWindows ? 6 : 5)
                radius: height / 2
                color:  isActive
                    ? Services.Theme.primary
                    : (hasWindows
                        ? Services.Theme.onSurfaceVariant
                        : Services.Theme.outline)

                Behavior on width  { NumberAnimation { duration: Services.Theme.animDuration; easing.type: Easing.OutCubic } }
                Behavior on color  { ColorAnimation  { duration: Services.Theme.animDuration } }

                ToolTip.text:    "Workspace " + modelData.name + " (" + modelData.windows + " windows)"
                ToolTip.visible: wsArea.containsMouse

                MouseArea {
                    id:           wsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked:    Services.HyprlandService.focusWorkspace(modelData.id)
                }
            }
        }
    }
}
