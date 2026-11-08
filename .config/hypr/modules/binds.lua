
-- PROGRAMS
local terminal = "kitty"
local fileManager = "nautilus"

-- PATHS
local dotarchPath = "/home/entity303069/.config/quickshell/dotarch"

-- KEYBINDINGS
local mainMod = "SUPER"

-- Super key: toggle Dotarch app launcher
hl.bind(
    "SUPER + SUPER_L",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call notch toggle launcher"),
    { release = true }
)

-- Lock screen
hl.bind(
    mainMod .. " + L",
    hl.dsp.exec_cmd("/home/entity303069/.local/bin/lock")
)

-- Wallpaper picker
hl.bind(
    mainMod .. " + W",
    hl.dsp.exec_cmd("qs -n -p /home/entity303069/.config/quickshell/hyprquickpaper")
)

-- DOTARCH KEYBINDINGS

-- Super + Space: open/toggle the control center
hl.bind(
    mainMod .. " + SPACE",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call notch toggle control")
)

-- Super + V: Dotarch clipboard history
hl.bind(
    mainMod .. " + V",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call notch toggle clipboard")
)

-- Super + Shift + W: Dotarch wallpaper selector
hl.bind(
    mainMod .. " + SHIFT + W",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call notch toggle wallpaper")
)

-- Super + Shift + T: theme selector
hl.bind(
    mainMod .. " + SHIFT + T",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call notch toggle theme")
)

-- Super + Shift + N: notes
hl.bind(
    mainMod .. " + SHIFT + N",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call notch toggle notes")
)

-- Super + Shift + C: to-do list
hl.bind(
    mainMod .. " + SHIFT + C",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call notch toggle todo")
)

-- Shift + Escape: power panel
hl.bind(
    "SHIFT + ESCAPE",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call notch toggle power")
)

-- CLOSE WINDOW
-- Hide Dotarch Settings; normally close every other application.
hl.bind(mainMod .. " + Q", function()
    local win = hl.get_active_window()

    if win ~= nil
        and win.class == "org.quickshell"
        and win.title == "Shell Settings"
    then
        hl.dispatch(
            hl.dsp.exec_cmd(
                "qs --path " .. dotarchPath .. " ipc call settings close"
            )
        )
    else
        hl.dispatch(hl.dsp.window.close())
    end
end)

-- Open Kitty
hl.bind("ALT + SPACE", hl.dsp.exec_cmd(terminal))

-- Restart Quickshell Dotarch notch: Super + Shift + R
hl.bind(
    mainMod .. " + SHIFT + R",
    hl.dsp.exec_cmd(
        "pkill -x qs; pkill -x quickshell; sleep 0.5; qs --no-duplicate --path " .. dotarchPath
    )
)

-- File manager
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))

-- Print Screen: Dotarch region screenshot
hl.bind(
    "PRINT",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call notch toggle capture")
)

-- Toggle floating
hl.bind(
    mainMod .. " + F",
    hl.dsp.window.float({ action = "toggle" })
)

-- MAXIMIZE / RESTORE (NOT NORMAL FULLSCREEN)
hl.bind(
    mainMod .. " + SHIFT + UP",
    hl.dsp.window.fullscreen({
        mode = "maximized",
        action = "toggle",
    })
)

-- Actual fullscreen (hides normal window UI)
hl.bind(
    mainMod .. " + SHIFT + F",
    hl.dsp.window.fullscreen({
        mode = "fullscreen",
        action = "toggle",
    })
)

-- Exit Hyprland
hl.bind(
    mainMod .. " + M",
    hl.dsp.exec_cmd(
        "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
    )
)

-- Dwindle layout controls
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Move focus between windows
hl.bind(mainMod .. " + LEFT", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + RIGHT", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + UP", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + DOWN", hl.dsp.focus({ direction = "down" }))

-- Workspaces 1–9 and 0
for i = 1, 10 do
    local key = i % 10

    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = i })
    )

    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = i })
    )
end

-- Special workspace
hl.bind(
    mainMod .. " + S",
    hl.dsp.workspace.toggle_special("magic")
)

hl.bind(
    mainMod .. " + SHIFT + S",
    hl.dsp.window.move({ workspace = "special:magic" })
)

-- Scroll through workspaces
hl.bind(
    mainMod .. " + mouse_down",
    hl.dsp.focus({ workspace = "e+1" })
)

hl.bind(
    mainMod .. " + mouse_up",
    hl.dsp.focus({ workspace = "e-1" })
)

-- Move and resize windows
hl.bind(
    mainMod .. " + mouse:272",
    hl.dsp.window.drag(),
    { mouse = true }
)

hl.bind(
    mainMod .. " + mouse:273",
    hl.dsp.window.resize(),
    { mouse = true }
)

-- Volume keys
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true }
)

-- Brightness keys
hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),
    { locked = true, repeating = true }
)

-- Media keys (requires playerctl)
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- WINDOW RULES
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})

-- Super + I: Settings panel
hl.bind(
    mainMod .. " + I",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call settings open")
)

-- Super + Shift + I: toggle Settings
hl.bind(
    mainMod .. " + SHIFT + I",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call settings toggle")
)

-- Shift + Print (Fn + Shift + PrtSc): select an area, save + copy, no shell panel
hl.bind(
    "SHIFT + PRINT",
    hl.dsp.exec_cmd("qs --path " .. dotarchPath .. " ipc call capture screenshot region")
)
