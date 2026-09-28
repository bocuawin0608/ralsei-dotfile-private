import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "./services" as Services
import "./panels" as Panels

ShellRoot {
    id: root

    // ──────────────────────────────────────────────────────────────
    //  Services (singletons – instantiated once globally)
    // ──────────────────────────────────────────────────────────────
    Services.Theme        { id: themeService }
    Services.HyprlandService { id: hyprlandService }
    Services.AudioService { id: audioService }
    Services.NetworkService { id: networkService }
    Services.MediaService { id: mediaService }
    Services.AIService    { id: aiService }
    Services.SubtitleService { id: subtitleService }

    // ──────────────────────────────────────────────────────────────
    //  IPC Server – handles all incoming qs ipc call <signal>
    // ──────────────────────────────────────────────────────────────
    IpcHandler {
        target: "quickshell"

        function onSearchToggleRelease() { overviewPanel.item.toggle() }
        function onWorkspaceNumber()     { /* pass-through; bar reacts to HyprlandService */ }
        function onOverviewWorkspacesToggle() { overviewPanel.item.toggleWorkspaces() }
        function onOverviewClipboardToggle()  { overviewPanel.item.toggleClipboard() }
        function onOverviewEmojiToggle()      { overviewPanel.item.toggleEmoji() }
        function onSidebarLeftToggle()        { sidebarLeftPanel.item.toggle() }
        function onSidebarLeftToggleDetach()  { sidebarLeftPanel.item.detach() }
        function onSidebarRightToggle()       { sidebarRightPanel.item.toggle() }
        function onCheatsheetToggle()         { welcomeWindow.item.toggle() }
        function onOskToggle()                { /* OSK integration placeholder */ }
        function onMediaControlsToggle()      { sidebarLeftPanel.item.showMedia() }
        function onOverlayToggle()            { subtitleOverlayPanel.item.toggle() }
        function onSessionToggle()            { sessionMenuPanel.item.toggle() }
        function onBarToggle()                { topBars.toggleVisibility(); bottomBars.toggleVisibility() }
        function onWallpaperSelectorToggle()  { wallpaperSelectorPanel.item.toggle() }
        function onWallpaperSelectorRandom()  { wallpaperSelectorPanel.item.pickRandom() }
        function onToggleLightDark()          { themeService.isDark = !themeService.isDark; themeService.reload() }
        function onPanelFamilyCycle()         { /* panel family cycling placeholder */ }
        function onRegionScreenshot()         { screenshotProcess.running = true }
        function onRegionSearch()             { regionSearchProcess.running = true }
        function onRegionOcr()                { regionOcrProcess.running = true }
        function onScreenTranslate()          { screenTranslateProcess.running = true }
        function onRegionRecord()             { regionRecordProcess.running = true }
        function onSubtitleMusicModeToggle()  { subtitleService.toggleMusicMode() }
    }

    IpcHandler {
        target: "security"
        function onAuthFailureLockout() { authFailureOverlayPanel.item.show() }
        function onAuthSuccess()        { authFailureOverlayPanel.item.dismiss() }
    }

    IpcHandler {
        target: "brightness"
        function onIncrement() { brightnessUpProcess.running = true }
        function onDecrement() { brightnessDownProcess.running = true }
    }

    IpcHandler {
        target: "themeReloaded"
        function handle() { themeService.reload() }
    }

    // Health check – TEST_ALIVE
    IpcHandler {
        target: "TEST_ALIVE"
        function handle() { /* exits 0, which is the health check response */ }
    }

    // ──────────────────────────────────────────────────────────────
    //  Global utility processes (never inside per-screen delegates)
    // ──────────────────────────────────────────────────────────────
    Process {
        id: screenshotProcess
        running: false
        command: ["bash", "-c",
            "hyprshot --freeze --clipboard-only --mode region --silent"]
    }
    Process {
        id: regionSearchProcess
        running: false
        command: ["bash", "-c",
            "$HOME/.config/hypr/hyprland/scripts/snip_to_search.sh"]
    }
    Process {
        id: regionOcrProcess
        running: false
        command: ["bash", "-c",
            "grim -g \"$(slurp)\" /tmp/ocr_image.png && tesseract /tmp/ocr_image.png stdout | wl-copy && rm /tmp/ocr_image.png"]
    }
    Process {
        id: screenTranslateProcess
        running: false
        command: ["bash", "-c",
            "$HOME/.config/hypr/hyprland/scripts/screen_translate.sh"]
    }
    Process {
        id: regionRecordProcess
        running: false
        command: ["bash", "-c",
            "$HOME/.config/quickshell/default/scripts/videos/record.sh"]
    }
    Process {
        id: brightnessUpProcess
        running: false
        command: ["brightnessctl", "s", "5%+"]
    }
    Process {
        id: brightnessDownProcess
        running: false
        command: ["brightnessctl", "s", "5%-"]
    }

    // ──────────────────────────────────────────────────────────────
    //  Per-monitor top bars
    // ──────────────────────────────────────────────────────────────
    Variants {
        id: topBars
        model: Quickshell.screens

        property bool allVisible: true
        function toggleVisibility() {
            allVisible = !allVisible
        }

        delegate: Panels.TopBar {
            screen: modelData
            visible: topBars.allVisible
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Per-monitor bottom bars
    // ──────────────────────────────────────────────────────────────
    Variants {
        id: bottomBars
        model: Quickshell.screens

        property bool allVisible: true
        function toggleVisibility() {
            allVisible = !allVisible
        }

        delegate: Panels.BottomBar {
            screen: modelData
            visible: bottomBars.allVisible
        }
    }

    // ──────────────────────────────────────────────────────────────
    //  Global overlays (one instance, not per-monitor)
    // ──────────────────────────────────────────────────────────────
    Loader {
        id: overviewPanel
        active: true
        source: "panels/Overview.qml"
    }
    Loader {
        id: sidebarLeftPanel
        active: true
        source: "panels/SidebarLeft.qml"
    }
    Loader {
        id: sidebarRightPanel
        active: true
        source: "panels/SidebarRight.qml"
    }
    Loader {
        id: wallpaperSelectorPanel
        active: true
        source: "panels/WallpaperSelector.qml"
    }
    Loader {
        id: sessionMenuPanel
        active: true
        source: "panels/SessionMenu.qml"
    }
    Loader {
        id: subtitleOverlayPanel
        active: true
        source: "panels/SubtitleOverlay.qml"
    }
    Loader {
        id: authFailureOverlayPanel
        active: true
        source: "panels/AuthFailureOverlay.qml"
    }
    Loader {
        id: welcomeWindow
        active: true
        source: "welcome.qml"
    }
}
