return function(Config)
	local MidiOutput = {
		last_log_key = nil,
	}

	function MidiOutput.log(message)
		if not Config.debug or not Config.debug.console_log then
			return
		end
		reaper.ShowConsoleMsg("[Check Hardware] " .. message .. "\n")
	end

	function MidiOutput.list_all_outputs()
		local outputs = {}
		local num_outputs = reaper.GetNumMIDIOutputs()

		for i = 0, num_outputs - 1 do
			local retval, name = reaper.GetMIDIOutputName(i, "")
			table.insert(outputs, {
				id = i,
				name = retval and name or "",
				available = retval,
			})
		end

		return outputs
	end

	function MidiOutput.check_device(device)
		local expected_id = device.id
		local expected_name = device.name
		local num_outputs = reaper.GetNumMIDIOutputs()

		if expected_id == nil or expected_id < 0 or expected_id >= num_outputs then
			return {
				ok = false,
				id = expected_id,
				name = expected_name,
				status = "not_found",
				num_outputs = num_outputs,
			}
		end

		local retval, name = reaper.GetMIDIOutputName(expected_id, "")
		if not retval then
			return {
				ok = false,
				id = expected_id,
				name = expected_name,
				status = "not_found",
				num_outputs = num_outputs,
			}
		end

		if name == expected_name then
			return {
				ok = true,
				id = expected_id,
				name = name,
				status = "connected",
				num_outputs = num_outputs,
			}
		end

		return {
			ok = false,
			id = expected_id,
			name = name,
			expected_name = expected_name,
			status = "wrong_name",
			num_outputs = num_outputs,
		}
	end

	function MidiOutput.check_all()
		local results = {}

		for _, device in ipairs(Config.midi_outputs) do
			table.insert(results, {
				device = device,
				result = MidiOutput.check_device(device),
			})
		end

		return results
	end

	function MidiOutput.log_snapshot(checks, outputs)
		local parts = {}

		for _, output in ipairs(outputs) do
			table.insert(parts, string.format("[%d] %q (available=%s)", output.id, output.name, tostring(output.available)))
		end

		local outputs_line = #parts > 0 and table.concat(parts, ", ") or "(none)"
		local key = outputs_line

		for _, entry in ipairs(checks) do
			local result = entry.result
			key = key .. "|" .. tostring(result.status) .. "|" .. tostring(result.name)
		end

		if key == MidiOutput.last_log_key then
			return
		end

		MidiOutput.last_log_key = key
		MidiOutput.log(string.format("MIDI outputs (%d): %s", #outputs, outputs_line))

		for _, entry in ipairs(checks) do
			local device = entry.device
			local result = entry.result
			MidiOutput.log(string.format(
				"Check id=%s name=%q -> status=%s actual=%q num_outputs=%s",
				tostring(device.id),
				device.name,
				result.status,
				result.name or "",
				tostring(result.num_outputs)
			))
		end
	end

	return MidiOutput
end
