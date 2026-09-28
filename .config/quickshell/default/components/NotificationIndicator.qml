import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Notifications
import "../services" as Services

Item {
    id: notifIndicator
    implicitWidth:  32
    implicitHeight: parent.height

    NotificationServer { id: notifSrv }

    property int count: notifSrv.trackedNotifications.length

    Text {
        anchors.centerIn: parent
        text:  notifIndicator.count > 0 ? ("🔔 " + notifIndicator.count) : "🔕"
        color: notifIndicator.count > 0
            ? Services.Theme.primary
            : Services.Theme.onSurfaceVariant
        font.pixelSize: 12

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Send IPC to toggle right sidebar
            toggleProc.running = false
            toggleProc.running = true
        }
        Process {
            id: toggleProc
            running: false
            command: ["qs", "-c", "default", "ipc", "call", "quickshell:sidebarRightToggle"]
        }
    }
}
