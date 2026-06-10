local config_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (config_file:match("^(.+)/[^/]*$") or ".") .. "/"

local Config = {
	script_path = script_dir,

	window = {
		title = "Check Hardware",
		-- REAPER docker index on first open (-1 = first docker, 0 = floating)
		default_dock_id = -1,
	},
}

return Config
