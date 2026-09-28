pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: networkSvc

    // ──────────────────────────────────────────────────────────────
    //  Public state
    // ──────────────────────────────────────────────────────────────
    property string ssid:      ""
    property bool   connected: false
    property bool   wifi:      false
    property bool   ethernet:  false
    property string ipAddress: ""

    // ──────────────────────────────────────────────────────────────
    //  Initial query
    // ──────────────────────────────────────────────────────────────
    Process {
        id: nmcliQueryProc
        running: false
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,DEVICE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n")
                var hasWifi = false, hasEth = false, hasConn = false, foundSsid = ""
                for (var i = 0; i < lines.length; i++) {
                    var parts = lines[i].split(":")
                    if (parts.length < 4) continue
                    var type   = parts[0]
                    var state  = parts[1]
                    var conn   = parts[2]
                    if (state === "connected") {
                        hasConn = true
                        if (type === "wifi") {
                            hasWifi = true
                            foundSsid = conn
                        }
                        if (type === "ethernet") hasEth = true
                    }
                }
                networkSvc.connected = hasConn
                networkSvc.wifi      = hasWifi
                networkSvc.ethernet  = hasEth
                networkSvc.ssid      = foundSsid
            }
        }
    }

    Process {
        id: ipQueryProc
        running: false
        command: ["bash", "-c",
            "ip -4 addr show | grep -oP '(?<=inet )\\d+\\.\\d+\\.\\d+\\.\\d+' | grep -v 127 | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                networkSvc.ipAddress = text.trim()
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  nmcli monitor for live change events
    // ──────────────────────────────────────────────────────────────
    Process {
        id: nmcliMonitor
        running: true
        command: ["nmcli", "monitor"]
        onStdoutChanged: {
            // Re-query on any network change event
            nmcliQueryProc.running = false
            nmcliQueryProc.running = true
            ipQueryProc.running    = false
            ipQueryProc.running    = true
        }
        onRunningChanged: {
            if (!running) Qt.callLater(function() { nmcliMonitor.running = true })
        }
    }

    Component.onCompleted: {
        nmcliQueryProc.running = true
        ipQueryProc.running    = true
    }
}
