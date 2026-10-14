local config_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (config_file:match("^(.+)/[^/]*$") or ".") .. "/"

local Config = {
	script_path = script_dir,
	version = "1.0.0",

	window = {
		title = "Show Check",
		default_dock_id = -1,
	},

	ui = {
		summary_font_size = 28,
		label_font_size = 18,
	},

	-- Substring of the REAPER audio device name (input and output)
	audio_device = "XR18",

	wifi = {
		-- Name prefix, only checked when macOS shows the SSID
		ssid = "SBarricade",
		band = "5GHz",
		-- MAC of the network router (default gateway): identifies the network
		-- even though macOS hides the SSID
		router_mac = "04:f4:1c:fa:64:f3",
	},

	helix_midi_output = "LINE 6 - HELIX",

	lyrics_script = "X-Raym_Convert Lyrics track items notes for dedicated web browser interface.lua",

	web_interfaces = {
		host = "192.168.0.10",
		ports = { 8080, 8082, 8084 },
	},

	artnet_host = "192.168.0.41",

	network = {
		refresh_seconds = 15,
		timeout_seconds = 2,
		-- A run taking longer than this is dropped and started again
		stale_seconds = 30,
	},

	local_refresh_seconds = 1,

	colors = {
		ok = { 0, 204, 0 },
		error = { 204, 0, 0 },
		pending = { 150, 150, 150 },
	},
}

return Config