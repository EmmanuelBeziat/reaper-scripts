local config_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (config_file:match("^(.+)/[^/]*$") or ".") .. "/"

local Config = {
	script_path = script_dir,
	version = "1.0.6",

	window = {
		title = "Check Hardware",
		default_dock_id = -1,
	},

	ui = {
		device_font_size = 28,
	},

	midi_outputs = {
		{
			id = 1,
			name = "LINE 6 - HELIX",
		},
	},

	colors = {
		ok = { 0, 204, 0 },
		error = { 204, 0, 0 },
	},

	debug = {
		console_log = false,
	},
}

return Config
