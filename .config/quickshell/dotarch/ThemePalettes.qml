pragma Singleton
import QtQuick

// All dotarch theme palettes.
// Token set (keep identical across every theme):
//   name, isDark, background, surface, primary, onPrimary,
//   text, subtext, success, danger, glow, glowStrength
//
// glowStrength scales glow opacity/radius on the notch indicators
// (workspace, wifi, battery). Light themes use a lower value.

QtObject {
    readonly property var palettes: ({

        mocha: {
            name: "Catppuccin Mocha", isDark: true,
            background: "#1e1e2e", surface: "#313244",
            primary: "#cba6f7", onPrimary: "#1e1e2e",
            text: "#cdd6f4", subtext: "#a6adc8",
            success: "#a6e3a1", danger: "#f38ba8",
            glow: "#cba6f7", glowStrength: 1.0
        },

        tokyonight: {
            name: "Tokyo Night", isDark: true,
            background: "#1a1b26", surface: "#24283b",
            primary: "#7aa2f7", onPrimary: "#1a1b26",
            text: "#c0caf5", subtext: "#a9b1d6",
            success: "#9ece6a", danger: "#f7768e",
            glow: "#7aa2f7", glowStrength: 1.0
        },

        rosepine: {
            name: "Rosé Pine", isDark: true,
            background: "#191724", surface: "#1f1d2e",
            primary: "#ebbcba", onPrimary: "#191724",
            text: "#e0def4", subtext: "#908caa",
            success: "#9ccfd8", danger: "#eb6f92",
            glow: "#ebbcba", glowStrength: 1.0
        },

        gruvbox: {
            name: "Gruvbox Dark", isDark: true,
            background: "#282828", surface: "#3c3836",
            primary: "#fe8019", onPrimary: "#282828",
            text: "#ebdbb2", subtext: "#a89984",
            success: "#b8bb26", danger: "#fb4934",
            glow: "#fe8019", glowStrength: 1.0
        },

        nord: {
            name: "Nord", isDark: true,
            background: "#2e3440", surface: "#3b4252",
            primary: "#88c0d0", onPrimary: "#2e3440",
            text: "#eceff4", subtext: "#9aa3b5",
            success: "#a3be8c", danger: "#bf616a",
            glow: "#88c0d0", glowStrength: 0.9
        },

        dracula: {
            name: "Dracula", isDark: true,
            background: "#282a36", surface: "#44475a",
            primary: "#bd93f9", onPrimary: "#282a36",
            text: "#f8f8f2", subtext: "#a9b0d0",
            success: "#50fa7b", danger: "#ff5555",
            glow: "#bd93f9", glowStrength: 1.1
        },

        everforest: {
            name: "Everforest", isDark: true,
            background: "#2d353b", surface: "#343f44",
            primary: "#a7c080", onPrimary: "#2d353b",
            text: "#d3c6aa", subtext: "#859289",
            success: "#a7c080", danger: "#e67e80",
            glow: "#a7c080", glowStrength: 0.9
        },

        kanagawa: {
            name: "Kanagawa", isDark: true,
            background: "#1f1f28", surface: "#2a2a37",
            primary: "#7e9cd8", onPrimary: "#1f1f28",
            text: "#dcd7ba", subtext: "#9c9a86",
            success: "#98bb6c", danger: "#e46876",
            glow: "#7e9cd8", glowStrength: 1.0
        },

        latte: {
            name: "Catppuccin Latte", isDark: false,
            background: "#eff1f5", surface: "#ccd0da",
            primary: "#8839ef", onPrimary: "#eff1f5",
            text: "#4c4f69", subtext: "#6c6f85",
            success: "#40a02b", danger: "#d20f39",
            glow: "#8839ef", glowStrength: 0.4
        },

        amoled: {
            name: "AMOLED", isDark: true,
            background: "#000000", surface: "#111111",
            primary: "#00e5ff", onPrimary: "#000000",
            text: "#f2f2f2", subtext: "#8a8a8a",
            success: "#30d158", danger: "#ff453a",
            glow: "#00e5ff", glowStrength: 1.2
        }
    })

    // Display order for ThemePanel
    readonly property var order: [
        "mocha", "tokyonight", "rosepine", "gruvbox", "nord",
        "dracula", "everforest", "kanagawa", "latte", "amoled"
    ]
}
