hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Sidebars: Super+A = left, Super+N = right
hl.unbind("SUPER + N")
hl.unbind("SUPER + A")
hl.bind("SUPER + A", hl.dsp.global("quickshell:sidebarLeftMedia"), { description = "Shell: Left sidebar (Media tab)" })
hl.bind("SUPER + N", hl.dsp.global("quickshell:sidebarRightToggle"), { description = "Shell: Toggle right sidebar" })

-- Scratchpad terminal
hl.bind("SUPER + grave", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/scratchterm.sh"), { description = "App: Scratchpad terminal" })

-- Screenshot region and annotate
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("~/.config/hypr/custom/scripts/snip_annotate.sh"), { description = "Utilities: Screenshot region >> annotate" })

-- Super + . opens the left sidebar on the Emoji tab (instead of the launcher emoji search)
hl.unbind("SUPER + Period")
hl.bind("SUPER + Period", hl.dsp.global("quickshell:sidebarLeftEmoji"), { description = "Shell: Emoji picker (left sidebar)" })
