-- Directory containing this file (trailing slash), for dofile / package.path
local config_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (config_file:match("^(.+)/[^/]*$") or ".") .. "/"

local Config = {
  -- Paths
  script_path = script_dir,

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