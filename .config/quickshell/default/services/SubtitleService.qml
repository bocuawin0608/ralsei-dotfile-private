pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: subtitleSvc

    // ──────────────────────────────────────────────────────────────
    //  Public state
    // ──────────────────────────────────────────────────────────────
    property string currentText:      ""
    property real   amplitude:        0.0
    property bool   musicModeActive:  false
    property bool   active:           false

    // ──────────────────────────────────────────────────────────────
    //  Auto-hide timer for setSubtitle duration
    // ──────────────────────────────────────────────────────────────
    Timer {
        id: hideTimer
        interval: 3000
        repeat:   false
        onTriggered: {
            subtitleSvc.currentText = ""
            subtitleSvc.active      = false
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  CAVA named pipe reader
    // ──────────────────────────────────────────────────────────────
    readonly property string cavaPipePath: "/tmp/cava_output"

    Process {
        id: cavaReader
        running: subtitleSvc.musicModeActive
        command: ["bash", "-c", "while true; do cat /tmp/cava_output; done"]
        onStdoutChanged: {
            var line = stdout.trim().split("\n").pop()
            if (!line) return
            // CAVA outputs semicolon-separated bar values, average them
            var vals  = line.split(";").filter(function(v) { return v !== "" })
            var sum   = 0
            for (var i = 0; i < vals.length; i++) sum += parseFloat(vals[i]) || 0
            subtitleSvc.amplitude = vals.length > 0 ? (sum / vals.length) : 0
        }
        onRunningChanged: {
            if (!running) subtitleSvc.amplitude = 0
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Public API
    // ──────────────────────────────────────────────────────────────
    function setSubtitle(text, duration) {
        currentText = text
        active      = true
        hideTimer.interval = (duration > 0) ? duration : 3000
        hideTimer.restart()
    }

    function clearSubtitle() {
        hideTimer.stop()
        currentText = ""
        active      = false
    }

    function toggleMusicMode() {
        musicModeActive = !musicModeActive
        if (!musicModeActive) amplitude = 0
    }
}
