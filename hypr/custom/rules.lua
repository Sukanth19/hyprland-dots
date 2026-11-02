-- Scratchpad terminal (Super + `)
hl.window_rule({ match = { class = "^(scratchterm)$" }, float = true })
hl.window_rule({ match = { class = "^(scratchterm)$" }, size = {"(monitor_w*0.7)", "(monitor_h*0.6)"} })
hl.window_rule({ match = { class = "^(scratchterm)$" }, center = true })
hl.window_rule({ match = { class = "^(scratchterm)$" }, workspace = "special:term silent" })

-- Spotify always opens on workspace 5
-- (Spotify sets its class late, so also match its window title)
hl.window_rule({ match = { class = "^([Ss]potify)$" }, workspace = "5" })
hl.window_rule({ match = { title = "^(Spotify( Free| Premium)?)$" }, workspace = "5" })

-- Obsidian: a bit see-through (less than kitty)
hl.window_rule({ match = { class = "^(md\\.obsidian\\.Obsidian|obsidian)$" }, opacity = "0.96" })

-- Obsidian always opens on workspace 4
hl.window_rule({ match = { class = "^(md\\.obsidian\\.Obsidian|obsidian)$" }, workspace = "4" })
