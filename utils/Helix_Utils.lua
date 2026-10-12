-- Helix_Utils.lua - Shared code for the Helix markers <-> MIDI scripts
-- Marker syntax: "p-<setlist>-<preset>", "p-<preset>", "s-<snapshot>", or combined ("p-2-12C-s-1")
--   setlist: CC32 value (0-7), preset: PC value (0-127) or Helix name (e.g. 12C), snapshot: CC69 value (0-7)

local reaper = reaper

local Helix = {
	TRACK_NAME = "Helix Snapshots",
	LANE_NAME = "Helix",
	-- Events are written on channel 1 (0-based here) and read on any channel:
	-- the track's MIDI hardware output sets the Helix channel
	MIDI_CHANNEL = 0,
	-- Bank MSB: sent by the Helix with every preset change, not used by these scripts
	CC_BANK_MSB = 0,
	CC_SETLIST = 32,
	CC_SNAPSHOT = 69,
	-- CC32 + PC are written this much before the CC69 of the same cue, so the Helix loads the preset first
	ORDER_GAP_QN = 1 / 64,
	-- Events closer than this are read back as one cue
	GROUP_QN = 1 / 16,
	-- Marker colors (r, g, b) per cue content
	COLORS = {
		preset = { 255, 140, 0 },
		snapshot = { 40, 110, 230 },
		both = { 150, 70, 200 },
	},
}

local COMMANDS = { p = true, s = true }

-- Native marker color for a cue: preset, snapshot, or both
function Helix.CueColor(cue)
	local rgb = Helix.COLORS[cue.preset and cue.snapshot and "both" or cue.preset and "preset" or "snapshot"]
	return reaper.ColorToNative(rgb[1], rgb[2], rgb[3]) | 0x1000000
end

-- Find track by name
-- Returns: track object, or nil if not found
function Helix.FindTrack(track_name)
	for i = 0, reaper.CountTracks(0) - 1 do
		local track = reaper.GetTrack(0, i)
		local _, name = reaper.GetTrackName(track)
		if name == track_name then
			return track
		end
	end
	return nil
end

-- Integer token within 0..max, or nil
local function ParseNumber(token, max)
	if not token:match("^%d+$") then
		return nil
	end
	local value = tonumber(token)
	return value <= max and value or nil
end

-- Helix preset name (bank 1-32 + letter A-D) to PC value: 12C -> 46
function Helix.PresetFromName(token)
	local bank, letter = token:upper():match("^(%d+)([A-D])$")
	if not bank then
		return nil
	end
	bank = tonumber(bank)
	if bank < 1 or bank > 32 then
		return nil
	end
	return (bank - 1) * 4 + (letter:byte() - ("A"):byte())
end

