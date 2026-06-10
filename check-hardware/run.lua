local script_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (script_file:match("^(.+)/[^/]*$") or ".") .. "/"
local Config = dofile(script_dir .. "config.lua")

local ReaImGui = dofile(Config.script_path .. "core/reaimgui.lua")
if not ReaImGui.ensure() then
	return
end

local MidiOutput = dofile(Config.script_path .. "core/midi_output.lua")(Config)
local ctx = ReaImGui.create_context(Config.window.title)
local device_font = ReaImGui.call("CreateFont", "sans-serif", Config.ui.device_font_size)
ReaImGui.call("Attach", ctx, device_font)

local MidiOutputsUi = dofile(Config.script_path .. "ui/midi_outputs.lua")(Config, ReaImGui, MidiOutput, device_font)

local function set_button_state(set)
	local _, _, sec, cmd = reaper.get_action_context()
	reaper.SetToggleCommandState(sec, cmd, set or 0)
	reaper.RefreshToolbar2(sec, cmd)
end

local function exit()
	set_button_state(0)
end

local Window = dofile(Config.script_path .. "ui/window.lua")(Config, ReaImGui, ctx, MidiOutputsUi)

local function run()
	local open = Window.draw()

	if open and not ReaImGui.call("IsKeyPressed", ctx, ReaImGui.flag("Key_Escape")) then
		reaper.defer(run)
	else
		exit()
	end
end

local function init()
	set_button_state(1)
	reaper.atexit(exit)
	reaper.defer(run)
end

init()
