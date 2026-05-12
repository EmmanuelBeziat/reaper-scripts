local Config = {
  -- Paths
  script_path = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
	script_dir = script_path:match("^(.+)/[^/]*$") or "."

  -- Window settings
  window = {
    title = "Helix MIDI",
    width = 300,
    height = 300
  },

  -- UI element positions and sizes
  device_list = {
    x = 20,
    y = 20,
    width = 260,
    height = 100
  },

  button = {
    x = 50,
    y = 250,
    width = 200,
    height = 40,
    text = "Create MIDI Block"
  }
}

return Config