-- @description Create Records track group from template
-- @version 1.1.0
-- @author Emmanuel Béziat
-- @changelog
--    # Move the Records group to the end with ReorderSelectedTracks (keeps sends/receives intact)

local reaper = reaper

-- Import shared utilities (path relative to this script)
local script_path = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = script_path:match("^(.+)/[^/]*$") or "."
local utils = dofile(script_dir .. "/utils/BR_Utils.lua")

local MSG_RECORDS_EXISTS = "Track 'Records' already exists. No action taken."
local MSG_RECORDS_NOT_IN_TEMPLATE = "Records track not found in template!"

-- 1. Check if Records track already exists
if utils.FindTrack("Records") then
	reaper.ShowMessageBox(MSG_RECORDS_EXISTS, "Info", 0)
	return
end

-- 2. Load template (which inserts at beginning), then select Records+subtracks and move to end
local template_path = utils.JoinPath(reaper.GetResourcePath(), "TrackTemplates", "Record Band.RTrackTemplate")
local template_file = io.open(template_path, "r")
if not template_file then
	reaper.ShowMessageBox(("Template file not found at:\n%s"):format(template_path), "Error", 0)
	return
end
template_file:close()

reaper.Undo_BeginBlock()

reaper.Main_openProject("noprompt:" .. template_path, false)

-- Select Records track and all its subtracks
if not utils.SelectRecordsAndSubtracks() then
	reaper.Undo_EndBlock("Band Record: Create Records tracks from template", -1)
	reaper.ShowMessageBox(MSG_RECORDS_NOT_IN_TEMPLATE, "Error", 0)
	return
end

-- Move them to the end (REAPER keeps folder structure and routing)
reaper.ReorderSelectedTracks(reaper.CountTracks(0), 0)

reaper.UpdateArrange()

reaper.Undo_EndBlock("Band Record: Create Records tracks from template", -1)
