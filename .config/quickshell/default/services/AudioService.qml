pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: audioSvc

    // ──────────────────────────────────────────────────────────────
    //  Public state
    // ──────────────────────────────────────────────────────────────
    property int  volume:     50   // 0-150
    property bool muted:      false
    property int  micVolume:  50
    property bool micMuted:   false

    // ──────────────────────────────────────────────────────────────
    //  Initial query
    // ──────────────────────────────────────────────────────────────
    Process {
        id: volumeQueryProc
        running: false
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Output: "Volume: 0.50 [MUTED]" or "Volume: 0.50"
                var match = text.match(/Volume:\s*([\d.]+)(\s*\[MUTED\])?/)
                if (match) {
                    audioSvc.volume = Math.round(parseFloat(match[1]) * 100)
                    audioSvc.muted  = match[2] !== undefined
                }
            }
        }
    }

    Process {
        id: micVolumeQueryProc
        running: false
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: StdioCollector {
            onStreamFinished: {
                var match = text.match(/Volume:\s*([\d.]+)(\s*\[MUTED\])?/)
                if (match) {
                    audioSvc.micVolume = Math.round(parseFloat(match[1]) * 100)
                    audioSvc.micMuted  = match[2] !== undefined
                }
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  pactl subscribe listener for real-time updates
    // ──────────────────────────────────────────────────────────────
    Process {
        id: pactlListener
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(line) {
                if (line.indexOf("sink") >= 0) {
                    volumeQueryProc.running = false
                    volumeQueryProc.running = true
                }
                if (line.indexOf("source") >= 0) {
                    micVolumeQueryProc.running = false
                    micVolumeQueryProc.running = true
                }
            }
        }
        onRunningChanged: {
            if (!running) Qt.callLater(function() { pactlListener.running = true })
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Setter processes
    // ──────────────────────────────────────────────────────────────
    Process {
        id: setVolumeProc
        running: false
        command: []
    }

    Process {
        id: setMuteProc
        running: false
        command: []
    }

    Process {
        id: setMicMuteProc
        running: false
        command: []
    }

    // ──────────────────────────────────────────────────────────────
    //  Public API
    // ──────────────────────────────────────────────────────────────
    function setVolume(v) {
        var clamped = Math.max(0, Math.min(150, v))
        setVolumeProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (clamped / 100).toFixed(2)]
        setVolumeProc.running = true
    }

    function setMuted(m) {
        setMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", m ? "1" : "0"]
        setMuteProc.running = true
    }

    function setMicMuted(m) {
        setMicMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", m ? "1" : "0"]
        setMicMuteProc.running = true
    }

    Component.onCompleted: {
        volumeQueryProc.running    = true
        micVolumeQueryProc.running = true
    }
}
