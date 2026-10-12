-- @description Remove the Records track and all its subtracks
-- @version 1.1.0
-- @author Emmanuel Béziat
-- @changelog
--    # Delete tracks directly instead of a deferred action (undo block no longer spans a defer cycle)

local reaper = reaper

-- Import shared utilities (path relative to this script)
local script_path = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = script_path:match("^(.+)/[^/]*$") or "."
local utils = dofile(script_dir .. "/utils/BR_Utils.lua")

local MSG_RECORDS_NOT_FOUND = "Track 'Records' not found!"
local MSG_SUBTRACKS_HAVE_CONTENT = "Records subtracks contain items.\nThey will be lost if not rendered.\n\nDelete anyway?"

-- 1. Find Records track (don't change selection yet so we can get index for AreSubtracksEmpty)
local records_track, records_idx = utils.FindTrack("Records")

if not records_track then
	reaper.ShowMessageBox(MSG_RECORDS_NOT_FOUND, "Error", 0)
	return
end

-- 2. Check if subtracks have content; if so, warn and ask confirmation
if not utils.AreSubtracksEmpty(records_track, records_idx) then
	local choice = reaper.ShowMessageBox(MSG_SUBTRACKS_HAVE_CONTENT, "Delete Records tracks", 1)
	if choice ~= 1 then
		return
	end
end

reaper.Undo_BeginBlock()

-- Select Records and all subtracks
utils.SelectRecordsAndSubtracks()

-- Delete selected tracks (reverse order so indices stay valid)
for i = reaper.CountTracks(0) - 1, 0, -1 do
	local track = reaper.GetTrack(0, i)
	if reaper.IsTrackSelected(track) then
		reaper.DeleteTrack(track)
	end
end

reaper.UpdateArrange()
reaper.Undo_EndBlock("Band Record: Delete Records tracks", -1)
