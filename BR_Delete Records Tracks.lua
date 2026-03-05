-- @description Remove the Records track and all its subtracks
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

-- Defer the remove so REAPER has one main-loop cycle to apply the selection (otherwise 40005 may not see it)
reaper.defer(function ()
	reaper.Main_OnCommand(40005, 0)  -- Track: Remove tracks
	reaper.UpdateArrange()
	reaper.Undo_EndBlock("Band Record: Delete Records tracks", -1)
end)
