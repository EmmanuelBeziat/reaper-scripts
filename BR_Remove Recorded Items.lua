-- @description Clear all content from 'Records' group and its subtracks
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

-- 1-2. Deselect all, find Records track, select it + subtracks
local records_track, records_idx = utils.SelectRecordsAndSubtracks()

if not records_track then
	reaper.ShowMessageBox(MSG_RECORDS_NOT_FOUND, "Error", 0)
	return
end

reaper.Undo_BeginBlock()

-- 3. Delete all items from selected tracks
-- First, collect all items in selected tracks, then delete them
local items_to_delete = {}
for i = 0, reaper.CountTracks(0) - 1 do
	local track = reaper.GetTrack(0, i)
	if reaper.IsTrackSelected(track) then
		local item_count = reaper.CountTrackMediaItems(track)
		for j = 0, item_count - 1 do
			local item = reaper.GetTrackMediaItem(track, j)
			table.insert(items_to_delete, item)
		end
	end
end

-- Delete collected items
for _, item in ipairs(items_to_delete) do
	reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(item), item)
end

-- Refresh the arrange view to immediately show the changes
reaper.UpdateArrange()

reaper.SetEditCurPos(0, false, false)

-- 4. Deselect all tracks
utils.DeselectAllTracks()

reaper.Undo_EndBlock("Band Record: Remove recorded tracks", -1)

