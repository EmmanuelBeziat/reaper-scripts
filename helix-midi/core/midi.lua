-- MIDI-related functions (factory: pass Config for Helix MIDI base channel)
return function(Config)
	local MIDI = {}

	local function clamp(v, lo, hi)
		if v < lo then
			return lo
		end
		if v > hi then
			return hi
		end
		return v
	end

	--- REAPER MIDI input index for "Line 6 Helix", or nil if not present.
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

	--- MIDI channel nibble 0–15 for [Config.midi.base_channel] (1–16 on the Helix).
	function MIDI.get_helix_midi_channel()
		local base = 1
		if Config.midi and Config.midi.base_channel ~= nil then
			base = math.floor(Config.midi.base_channel)
		end
		base = clamp(base, 1, 16)
		return base - 1
	end

	function MIDI.get_input_devices()
		local devices = {}
		local i = 0

		while true do
			local retval, name = reaper.GetMIDIInputName(i, "")
			if not retval then break end

			reaper.ShowConsoleMsg(string.format("Found MIDI Input Device %d: %s\n", i, name))

			table.insert(devices, {
				id = i,
				name = name
			})
			i = i + 1
		end

		local num_inputs = reaper.GetNumMIDIInputs()
		for j = 0, num_inputs - 1 do
			local retval, name = reaper.GetMIDIInputName(j, "")
			if retval then
				local found = false
				for _, device in ipairs(devices) do
					if device.name == name then
						found = true
						break
					end
				end

				if not found then
					reaper.ShowConsoleMsg(string.format("Found additional MIDI Input Device %d: %s\n", j, name))
					table.insert(devices, {
						id = j,
						name = name
					})
				end
			end
		end

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

	--- Insert CC32 (setlist), PC (preset), CC69 (snapshot), CC1 (expression) at edit cursor on selected track.
	function MIDI.create_helix_item_at_cursor(helix_values)
		local track = reaper.GetSelectedTrack(0, 0)
		if not track then
			reaper.ShowMessageBox("Please select a track first!", "Helix MIDI", 0)
			return
		end

		local proj = 0
		local cursor_pos = reaper.GetCursorPosition()
		local _, num = reaper.TimeMap_GetTimeSigAtTime(proj, cursor_pos)
		local qn = reaper.TimeMap2_timeToQN(proj, cursor_pos)
		local qn_end = qn + num
		local end_pos = reaper.TimeMap2_QNToTime(proj, qn_end)

		local setlist = clamp(math.floor(helix_values.setlist or 0), 0, 7)
		local preset = clamp(math.floor(helix_values.preset or 0), 0, 127)
		local snapshot = clamp(math.floor(helix_values.snapshot or 0), 0, 7)
		local expr1 = clamp(math.floor(helix_values.expr1 or 0), 0, 127)

		reaper.Undo_BeginBlock2(0)

		local item = reaper.CreateNewMIDIItemInProj(track, cursor_pos, end_pos, false)
		if not item then
			reaper.Undo_EndBlock2(0, "Helix MIDI", -1)
			reaper.ShowMessageBox("Failed to create MIDI item.", "Helix MIDI", 0)
			return
		end

		local take = reaper.GetActiveTake(item)
		if not take or not reaper.TakeIsMIDI(take) then
			reaper.Undo_EndBlock2(0, "Helix MIDI", -1)
			reaper.ShowMessageBox("Created item has no MIDI take.", "Helix MIDI", 0)
			return
		end

		local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, cursor_pos)
		local ch = MIDI.get_helix_midi_channel()
		local cc_status = 0xB0 + ch
		local pc_status = 0xC0 + ch

		reaper.MIDI_InsertCC(take, false, false, ppq, cc_status, 0, 32, setlist)
		reaper.MIDI_InsertCC(take, false, false, ppq, pc_status, 0, preset, 0)
		reaper.MIDI_InsertCC(take, false, false, ppq, cc_status, 0, 69, snapshot)
		reaper.MIDI_InsertCC(take, false, false, ppq, cc_status, 0, 1, expr1)

		reaper.MIDI_Sort(take)
		reaper.UpdateArrange()

		reaper.Undo_EndBlock2(0, "Helix MIDI: insert Helix MIDI", -1)
	end

	return MIDI
end
