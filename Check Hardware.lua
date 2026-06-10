-- @description Open Check Hardware dockable window
-- @version 1.0.2
-- @author Emmanuel Béziat
-- @provides
--   [main] .
-- @changelog
--    # Register action in REAPER (root entry + main section)

local script_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (script_file:match("^(.+)/[^/]*$") or ".") .. "/"
dofile(script_dir .. "check-hardware/run.lua")
