local ReaImGui = {}

function ReaImGui.ensure()
	if not reaper.ImGui_CreateContext then
		reaper.ShowMessageBox(
			"Missing dependency: ReaImGui extension.\n\nInstall it via ReaPack: Extensions > ReaTeam Extensions.",
			"Check Hardware",
			0
		)
		return false
	end

	local shim_path = reaper.GetResourcePath() .. "/Scripts/ReaTeam Extensions/API/imgui.lua"
	if reaper.file_exists(shim_path) then
		dofile(shim_path)("0.9")
	end

	return true
end

function ReaImGui.create_context(title)
	return reaper.ImGui_CreateContext(title, reaper.ImGui_ConfigFlags_DockEnable())
end

return ReaImGui
