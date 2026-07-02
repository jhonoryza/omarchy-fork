-- Browser tags and styling.
o.window("[bB]rave-browser", { tag = "+chromium-based-browser" })
o.window({ tag = "chromium-based-browser" }, { tag = "-default-opacity", tile = true, opacity = "1.0 0.97" })

-- Hide screen sharing notification windows.
o.window({ title = ".*is sharing.*" }, { workspace = "special silent" })
