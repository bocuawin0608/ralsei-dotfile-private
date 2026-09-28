pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: mediaSvc

    // ──────────────────────────────────────────────────────────────
    //  Public state
    // ──────────────────────────────────────────────────────────────
    property string title:    ""
    property string artist:   ""
    property string album:    ""
    property string player:   ""
    property bool   playing:  false
    property real   position: 0.0
    property real   duration: 0.0
    property string artUrl:   ""

    // ──────────────────────────────────────────────────────────────
    //  playerctl --follow metadata listener
    // ──────────────────────────────────────────────────────────────
    Process {
        id: playerctlFollow
        running: true
        command: [
            "playerctl", "--follow", "metadata",
            "--format",
            "{{playerName}}\t{{status}}\t{{title}}\t{{artist}}\t{{album}}\t{{mpris:artUrl}}\t{{duration(mpris:length)}}\t{{duration(position)}}"
        ]

        onStdoutChanged: {
            var lines = stdout.split("\n")
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim()
                if (!line) continue
                var parts = line.split("\t")
                if (parts.length < 8) continue
                mediaSvc.player   = parts[0]
                mediaSvc.playing  = parts[1] === "Playing"
                mediaSvc.title    = parts[2]
                mediaSvc.artist   = parts[3]
                mediaSvc.album    = parts[4]
                mediaSvc.artUrl   = parts[5]
                // duration fields are in human format "mm:ss", convert to seconds
                mediaSvc.duration = _timeToSeconds(parts[6])
                mediaSvc.position = _timeToSeconds(parts[7])
            }
        }

        onRunningChanged: {
            if (!running) {
                mediaSvc.title   = ""
                mediaSvc.artist  = ""
                mediaSvc.playing = false
                Qt.callLater(function() { playerctlFollow.running = true })
            }
        }
    }

    function _timeToSeconds(s) {
        if (!s) return 0
        var parts = s.split(":")
        if (parts.length === 2) return parseInt(parts[0]) * 60 + parseFloat(parts[1])
        if (parts.length === 3) return parseInt(parts[0]) * 3600 + parseInt(parts[1]) * 60 + parseFloat(parts[2])
        return 0
    }

    // ──────────────────────────────────────────────────────────────
    //  Control processes
    // ──────────────────────────────────────────────────────────────
    Process { id: playPauseProc; running: false; command: ["playerctl", "play-pause"] }
    Process { id: nextProc;      running: false; command: ["playerctl", "next"]        }
    Process { id: prevProc;      running: false; command: ["playerctl", "previous"]    }
    Process { id: seekProc;      running: false; command: []                            }

    // ──────────────────────────────────────────────────────────────
    //  Public API
    // ──────────────────────────────────────────────────────────────
    function playPause() { playPauseProc.running = true }
    function next()      { nextProc.running      = true }
    function previous()  { prevProc.running      = true }
    function seek(pos) {
        seekProc.command = ["playerctl", "position", String(pos)]
        seekProc.running = true
    }
}
