-- ENV (must be set before the shell starts)
hl.env("QML_IMPORT_PATH", os.getenv("HOME") .. "/.local/lib64/qt6/qml")

-- AUTOSTART
hl.on("hyprland.start", function()
    -- hl.exec_cmd("waybar")
    -- hl.exec_cmd("swaync")

    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("qs --no-duplicate --path " .. os.getenv("HOME") .. "/.config/quickshell/dotarch")
    hl.exec_cmd("sleep 1; ~/.config/quickshell/dotarch/scripts/theme-system.sh restore-wallpaper")
    hl.exec_cmd("hypridle")
--     hl.exec_cmd("easyeffects --gapplication-service")
    
    -- Bluetooth applet for Quickshell notch
    hl.exec_cmd("blueman-applet")

    -- Clipboard history (text and images)
    hl.exec_cmd("~/.local/bin/clipboard-history")

    -- Apply macOS cursor theme
    hl.exec_cmd("hyprctl setcursor macOS 36")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme 'macOS'")
end)