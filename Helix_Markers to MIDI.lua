-- @description Helix: convert markers of the "Helix" ruler lane to MIDI events
-- @version 1.2.0
-- @author Emmanuel Béziat
-- @changelog
--    # Label each cue on the MIDI item with a colored take marker (e.g. "2:04C S1")

local reaper = reaper

-- Import shared utilities (path relative to this script)
local script_path = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = script_path:match("^(.+)/[^/]*$") or "."
local helix = dofile(script_dir .. "/utils/Helix_Utils.lua")

local TITLE = "Helix markers to MIDI"
local MSG_TRACK_NOT_FOUND = "Track '" .. helix.TRACK_NAME .. "' not found!"
local MSG_LANE_NOT_FOUND = "No ruler lane named '" .. helix.LANE_NAME .. "'."
local MSG_NO_MARKERS = "No markers on the '" .. helix.LANE_NAME .. "' lane."
local MSG_INVALID_MARKERS = "Invalid marker names, nothing was changed:\n\n%s\n\n"
	.. "Syntax: p-<setlist>-<preset>, p-<preset>, s-<snapshot>, or combined (p-2-12C-s-1)."
local MSG_TOO_MANY_ITEMS = "'" .. helix.TRACK_NAME .. "' holds several items. Glue or delete them so only one MIDI item remains."
local MSG_NOT_MIDI = "The item on '" .. helix.TRACK_NAME .. "' is not a MIDI item."
local MSG_MARKERS_LEFT = "MIDI written, but %d marker(s) could not be deleted. Delete them by hand before running the script again."

-- Make sure the item spans from the project start to end_pos (create it if needed)
-- Returns: MIDI item
local function CoverRange(track, item, end_pos)
	if not item then
		return reaper.CreateNewMIDIItemInProj(track, 0, end_pos, false)
	end

	local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	if item_start > 0 or item_end < end_pos then
		reaper.MIDI_SetItemExtents(item,
			reaper.TimeMap2_timeToQN(0, 0),
			reaper.TimeMap2_timeToQN(0, math.max(item_end, end_pos)))
	end
	return item
end

-- Insert the events of a cue: CC69 exactly at the marker; CC32 + PC on one tick (one bank/program event),
-- just before the snapshot when there is one (on the same tick as it if the cue sits at the item start)
local function InsertCue(take, item_start_ppq, cue)
	local qn = reaper.TimeMap2_timeToQN(0, cue.position)
	local cue_ppq = reaper.MIDI_GetPPQPosFromProjQN(take, qn)
	local preset_ppq = cue_ppq
	if cue.snapshot then
		preset_ppq = math.max(reaper.MIDI_GetPPQPosFromProjQN(take, qn - helix.ORDER_GAP_QN), item_start_ppq)
	end

	local ch = helix.MIDI_CHANNEL
	if cue.setlist then
		reaper.MIDI_InsertCC(take, false, false, preset_ppq, 0xB0, ch, helix.CC_SETLIST, cue.setlist)
	end
	if cue.preset then
		reaper.MIDI_InsertCC(take, false, false, preset_ppq, 0xC0, ch, cue.preset, 0)
	end
	if cue.snapshot then
		reaper.MIDI_InsertCC(take, false, false, cue_ppq, 0xB0, ch, helix.CC_SNAPSHOT, cue.snapshot)
	end
end

local track = helix.FindTrack(helix.TRACK_NAME)
if not track then
	reaper.ShowMessageBox(MSG_TRACK_NOT_FOUND, TITLE, 0)
	return
end

local lane = helix.FindLane()
if not lane then
	reaper.ShowMessageBox(MSG_LANE_NOT_FOUND, TITLE, 0)
	return
end

local markers = helix.GetLaneMarkers(lane)
if #markers == 0 then
	reaper.ShowMessageBox(MSG_NO_MARKERS, TITLE, 0)
	return
end

-- 1. Parse every marker first: nothing is written if one name is invalid
local cues, invalid = {}, {}
for _, marker in ipairs(markers) do
	local cue = helix.ParseMarkerName(marker.name)
	if cue then
		cue.position = marker.position
		table.insert(cues, cue)
	else
		table.insert(invalid, ("- \"%s\" at %s"):format(marker.name, reaper.format_timestr_pos(marker.position, "", -1)))
	end
end

if #invalid > 0 then
	reaper.ShowMessageBox(MSG_INVALID_MARKERS:format(table.concat(invalid, "\n")), TITLE, 0)
	return
end

-- 2. Target item: the single item of the track, or a new one
local item_count = reaper.CountTrackMediaItems(track)
if item_count > 1 then
	reaper.ShowMessageBox(MSG_TOO_MANY_ITEMS, TITLE, 0)
	return
end

local item = item_count == 1 and reaper.GetTrackMediaItem(track, 0) or nil
if item and not reaper.TakeIsMIDI(reaper.GetActiveTake(item)) then
	reaper.ShowMessageBox(MSG_NOT_MIDI, TITLE, 0)
	return
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

-- 3. Write the cues into an item spanning the whole project, then remove the markers
local end_pos = math.max(reaper.GetProjectLength(0), cues[#cues].position + 1)
item = CoverRange(track, item, end_pos)
local take = reaper.GetActiveTake(item)
local item_start_ppq = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.GetMediaItemInfo_Value(item, "D_POSITION"))

for _, cue in ipairs(cues) do
	InsertCue(take, item_start_ppq, cue)
	helix.AddTakeLabel(take, cue.position, cue)
end
reaper.MIDI_Sort(take)

local deleted = helix.DeleteMarkers(markers)

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Helix: markers to MIDI", -1)

if deleted < #markers then
	reaper.ShowMessageBox(MSG_MARKERS_LEFT:format(#markers - deleted), TITLE, 0)
end
