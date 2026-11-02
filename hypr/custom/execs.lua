hl.on("hyprland.start", function ()
    -- Cursor (runs after the default setcursor so this one wins)
    hl.exec_cmd("sleep 1 && hyprctl setcursor Bibata-Crosshair 24")

    -- Automount USB drives
    hl.exec_cmd("udiskie --smart-tray")
end)
