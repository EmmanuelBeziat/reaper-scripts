return function(Config)
	local MidiOutput = {}

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

	return MidiOutput
end
