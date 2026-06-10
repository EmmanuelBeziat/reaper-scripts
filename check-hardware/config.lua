local config_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (config_file:match("^(.+)/[^/]*$") or ".") .. "/"

local Config = {
	script_path = script_dir,

	window = {
		title = "Check Hardware",
		default_dock_id = -1,
	},

	midi_outputs = {
		{
			id = 1,
			name = "LINE 6 - HELIX",
			label = "MIDI Output",
		},
	},

	colors = {
		ok = { 0, 204, 0 },
		error = { 204, 0, 0 },
	},
}

return Config
