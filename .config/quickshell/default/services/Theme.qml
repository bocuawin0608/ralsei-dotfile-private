pragma Singleton
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    // ──────────────────────────────────────────────────────────────
    //  Runtime flags
    // ──────────────────────────────────────────────────────────────
    property bool isDark: true
    property bool reducedMotion: false
    property int  animDuration: reducedMotion ? 0 : 220
    property int  radius:       12
    property int  spacing:       8
    property string fontFamily: "Inter, sans-serif"

    // ──────────────────────────────────────────────────────────────
    //  MD3 color tokens — dark-mode defaults, overwritten by reload()
    // ──────────────────────────────────────────────────────────────
    property color primary:              "#D0BCFF"
    property color onPrimary:            "#381E72"
    property color primaryContainer:     "#4F378B"
    property color onPrimaryContainer:   "#EADDFF"
    property color secondary:            "#CCC2DC"
    property color onSecondary:          "#332D41"
    property color secondaryContainer:   "#4A4458"
    property color onSecondaryContainer: "#E8DEF8"
    property color tertiary:             "#EFB8C8"
    property color onTertiary:           "#492532"
    property color tertiaryContainer:    "#633B48"
    property color onTertiaryContainer:  "#FFD8E4"
    property color error:                "#F2B8B5"
    property color onError:              "#601410"
    property color errorContainer:       "#8C1D18"
    property color onErrorContainer:     "#F9DEDC"
    property color background:           "#1C1B1F"
    property color onBackground:         "#E6E1E5"
    property color surface:              "#1C1B1F"
    property color onSurface:            "#E6E1E5"
    property color surfaceVariant:       "#49454F"
    property color onSurfaceVariant:     "#CAC4D0"
    property color outline:              "#938F99"
    property color outlineVariant:       "#49454F"
    property color shadow:               "#000000"
    property color scrim:                "#000000"
    property color inverseSurface:       "#E6E1E5"
    property color inverseOnSurface:     "#313033"
    property color inversePrimary:       "#6750A4"
    property color surfaceDim:           "#141218"
    property color surfaceBright:        "#3B383E"
    property color surfaceContainerLowest:  "#0F0D13"
    property color surfaceContainerLow:     "#1D1B20"
    property color surfaceContainer:        "#211F26"
    property color surfaceContainerHigh:    "#2B2930"
    property color surfaceContainerHighest: "#36343B"

    // ──────────────────────────────────────────────────────────────
    //  Convenience alpha variants
    // ──────────────────────────────────────────────────────────────
    property color surfaceAlpha85: Qt.rgba(surface.r, surface.g, surface.b, 0.85)
    property color surfaceAlpha70: Qt.rgba(surface.r, surface.g, surface.b, 0.70)
    property color surfaceAlpha60: Qt.rgba(surface.r, surface.g, surface.b, 0.60)

    // ──────────────────────────────────────────────────────────────
    //  Colors.json file watcher (matugen output)
    // ──────────────────────────────────────────────────────────────
    readonly property string colorsPath: StandardPaths.writableLocation(
        StandardPaths.HomeLocation) + "/.cache/matugen/colors.json"

    FileView {
        id: colorFile
        path: theme.colorsPath
        watchChanges: true
        onTextChanged: theme.parseColors(text)
    }

    Component.onCompleted: reload()

    // ──────────────────────────────────────────────────────────────
    //  Public API
    // ──────────────────────────────────────────────────────────────
    function reload() {
        colorFile.reload()
    }

    function parseColors(jsonText) {
        if (!jsonText || jsonText.length === 0) return
        try {
            var obj = JSON.parse(jsonText)
            var scheme = isDark
                ? (obj.colors && obj.colors.dark  ? obj.colors.dark  : obj)
                : (obj.colors && obj.colors.light ? obj.colors.light : obj)
            if (!scheme) return

            var map = {
                "primary":              "primary",
                "on_primary":           "onPrimary",
                "primary_container":    "primaryContainer",
                "on_primary_container": "onPrimaryContainer",
                "secondary":            "secondary",
                "on_secondary":         "onSecondary",
                "secondary_container":  "secondaryContainer",
                "on_secondary_container": "onSecondaryContainer",
                "tertiary":             "tertiary",
                "on_tertiary":          "onTertiary",
                "tertiary_container":   "tertiaryContainer",
                "on_tertiary_container":"onTertiaryContainer",
                "error":                "error",
                "on_error":             "onError",
                "error_container":      "errorContainer",
                "on_error_container":   "onErrorContainer",
                "background":           "background",
                "on_background":        "onBackground",
                "surface":              "surface",
                "on_surface":           "onSurface",
                "surface_variant":      "surfaceVariant",
                "on_surface_variant":   "onSurfaceVariant",
                "outline":              "outline",
                "outline_variant":      "outlineVariant",
                "inverse_surface":      "inverseSurface",
                "inverse_on_surface":   "inverseOnSurface",
                "inverse_primary":      "inversePrimary",
                "surface_dim":          "surfaceDim",
                "surface_bright":       "surfaceBright",
                "surface_container_lowest":  "surfaceContainerLowest",
                "surface_container_low":     "surfaceContainerLow",
                "surface_container":         "surfaceContainer",
                "surface_container_high":    "surfaceContainerHigh",
                "surface_container_highest": "surfaceContainerHighest"
            }
            for (var k in map) {
                if (scheme[k]) {
                    theme[map[k]] = scheme[k]
                }
            }
            // Refresh alpha helpers
            theme.surfaceAlpha85 = Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.85)
            theme.surfaceAlpha70 = Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.70)
            theme.surfaceAlpha60 = Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.60)
        } catch (e) {
            console.warn("Theme: failed to parse colors.json:", e)
        }
    }
}
