local ReaImGui = {
	ImGui = nil,
}

local function call(name, ...)
	local fn = reaper["ImGui_" .. name]
	if not fn then
		error("ReaImGui API missing: ImGui_" .. name, 2)
	end
	return fn(...)
end

local function flag(name)
	local fn = reaper["ImGui_" .. name]
	if type(fn) == "function" then
		return fn()
	end
	return 0
end

function ReaImGui.ensure()
	if not reaper.ImGui_CreateContext then
		reaper.ShowMessageBox(
			"Missing dependency: ReaImGui extension.\n\nInstall it via ReaPack: Extensions > ReaTeam Extensions.",
			"Check Hardware",
			0
		)
		return false
	end

	if reaper.ImGui_GetBuiltinPath then
		package.path = reaper.ImGui_GetBuiltinPath() .. "/?.lua;" .. package.path
		ReaImGui.ImGui = require("imgui") "0.9"
	end

	return true
end

function ReaImGui.create_context(title)
	local config_flags = flag("ConfigFlags_DockingEnable")
	return call("CreateContext", title, config_flags)
end

function ReaImGui.call(name, ...)
	if ReaImGui.ImGui and ReaImGui.ImGui[name] then
		local fn = ReaImGui.ImGui[name]
		return fn(...)
	end
	return call(name, ...)
end

function ReaImGui.flag(name)
	if ReaImGui.ImGui and ReaImGui.ImGui[name] ~= nil then
		local value = ReaImGui.ImGui[name]
		if type(value) == "function" then
			return value()
		end
		return value
	end
	return flag(name)
end

return ReaImGui
