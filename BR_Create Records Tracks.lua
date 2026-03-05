-- @description Create Records track group from template
-- @version 1.0.0
-- @author Emmanuel Béziat
-- @changelog
--    # Initial commit

local reaper = reaper

-- Import shared utilities (path relative to this script)
local script_path = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = script_path:match("^(.+)/[^/]*$") or "."
local utils = dofile(script_dir .. "/utils/BR_Utils.lua")

local MSG_RECORDS_EXISTS = "Track 'Records' already exists. No action taken."
local MSG_RECORDS_NOT_IN_TEMPLATE = "Records track not found in template!"

-- 1. Check if Records track already exists
local records_track = utils.FindTrack("Records")
if records_track then
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
local records_track, records_idx, count_selected = utils.SelectRecordsAndSubtracks()
if not records_track then
	reaper.Undo_EndBlock("Band Record: Create Records tracks from template", -1)
	reaper.ShowMessageBox(MSG_RECORDS_NOT_IN_TEMPLATE, "Error", 0)
	return
end

-- Collect selected tracks' state chunks (in order)
local selected_tracks = {}
local track_states = {}

for i = 0, reaper.CountTracks(0) - 1 do
	local track = reaper.GetTrack(0, i)
	if reaper.IsTrackSelected(track) then
		table.insert(selected_tracks, track)
		local _, state = reaper.GetTrackStateChunk(track, "", false)
		table.insert(track_states, state)
	end
end

-- Delete selected tracks from their current positions (delete in reverse order to preserve indices)
for i = #selected_tracks, 1, -1 do
	reaper.DeleteTrack(selected_tracks[i])
end

-- Re-add them at the end (preserves parent-child relationships since we maintain order)
for _, state in ipairs(track_states) do
	local idx = reaper.CountTracks(0)
	reaper.InsertTrackAtIndex(idx, false)
	local track = reaper.GetTrack(0, idx)
	reaper.SetTrackStateChunk(track, state, false)
end

reaper.UpdateArrange()

reaper.Undo_EndBlock("Band Record: Create Records tracks from template", -1)
