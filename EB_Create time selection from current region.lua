-- @description Create a time selection from current region
-- @version 1.0.0
-- @author Emmanuel Béziat
-- @changelog
--    # Initial commit

local project = 0
local isPlaying = (reaper.GetPlayState() & 1) == 1
local referencePosition = isPlaying and reaper.GetPlayPosition() or reaper.GetCursorPosition()
local _, markerCount, regionCount = reaper.CountProjectMarkers(project)
local totalMarkersAndRegions = markerCount + regionCount

local bestRegionStartTime = -1
local bestRegionEndTime = -1

for markerIndex = 0, totalMarkersAndRegions - 1 do
	local _, isRegion, regionStartTime, regionEndTime = reaper.EnumProjectMarkers3(project, markerIndex, false, 0, 0, "", 0, 0)
	if isRegion and referencePosition >= regionStartTime and referencePosition < regionEndTime then
		if regionStartTime > bestRegionStartTime then
			bestRegionStartTime = regionStartTime
			bestRegionEndTime = regionEndTime
		end
	end
end

if bestRegionStartTime >= 0 then
	reaper.GetSet_LoopTimeRange(true, true, bestRegionStartTime, bestRegionEndTime, false)
	reaper.Undo_OnStateChange("Region to time selection")
else
	reaper.MB("No region at current position.", "Region to time selection", 0)
end
