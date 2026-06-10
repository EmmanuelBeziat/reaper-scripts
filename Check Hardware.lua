-- @description Open Check Hardware dockable window
-- @version 1.0.7
-- @author Emmanuel Béziat
-- @provides
--   [main] .
-- @changelog
--    # Fix ReaImGui font API (CreateFont family+size, PushFont 2 args)

local script_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (script_file:match("^(.+)/[^/]*$") or ".") .. "/"
dofile(script_dir .. "check-hardware/run.lua")
