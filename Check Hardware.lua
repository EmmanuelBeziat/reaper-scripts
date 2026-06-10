-- @description Open Check Hardware dockable window
-- @version 1.0.6
-- @author Emmanuel Béziat
-- @provides
--   [main] .
-- @changelog
--    # Clean UI: large bold device name, theme background, no debug list

local script_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (script_file:match("^(.+)/[^/]*$") or ".") .. "/"
dofile(script_dir .. "check-hardware/run.lua")
