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
    height = 340
  },

  -- UI element positions and sizes
  device_list = {
    x = 20,
    y = 20,
    width = 260,
    height = 100
  },

  -- Setlist / Preset / Snapshot / Expression (rows below device status)
  helix_fields = {
    x = 20,
    y = 72,
    label_width = 136,
    value_width = 48,
    row_height = 28,
    button_width = 26,
    button_gap = 6,
    -- horizontal drag on value box: pixels of movement per ±1 step
    scrub_pixels_per_step = 2,
    -- mouse wheel: treat |delta| >= this as one notch (OS-dependent); smaller = finer steps
    wheel_pixels_per_notch = 80
  },

  button = {
    x = 50,
    y = 290,
    width = 200,
    height = 40,
    text = "Create MIDI Block"
  }
}

return Config