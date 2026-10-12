-- @description Prepare and start recording on Records group
-- @version 1.1.0
-- @author Emmanuel Béziat
-- @changelog
--    # Warn when tracks outside Records are armed, with an option to disarm them
--    # Check subtracks are empty before muting anything

local reaper = reaper

-- Import shared utilities (path relative to this script)
local script_path = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = script_path:match("^(.+)/[^/]*$") or "."
local utils = dofile(script_dir .. "/utils/BR_Utils.lua")

local MSG_RECORDS_NOT_FOUND = "Track 'Records' not found!"
local MSG_SUBTRACKS_NOT_EMPTY = "Warning: Records subtracks are not empty!\nPlease clear them before recording."
local MSG_OTHER_TRACKS_ARMED = "These tracks outside Records are armed and would be recorded too:\n\n%s\n\n"
	.. "Yes: disarm them\nNo: keep them armed\nCancel: abort"

-- True if track is inside the given folder track (at any depth)
local function IsInsideFolder(track, folder)
	local parent = reaper.GetParentTrack(track)
	while parent do
		if parent == folder then
			return true
		end
		parent = reaper.GetParentTrack(parent)
	end
	return false
end

local records_track, records_idx = utils.FindTrack("Records")
if not records_track then
	reaper.ShowMessageBox(MSG_RECORDS_NOT_FOUND, "Error", 0)
	return
end

-- 1. Check if subtracks of Records are empty
if not utils.AreSubtracksEmpty(records_track, records_idx) then
	reaper.ShowMessageBox(MSG_SUBTRACKS_NOT_EMPTY, "Error", 0)
	return
end

-- 2. Check for armed tracks outside Records
local other_armed_tracks = {}
local other_armed_names = {}
for i = 0, reaper.CountTracks(0) - 1 do
	local track = reaper.GetTrack(0, i)
	if reaper.GetMediaTrackInfo_Value(track, "I_RECARM") == 1
		and track ~= records_track and not IsInsideFolder(track, records_track) then
		table.insert(other_armed_tracks, track)
		local _, name = reaper.GetTrackName(track)
		table.insert(other_armed_names, "- " .. name)
	end
end

local disarm_others = false
if #other_armed_tracks > 0 then
	local message = MSG_OTHER_TRACKS_ARMED:format(table.concat(other_armed_names, "\n"))
	local choice = reaper.ShowMessageBox(message, "Band Record", 3)
	if choice == 2 then  -- Cancel
		return
	end
	disarm_others = choice == 6  -- Yes
end

reaper.Undo_BeginBlock()

if disarm_others then
	for _, track in ipairs(other_armed_tracks) do
		reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
	end
end

-- Mute Records and Track tracks
reaper.SetMediaTrackInfo_Value(records_track, "B_MUTE", 1)

local track_track = utils.FindTrack("Track")
if track_track then
	reaper.SetMediaTrackInfo_Value(track_track, "B_MUTE", 1)
end

-- 3. Arm all subtracks of Records for recording
utils.SetSubtracksRecordArm(records_track, records_idx, 1)

-- 4. Move cursor to project start
reaper.SetEditCurPos(0, false, false)

-- 5. Start recording
reaper.Undo_EndBlock("Band Record: Prepare recording", -1)
reaper.Main_OnCommand(1013, 0)  -- Transport: Record
