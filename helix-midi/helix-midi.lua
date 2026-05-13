-- helix-in-reaper.lua
-- Basic GUI with a button to create a MIDI block at the cursor position

-- Main script: debug path is .../helix-midi.lua; strip filename before loading config.lua
local script_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (script_file:match("^(.+)/[^/]*$") or ".") .. "/"
local Config = dofile(script_dir .. "config.lua")
package.path = Config.script_path .. "?.lua;" .. package.path

-- Import modules
local Window = dofile(Config.script_path .. "ui/window.lua")(Config)
local MIDI = dofile(Config.script_path .. "core/midi.lua")(Config)
local DeviceList = dofile(Config.script_path .. "ui/device_list.lua")(Config, MIDI)

local function on_setlist_change(value)
end

local function on_preset_change(value)
end

local function on_snapshot_change(value)
end

local function on_expression_pedal1_change(value)
end

local HelixFields = dofile(Config.script_path .. "ui/helix_fields.lua")(Config, {
  on_setlist_change = on_setlist_change,
  on_preset_change = on_preset_change,
  on_snapshot_change = on_snapshot_change,
  on_expression_pedal1_change = on_expression_pedal1_change,
})

local Button = dofile(Config.script_path .. "ui/button.lua")(Config, HelixFields, MIDI)

-- Initialize window
Window.init()

-- Initialize device list
DeviceList.init()

function main()
  -- Draw background
  Window.draw_background()

  -- Draw and handle device list
  DeviceList.draw()
  DeviceList.handle_click()

  HelixFields.draw()
  HelixFields.handle_click()

  -- Draw and handle button
  Button.draw()
  Button.handle_click()

  -- Update window
  Window.update()

  -- Check for window close
  if Window.should_close() then
    Window.close()
    return
  end

  reaper.defer(main)
end

main()