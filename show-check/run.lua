local script_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (script_file:match("^(.+)/[^/]*$") or ".") .. "/"
local Config = dofile(script_dir .. "config.lua")

local ReaImGui = dofile(Config.script_path .. "core/reaimgui.lua")
if not ReaImGui.ensure(Config.window.title) then
	return
end

local Status = dofile(Config.script_path .. "core/status.lua")
local LocalChecks = dofile(Config.script_path .. "core/local_checks.lua")(Config, Status)
local Network = dofile(Config.script_path .. "core/network.lua")(Config, Status)
local Checks = dofile(Config.script_path .. "core/checks.lua")(Config, LocalChecks, Network)

local ctx = ReaImGui.create_context(Config.window.title)
local fonts = {
	summary = ReaImGui.call("CreateFont", "sans-serif", Config.ui.summary_font_size),
	label = ReaImGui.call("CreateFont", "sans-serif", Config.ui.label_font_size),
}
ReaImGui.call("Attach", ctx, fonts.summary)
ReaImGui.call("Attach", ctx, fonts.label)

local Window = dofile(Config.script_path .. "ui/window.lua")(Config, ReaImGui, ctx, fonts, Checks)

local function set_button_state(set)
	local _, _, sec, cmd = reaper.get_action_context()
	reaper.SetToggleCommandState(sec, cmd, set or 0)
	reaper.RefreshToolbar2(sec, cmd)
end

local function exit()
	set_button_state(0)
	Network.cleanup()
end

local function run()
	local open = Window.draw()

	if open and not ReaImGui.call("IsKeyPressed", ctx, ReaImGui.flag("Key_Escape")) then
		reaper.defer(run)
	end
end

local function init()
	set_button_state(1)
	reaper.atexit(exit)
	reaper.defer(run)
end

init()