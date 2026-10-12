-- @description Render 'Records' group as stems
-- @version 1.1.0
-- @author Emmanuel Béziat
-- @changelog
--    # Render bounds set to the recorded items (ignores time selection)
--    # Disarm Records subtracks before rendering
--    # Check the project is saved before changing anything (no more open undo block)
--    # Report a cancelled or failed render instead of "Render completed"
--    # Create the output folder without shell commands

local reaper = reaper

-- Import shared utilities (path relative to this script)
local script_path = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = script_path:match("^(.+)/[^/]*$") or "."
local utils = dofile(script_dir .. "/utils/BR_Utils.lua")

local MSG_RECORDS_NOT_FOUND = "Track 'Records' not found!"
local MSG_SUBTRACKS_EMPTY = "Records subtracks are empty.\nNothing to render."
local MSG_PROJECT_UNSAVED = "Save the project before rendering so the output folder can be determined."
local MSG_CFILLION_MISSING = "Optional script not found:\n\n"
	.. "cfillion_Apply render preset.lua\n\n"
	.. "Install it via ReaPack: ReaTeam Scripts → Rendering → \"cfillion_Apply render preset\".\n\n"
	.. "Rendering will use built-in settings (stems, $track, MP3 with REAPER default settings) instead of your \"StemsExport\" preset."
local MSG_RENDER_FAILED = "Render cancelled or failed: some files are missing."

-- 1-3. Deselect all, find Records track, select it + subtracks
local records_track, records_idx = utils.SelectRecordsAndSubtracks()

if not records_track then
	reaper.ShowMessageBox(MSG_RECORDS_NOT_FOUND, "Error", 0)
	return
end

-- Render bounds = time range covered by the recorded items (only subtracks hold items, not the Records folder track)
local render_start, render_end = utils.GetSubtracksItemsBounds(records_track, records_idx)
if not render_start then
	reaper.ShowMessageBox(MSG_SUBTRACKS_EMPTY, "Render", 0)
	return
end

-- The output path is relative to the project, so the project must be saved
local _, project_file = reaper.EnumProjects(-1)
if project_file == "" then
	reaper.ShowMessageBox(MSG_PROJECT_UNSAVED, "Render", 0)
	return
end

reaper.Undo_BeginBlock()

-- Unmute all selected tracks, disarm Records subtracks (recording is over)
utils.SetSelectedTracksMute(0)
utils.SetSubtracksRecordArm(records_track, records_idx, 0)

local date_str = os.date("%Y-%m-%d %Hh%Mm")

-- Apply render preset via cfillion script dynamically (no hardcoded action ID)
-- Set this to the name of the preset you saved in REAPER's render dialog
local preset_to_apply = "StemsExport"
local cfillion_script = utils.JoinPath(reaper.GetResourcePath(), "Scripts", "ReaTeam Scripts", "Rendering", "cfillion_Apply render preset.lua")
local f = io.open(cfillion_script, "r")
if f then
	f:close()
	-- The cfillion script looks for a global `ApplyPresetByName` variable
	-- when present it applies the preset silently. Set it and run the script.
	ApplyPresetByName = preset_to_apply
	dofile(cfillion_script)
	ApplyPresetByName = nil
else
	reaper.ShowMessageBox(MSG_CFILLION_MISSING, "cfillion script missing", 0)
	-- Fallback: set required render flags directly (stems via master + pattern + MP3)
	reaper.GetSetProjectInfo(0, "RENDER_SETTINGS", 130, true)
	reaper.GetSetProjectInfo_String(0, "RENDER_PATTERN", "$track", true)
	reaper.GetSetProjectInfo_String(0, "RENDER_FORMAT", "l3pm", true)
end

-- Ensure output directory is our render folder (override preset if needed).
-- Pass path relative to project so REAPER doesn't prepend project path again (which caused duplicated paths).
local render_file_relative = "Records/" .. date_str
reaper.GetSetProjectInfo_String(0, "RENDER_FILE", render_file_relative, true)

-- Render the recorded range only (custom bounds), whatever the preset or time selection says
reaper.GetSetProjectInfo(0, "RENDER_BOUNDSFLAG", 0, true)
reaper.GetSetProjectInfo(0, "RENDER_STARTPOS", render_start, true)
reaper.GetSetProjectInfo(0, "RENDER_ENDPOS", render_end, true)

-- Expected output files (semicolon-separated absolute paths)
local _, render_targets = reaper.GetSetProjectInfo_String(0, "RENDER_TARGETS", "", false)
local target_files = {}
for target in render_targets:gmatch("[^;]+") do
	table.insert(target_files, target)
end
local render_folder = target_files[1] and utils.ParentPath(target_files[1]) or render_file_relative
if target_files[1] then
	reaper.RecursiveCreateDirectory(render_folder, 0)
end

-- Trigger automatic render using the most recent render settings
reaper.Main_OnCommand(41824, 0)
-- Mute the Records track after rendering (always, regardless of initial state)
reaper.SetMediaTrackInfo_Value(records_track, "B_MUTE", 1)

reaper.SetEditCurPos(0, false, false)
reaper.Undo_EndBlock("Band Record: Render Records stems", -1)

local render_ok = #target_files > 0
for _, target in ipairs(target_files) do
	if not reaper.file_exists(target) then
		render_ok = false
		break
	end
end

if render_ok then
	reaper.ShowMessageBox(("Render completed. Files saved to:\n%s"):format(render_folder), "Render Complete", 0)
else
	reaper.ShowMessageBox(MSG_RENDER_FAILED, "Render", 0)
end
