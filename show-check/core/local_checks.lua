return function(Config, Status)
	local LocalChecks = {}
	local lyrics_command = nil

	local function find_script_command(file_name)
		local file = io.open(reaper.GetResourcePath() .. "/reaper-kb.ini", "r")
		if not file then
			return nil
		end

		local command = nil
		for line in file:lines() do
			if line:sub(1, 4) == "SCR " and line:find(file_name, 1, true) then
				local section, id = line:match("^SCR %d+ (%d+) (%S+)")
				if section == "0" then
					command = reaper.NamedCommandLookup("_" .. id)
					break
				end
			end
		end
		file:close()

		if command and command > 0 then
			return command
		end
		return nil
	end

	function LocalChecks.audio()
		local expected = Config.audio_device
		if reaper.Audio_IsRunning() == 0 then
			return Status.fail("Audio engine stopped (" .. expected .. " unplugged?)")
		end

		local _, input = reaper.GetAudioDeviceInfo("IDENT_IN")
		local _, output = reaper.GetAudioDeviceInfo("IDENT_OUT")
		if input:find(expected, 1, true) and output:find(expected, 1, true) then
			return Status.ok(input)
		end
		return Status.fail("In: " .. input .. " / Out: " .. output)
	end

	function LocalChecks.helix()
		for i = 0, reaper.GetNumMIDIOutputs() - 1 do
			local present, name = reaper.GetMIDIOutputName(i, "")
			if name == Config.helix_midi_output then
				if present then
					return Status.ok("MIDI output " .. (i + 1))
				end
				return Status.fail("MIDI output known but not connected")
			end
		end
		return Status.fail(Config.helix_midi_output .. " not found")
	end

	-- Returns the status and, when the script is stopped, its command ID to start it
	function LocalChecks.lyrics()
		lyrics_command = lyrics_command or find_script_command(Config.lyrics_script)
		if not lyrics_command then
			return Status.fail("Script not found in the action list")
		end

		if reaper.GetToggleCommandStateEx(0, lyrics_command) == 1 then
			return Status.ok("Running")
		end
		return Status.fail("Not running"), lyrics_command
	end

	return LocalChecks
end