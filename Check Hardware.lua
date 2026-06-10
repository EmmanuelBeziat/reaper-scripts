-- @description Open Check Hardware dockable window
-- @version 1.0.3
-- @author Emmanuel Béziat
-- @provides
--   [main] .
-- @changelog
--    # Helix MIDI output status (LINE 6 - HELIX, ID 1)

local script_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (script_file:match("^(.+)/[^/]*$") or ".") .. "/"
dofile(script_dir .. "check-hardware/run.lua")
