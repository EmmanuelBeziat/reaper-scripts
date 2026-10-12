-- @description Helix: snap the markers of the "Helix" ruler lane to the project grid
-- @version 1.0.0
-- @author Emmanuel Béziat
-- @changelog
--    # Initial release

local reaper = reaper

-- Import shared utilities (path relative to this script)
local script_path = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = script_path:match("^(.+)/[^/]*$") or "."
local helix = dofile(script_dir .. "/utils/Helix_Utils.lua")

local TITLE = "Helix snap markers to grid"
local MSG_LANE_NOT_FOUND = "No ruler lane named '" .. helix.LANE_NAME .. "'."
local MSG_NO_MARKERS = "No markers on the '" .. helix.LANE_NAME .. "' lane."
local MSG_DONE = "%d of %d marker(s) moved to the grid."

-- Grid step in QN, or nil for a measure grid
local function GridStepQN()
	local _, division, swingmode = reaper.GetSetProjectGrid(0, false)
	if swingmode == 3 then
		return nil
	end
	return division * 4
end

-- Nearest grid line, counted from the start of the measure (works with any time signature)
local function SnapPosition(position, step_qn)
	local qn = reaper.TimeMap2_timeToQN(0, position)
	local _, measure_start, measure_end = reaper.TimeMap_QNToMeasures(0, qn)
	local step = step_qn or (measure_end - measure_start)
	local snapped = measure_start + math.floor((qn - measure_start) / step + 0.5) * step
	return reaper.TimeMap2_QNToTime(0, math.min(snapped, measure_end))
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

reaper.Undo_BeginBlock()

local step_qn = GridStepQN()
local moved = 0
for _, marker in ipairs(markers) do
	local snapped = SnapPosition(marker.position, step_qn)
	if math.abs(snapped - marker.position) > 1e-9 then
		local handle = reaper.GetRegionOrMarker(0, -1, marker.guid)
		reaper.SetRegionOrMarkerInfo_Value(0, handle, "D_STARTPOS", snapped)
		moved = moved + 1
	end
end

reaper.UpdateTimeline()
reaper.Undo_EndBlock("Helix: snap markers to grid", -1)

reaper.ShowMessageBox(MSG_DONE:format(moved, #markers), TITLE, 0)