-- PC value to Helix preset name: 46 -> 12C
function Helix.PresetToName(pc)
	return ("%02d%s"):format(pc // 4 + 1, string.char(("A"):byte() + pc % 4))
end

-- Parse a marker name into a cue { setlist, preset, snapshot } (each optional)
-- Returns: cue, or nil if the name is invalid
function Helix.ParseMarkerName(name)
	local tokens = {}
	for token in name:gmatch("[^-]+") do
		table.insert(tokens, token:match("^%s*(.-)%s*$"))
	end

	local cue = {}
	local i = 1
	while i <= #tokens do
		local command = tokens[i]:lower()
		local args = {}
		i = i + 1
		while i <= #tokens and not COMMANDS[tokens[i]:lower()] do
			table.insert(args, tokens[i])
			i = i + 1
		end

		if command == "p" and cue.preset == nil and (#args == 1 or #args == 2) then
			cue.preset = Helix.PresetFromName(args[#args]) or ParseNumber(args[#args], 127)
			if cue.preset == nil then
				return nil
			end
			if #args == 2 then
				cue.setlist = ParseNumber(args[1], 7)
				if cue.setlist == nil then
					return nil
				end
			end
		elseif command == "s" and cue.snapshot == nil and #args == 1 then
			cue.snapshot = ParseNumber(args[1], 7)
			if cue.snapshot == nil then
				return nil
			end
		else
			return nil
		end
	end

	return next(cue) and cue or nil
end

-- Cue to marker name (preset written as a Helix name); a setlist needs a preset
function Helix.FormatMarkerName(cue)
	local parts = {}
	if cue.preset then
		table.insert(parts, "p")
		if cue.setlist then
			table.insert(parts, tostring(cue.setlist))
		end
		table.insert(parts, Helix.PresetToName(cue.preset))
	end
	if cue.snapshot then
		table.insert(parts, "s")
		table.insert(parts, tostring(cue.snapshot))
	end
	return table.concat(parts, "-")
end

-- Label shown on the MIDI item for a cue: "2:04C S1", "04C", "S0"
function Helix.FormatLabel(cue)
	local parts = {}
	if cue.preset then
		local preset = Helix.PresetToName(cue.preset)
		table.insert(parts, cue.setlist and (cue.setlist .. ":" .. preset) or preset)
	end
	if cue.snapshot then
		table.insert(parts, "S" .. cue.snapshot)
	end
	return table.concat(parts, " ")
end

local LABEL_TOKENS = { "^%d:%d%d[A-D]$", "^%d%d[A-D]$", "^S%d$" }

-- True if a take marker name has the label syntax (so only the script's own take markers are deleted)
local function IsLabel(name)
	if not name:match("%S") then
		return false
	end
	for token in name:gmatch("%S+") do
		local valid = false
		for _, pattern in ipairs(LABEL_TOKENS) do
			if token:match(pattern) then
				valid = true
				break
			end
		end
		if not valid then
			return false
		end
	end
	return true
end

-- Add a colored take marker labelling a cue at a project position
function Helix.AddTakeLabel(take, position, cue)
	local item = reaper.GetMediaItemTake_Item(take)
	local offset = position - reaper.GetMediaItemInfo_Value(item, "D_POSITION")
	local source_pos = offset * reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
		+ reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
	reaper.SetTakeMarker(take, -1, Helix.FormatLabel(cue), source_pos, Helix.CueColor(cue))
end

-- Delete the cue labels of a take (other take markers are kept)
function Helix.DeleteTakeLabels(take)
	for i = reaper.GetNumTakeMarkers(take) - 1, 0, -1 do
		local _, name = reaper.GetTakeMarker(take, i)
		if IsLabel(name) then
			reaper.DeleteTakeMarker(take, i)
		end
	end
end

-- Cue field matching a MIDI event, or nil if the Helix cue doesn't use it
function Helix.EventKind(chanmsg, msg2)
	if chanmsg == 0xC0 then
		return "preset"
	end
	if chanmsg == 0xB0 and msg2 == Helix.CC_SETLIST then
		return "setlist"
	end
	if chanmsg == 0xB0 and msg2 == Helix.CC_SNAPSHOT then
		return "snapshot"
	end
	return nil
end

-- Ruler lanes: the API doesn't say whether lane numbers start at 0 or 1, so scan 0..count
local function LaneCount()
	return math.floor(reaper.GetSetProjectInfo(0, "RULER_LANE_COUNT", 0, false))
end

local function LaneGuids()
	local guids = {}
	for lane = 0, LaneCount() do
		local ok, guid = reaper.GetSetProjectInfo_String(0, "RULER_LANE_GUID:" .. lane, "", false)
		if ok and guid ~= "" then
			guids[guid] = lane
		end
	end
	return guids
end

-- Returns: number of the ruler lane named Helix.LANE_NAME, or nil
function Helix.FindLane()
	for lane = 0, LaneCount() do
		local ok, name = reaper.GetSetProjectInfo_String(0, "RULER_LANE_NAME:" .. lane, "", false)
		if ok and name == Helix.LANE_NAME then
			return lane
		end
	end
	return nil
end

-- Returns: number of the Helix ruler lane, created at the bottom if missing, or nil if creation failed
function Helix.GetOrCreateLane()
	local lane = Helix.FindLane()
	if lane then
		return lane
	end

	local before = LaneGuids()
	reaper.GetSetProjectInfo(0, "RULER_LANE_ORDER:-1", LaneCount(), true)
	for guid, new_lane in pairs(LaneGuids()) do
		if before[guid] == nil then
			reaper.GetSetProjectInfo_String(0, "RULER_LANE_NAME:" .. new_lane, Helix.LANE_NAME, true)
			return new_lane
		end
	end
	return nil
end

-- Returns: list of { guid, position, name } for the markers (not regions) of a ruler lane, by position
function Helix.GetLaneMarkers(lane)
	local markers = {}
	for i = 0, reaper.GetNumRegionsOrMarkers(0) - 1 do
		local marker = reaper.GetRegionOrMarker(0, i, "")
		if reaper.GetRegionOrMarkerInfo_Value(0, marker, "B_ISREGION") == 0
			and reaper.GetRegionOrMarkerInfo_Value(0, marker, "I_LANENUMBER") == lane then
			local _, name = reaper.GetSetRegionOrMarkerInfo_String(0, marker, "P_NAME", "", false)
			local _, guid = reaper.GetSetRegionOrMarkerInfo_String(0, marker, "GUID", "", false)
			table.insert(markers, {
				guid = guid,
				position = reaper.GetRegionOrMarkerInfo_Value(0, marker, "D_STARTPOS"),
				name = name,
			})
		end
	end
	table.sort(markers, function(a, b) return a.position < b.position end)
	return markers
end

-- Delete markers by GUID (deleting by index would shift the following indices)
-- Returns: number of markers deleted
function Helix.DeleteMarkers(markers)
	local deleted = 0
	for _, marker in ipairs(markers) do
		for i = 0, reaper.GetNumRegionsOrMarkers(0) - 1 do
			local _, guid = reaper.GetSetProjectInfo_String(0, "MARKER_GUID:" .. i, "", false)
			if guid == marker.guid then
				reaper.DeleteProjectMarkerByIndex(0, i)
				deleted = deleted + 1
				break
			end
		end
	end
	return deleted
end

-- Add a marker on a ruler lane (color: native color | 0x1000000, or 0 for the default)
function Helix.AddLaneMarker(lane, position, name, color)
	local marker = reaper.AddRegionOrMarker(0, false, position, position, name, -1, color or 0)
	reaper.SetRegionOrMarkerInfo_Value(0, marker, "I_LANENUMBER", lane)
end

return Helix
