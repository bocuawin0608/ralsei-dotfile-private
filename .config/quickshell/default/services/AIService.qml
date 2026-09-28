pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: aiSvc

    // ──────────────────────────────────────────────────────────────
    //  Public state
    // ──────────────────────────────────────────────────────────────
    property bool   ollamaAvailable:    false
    property bool   geminiConfigured:   false
    property string currentProvider:    "ollama"  // or "gemini"
    property var    ollamaModels:       []
    property string selectedModel:      ""
    property string response:           ""
    property bool   loading:            false
    property string error:              ""

    // ──────────────────────────────────────────────────────────────
    //  Startup checks
    // ──────────────────────────────────────────────────────────────
    Process {
        id: ollamaCheckProc
        running: false
        command: ["curl", "-s", "--max-time", "2",
                  "http://localhost:11434/api/tags"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text)
                    if (data.models) {
                        aiSvc.ollamaAvailable = true
                        aiSvc.ollamaModels    = data.models.map(function(m) { return m.name })
                        if (!aiSvc.selectedModel && aiSvc.ollamaModels.length > 0)
                            aiSvc.selectedModel = aiSvc.ollamaModels[0]
                    }
                } catch(e) {
                    aiSvc.ollamaAvailable = false
                }
            }
        }
        onExitCodeChanged: {
            if (exitCode !== 0) aiSvc.ollamaAvailable = false
        }
    }

    Process {
        id: geminiCheckProc
        running: false
        command: ["bash", "-c", "test -n \"$GEMINI_API_KEY\" && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: {
                aiSvc.geminiConfigured = text.trim() === "yes"
                if (aiSvc.geminiConfigured && !aiSvc.ollamaAvailable)
                    aiSvc.currentProvider = "gemini"
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Query process
    // ──────────────────────────────────────────────────────────────
    Process {
        id: queryProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                aiSvc.loading = false
                try {
                    if (aiSvc.currentProvider === "ollama") {
                        var lines = text.trim().split("\n")
                        var full = ""
                        for (var i = 0; i < lines.length; i++) {
                            var obj = JSON.parse(lines[i])
                            if (obj.response) full += obj.response
                        }
                        aiSvc.response = full
                    } else {
                        var data = JSON.parse(text)
                        aiSvc.response = data.candidates
                            && data.candidates[0]
                            && data.candidates[0].content
                            && data.candidates[0].content.parts
                            && data.candidates[0].content.parts[0].text
                            ? data.candidates[0].content.parts[0].text
                            : text
                    }
                } catch(e) {
                    aiSvc.response = text
                }
                aiSvc.error = ""
            }
        }
        onExitCodeChanged: {
            if (exitCode !== 0) {
                aiSvc.loading = false
                aiSvc.error   = "Query failed (exit " + exitCode + ")"
            }
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Public API
    // ──────────────────────────────────────────────────────────────
    function query(prompt, provider) {
        var prov = provider || currentProvider
        loading  = true
        error    = ""
        response = ""

        if (prov === "ollama") {
            var body = JSON.stringify({
                model:  selectedModel || "llama3",
                prompt: prompt,
                stream: true
            })
            queryProc.command = [
                "curl", "-s", "-X", "POST",
                "http://localhost:11434/api/generate",
                "-H", "Content-Type: application/json",
                "-d", body
            ]
        } else {
            var apiKey = Qt.getenv("GEMINI_API_KEY") || ""
            var gbody  = JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }]
            })
            queryProc.command = [
                "curl", "-s", "-X", "POST",
                "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=" + apiKey,
                "-H", "Content-Type: application/json",
                "-d", gbody
            ]
        }
        queryProc.running = true
    }

    function clearResponse() {
        response = ""
        error    = ""
    }

    Component.onCompleted: {
        ollamaCheckProc.running = true
        geminiCheckProc.running = true
    }
}
