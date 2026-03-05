-- @description Render 'Records' group as MP3 320kbps stems
-- @version 1.0.0
-- @author Emmanuel Béziat
-- @changelog
--    # Initial commit

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
	.. "Rendering will use built-in settings (stems, $track, MP3 320) instead of your \"StemsExport\" preset."

-- 1-3. Deselect all, find Records track, select it + subtracks, unmute
local records_track, records_idx = utils.SelectRecordsAndSubtracks()

if not records_track then
	reaper.ShowMessageBox(MSG_RECORDS_NOT_FOUND, "Error", 0)
	return
end

-- Check if subtracks have content (only subtracks hold items, not the Records folder track)
if utils.AreSubtracksEmpty(records_track, records_idx) then
	reaper.ShowMessageBox(MSG_SUBTRACKS_EMPTY, "Render", 0)
	return
end

reaper.Undo_BeginBlock()

-- Unmute all selected tracks
utils.SetSelectedTracksMute(0)

-- 4. Get render path and create folder structure
-- Use project directory (where the .rpp lives), not its parent, so output is <project>/Records/<date>
local project_path = reaper.GetProjectPath("")
if not project_path or project_path == "" then
	reaper.ShowMessageBox(MSG_PROJECT_UNSAVED, "Render", 0)
	return
end

local date_str = os.date("%Y-%m-%d %Hh%Mm")
local render_folder = utils.JoinPath(project_path, "Records", date_str)

utils.CreateDirectory(render_folder)
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

-- Trigger automatic render using the most recent render settings
reaper.Main_OnCommand(41824, 0)
-- Mute the Records track after rendering (always, regardless of initial state)
reaper.SetMediaTrackInfo_Value(records_track, "B_MUTE", 1)

reaper.SetEditCurPos(0, false, false)
reaper.Undo_EndBlock("Band Record: Render Records stems", -1)
reaper.ShowMessageBox(("Render completed. Files saved to:\n%s"):format(render_folder), "Render Complete", 0)
