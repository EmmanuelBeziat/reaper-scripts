-- @description Show Check: dockable pre-show checklist (audio device, Wi-Fi, Helix, lyrics script, web interfaces, Art-Net)
-- @version 1.0.0
-- @author Emmanuel Béziat
-- @provides
--   [main] .
-- @changelog
--    # Initial release (replaces Check Hardware)

local script_file = (debug.getinfo(1, "S").source):gsub("^@", ""):gsub("\\", "/")
local script_dir = (script_file:match("^(.+)/[^/]*$") or ".") .. "/"
dofile(script_dir .. "show-check/run.lua")