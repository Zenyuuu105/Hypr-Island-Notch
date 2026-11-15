-- ENV (must be set before the shell starts)
hl.env("QML_IMPORT_PATH", os.getenv("HOME") .. "/.local/lib64/qt6/qml")

-- Managed startup services
hl.on("hyprland.start", function()
    hl.exec_cmd("python3 ~/.config/quickshell/dotarch/scripts/startup-settings.py launch")
end)
