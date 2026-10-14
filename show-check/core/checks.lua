return function(Config, LocalChecks, Network)
	local Checks = {}
	local local_rows = nil
	local local_checked_at = 0

	local function update_local_rows()
		local now = reaper.time_precise()
		if local_rows and now - local_checked_at < Config.local_refresh_seconds then
			return
		end

		local lyrics, lyrics_command = LocalChecks.lyrics()
		local_rows = {
			audio = { label = "Audio device", status = LocalChecks.audio() },
			helix = { label = "Helix MIDI", status = LocalChecks.helix() },
			lyrics = {
				label = "Lyrics script",
				status = lyrics,
				action = lyrics_command and { label = "Start", command = lyrics_command },
			},
		}
		local_checked_at = now
	end

	-- Rows in checklist order: { label, status = { state, detail }, action? }
	function Checks.rows()
		Network.update()
		update_local_rows()

		local rows = {
			local_rows.audio,
			{ label = "Wi-Fi", status = Network.wifi() },
			local_rows.helix,
			local_rows.lyrics,
		}
		for _, port in ipairs(Config.web_interfaces.ports) do
			table.insert(rows, { label = "Web :" .. port, status = Network.web(port) })
		end
		table.insert(rows, { label = "Art-Net DMX", status = Network.artnet() })
		return rows
	end

	function Checks.refresh()
		local_rows = nil
		Network.refresh()
	end

	function Checks.is_running()
		return Network.is_running()
	end

	return Checks
end