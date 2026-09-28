import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services" as Services

Item {
    id: statsWidget
    implicitWidth:  statsRow.implicitWidth + 8
    implicitHeight: parent.height

    property string cpuText:  "CPU --%"
    property string ramText:  "RAM --%"

    // ──────────────────────────────────────────────────────────────
    //  CPU polling (3-second interval — unavoidable for CPU%)
    // ──────────────────────────────────────────────────────────────
    Timer {
        interval: 3000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = false
            cpuProc.running = true
        }
    }

    Process {
        id: cpuProc
        running: false
        command: ["bash", "-c",
            "awk '/^cpu / {u=$2+$4; t=$2+$3+$4+$5; " +
            "if (t>0) printf \"%.0f\", 100*(u-pu)/(t-pt); pu=u; pt=t}' /proc/stat /proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text.trim())
                if (!isNaN(v)) statsWidget.cpuText = "CPU " + v + "%"
            }
        }
    }

    Process {
        id: ramProc
        running: false
        command: ["bash", "-c",
            "free | awk '/^Mem/ {printf \"%.0f\", $3/$2*100}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var v = parseInt(text.trim())
                if (!isNaN(v)) statsWidget.ramText = "RAM " + v + "%"
            }
        }
    }

    Timer {
        interval: 5000
        running:  true
        repeat:   true
        triggeredOnStart: true
        onTriggered: {
            ramProc.running = false
            ramProc.running = true
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Display
    // ──────────────────────────────────────────────────────────────
    RowLayout {
        id:              statsRow
        anchors.centerIn: parent
        spacing:         8

        Text {
            text:           statsWidget.cpuText
            color:          Services.Theme.onSurfaceVariant
            font.pixelSize: 11
            font.family:    Services.Theme.fontFamily
        }
        Text {
            text:           statsWidget.ramText
            color:          Services.Theme.onSurfaceVariant
            font.pixelSize: 11
            font.family:    Services.Theme.fontFamily
        }
    }
}
