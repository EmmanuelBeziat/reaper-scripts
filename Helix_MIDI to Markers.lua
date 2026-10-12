-- @description Helix: convert Helix MIDI events (CC32, PC, CC69) to markers on the "Helix" ruler lane
-- @version 1.0.0
-- @author Emmanuel Béziat
-- @changelog
--    # Initial release

local reaper = reaper

-- Import shared utilities (path relative to this script)
local script_path = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = script_path:match("^(.+)/[^/]*$") or "."
local helix = dofile(script_dir .. "/utils/Helix_Utils.lua")

local TITLE = "Helix MIDI to markers"
local MSG_TRACK_NOT_FOUND = "Track '" .. helix.TRACK_NAME .. "' not found!"
local MSG_NO_EVENTS = "No Helix events (CC32, PC, CC69) on '" .. helix.TRACK_NAME .. "'."
local MSG_LANE_FAILED = "Could not create the '" .. helix.LANE_NAME .. "' ruler lane.\nCreate it by hand, then run the script again."
local MSG_SKIPPED = "%d cue(s) with a setlist change but no preset were left in the MIDI item (no marker syntax for them)."

-- Helix events (unmuted, any channel, inside the item) of a MIDI take, by position
local function CollectEvents(take, item)
	local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local item_end = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
	local events = {}
	local _, _, cc_count = reaper.MIDI_CountEvts(take)
	for i = 0, cc_count - 1 do
		local _, _, muted, ppq, chanmsg, _, msg2, msg3 = reaper.MIDI_GetCC(take, i)
		local kind = helix.EventKind(chanmsg, msg2)
		local position = reaper.MIDI_GetProjTimeFromPPQPos(take, ppq)
		if kind and not muted and position >= item_start and position < item_end then
			table.insert(events, {
				index = i,
				kind = kind,
				value = chanmsg == 0xC0 and msg2 or msg3,
				position = position,
				qn = reaper.MIDI_GetProjQNFromPPQPos(take, ppq),
			})
		end
	end
	table.sort(events, function(a, b) return a.qn < b.qn end)
	return events
end

-- Group close events into cues (one value per kind)
local function GroupEvents(events)
	local groups = {}
	for _, event in ipairs(events) do
		local group = groups[#groups]
		if not group or event.qn - group.qn > helix.GROUP_QN or group.cue[event.kind] ~= nil then
			group = { qn = event.qn, position = event.position, cue = {}, indices = {} }
			table.insert(groups, group)
		end
		group.cue[event.kind] = event.value
		table.insert(group.indices, event.index)
	end
	return groups
end

local track = helix.FindTrack(helix.TRACK_NAME)
if not track then
	reaper.ShowMessageBox(MSG_TRACK_NOT_FOUND, TITLE, 0)
	return
end

-- 1. Read the cues of every MIDI item of the track
local takes = {}
local cue_count, skipped = 0, 0
for i = 0, reaper.CountTrackMediaItems(track) - 1 do
	local item = reaper.GetTrackMediaItem(track, i)
	local take = reaper.GetActiveTake(item)
	if take and reaper.TakeIsMIDI(take) then
		local cues = {}
		for _, group in ipairs(GroupEvents(CollectEvents(take, item))) do
			-- A setlist change alone has no marker syntax: leave it in the item
			if group.cue.setlist and not group.cue.preset then
				skipped = skipped + 1
			else
				table.insert(cues, group)
			end
		end
		if #cues > 0 then
			table.insert(takes, { take = take, cues = cues })
			cue_count = cue_count + #cues
		end
	end
end

if cue_count == 0 then
	reaper.ShowMessageBox(MSG_NO_EVENTS, TITLE, 0)
	return
end

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

local lane = helix.GetOrCreateLane()
if not lane then
	reaper.PreventUIRefresh(-1)
	reaper.Undo_EndBlock("Helix: MIDI to markers", -1)
	reaper.ShowMessageBox(MSG_LANE_FAILED, TITLE, 0)
	return
end

-- 2. Create the markers, then remove the converted events (highest index first so indices stay valid)
for _, entry in ipairs(takes) do
	local indices = {}
	for _, group in ipairs(entry.cues) do
		helix.AddLaneMarker(lane, group.position, helix.FormatMarkerName(group.cue))
		for _, index in ipairs(group.indices) do
			table.insert(indices, index)
		end
	end

	table.sort(indices, function(a, b) return a > b end)
	for _, index in ipairs(indices) do
		reaper.MIDI_DeleteCC(entry.take, index)
	end
	reaper.MIDI_Sort(entry.take)
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Helix: MIDI to markers", -1)

if skipped > 0 then
	reaper.ShowMessageBox(MSG_SKIPPED:format(skipped), TITLE, 0)
end
