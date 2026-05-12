-- MIDI-related functions
local MIDI = {}

function MIDI.find_helix()
  local helix_id = nil
  local num_inputs = reaper.GetNumMIDIInputs()

  for i = 0, num_inputs - 1 do
    local retval, name = reaper.GetMIDIInputName(i, "")
    if retval and name == "Line 6 Helix" then
      helix_id = i
      break
    end
  end

  return helix_id
end

function MIDI.get_input_devices()
  local devices = {}
  local i = 0

  -- First try the standard way
  while true do
    local retval, name = reaper.GetMIDIInputName(i, "")
    if not retval then break end

    -- Debug: Print device info
    reaper.ShowConsoleMsg(string.format("Found MIDI Input Device %d: %s\n", i, name))

    table.insert(devices, {
      id = i,
      name = name
    })
    i = i + 1
  end

  -- Now try to get all possible MIDI inputs
  local num_inputs = reaper.GetNumMIDIInputs()
  for i = 0, num_inputs - 1 do
    local retval, name = reaper.GetMIDIInputName(i, "")
    if retval then
      -- Check if this device is already in our list
      local found = false
      for _, device in ipairs(devices) do
        if device.name == name then
          found = true
          break
        end
      end

      if not found then
        reaper.ShowConsoleMsg(string.format("Found additional MIDI Input Device %d: %s\n", i, name))
        table.insert(devices, {
          id = i,
          name = name
        })
      end
    end
  end

  -- Debug: Print total count
  reaper.ShowConsoleMsg(string.format("Total MIDI Input Devices found: %d\n", #devices))

  return devices
end

function MIDI.get_output_devices()
  local devices = {}
  local i = 0
  while true do
    local retval, name = reaper.GetMIDIOutputName(i, "")
    if not retval then break end
    table.insert(devices, {
      id = i,
      name = name
    })
    i = i + 1
  end
  return devices
end

function MIDI.create_midi_block()
  local track = reaper.GetSelectedTrack(0, 0)
  if not track then
    reaper.ShowMessageBox("Please select a track first!", "Error", 0)
    return
  end

  local cursor_pos = reaper.GetCursorPosition()
  local proj = 0
  local _, num, denom = reaper.TimeMap_GetTimeSigAtTime(proj, cursor_pos)
  local qn = reaper.TimeMap2_timeToQN(proj, cursor_pos)
  local qn_end = qn + num -- 1 measure
  local end_pos = reaper.TimeMap2_QNToTime(proj, qn_end)

  local item = reaper.CreateNewMIDIItemInProj(track, cursor_pos, end_pos, false)
  if not item then
    reaper.ShowMessageBox("Failed to create MIDI item.", "Error", 0)
  end
end

return MIDI