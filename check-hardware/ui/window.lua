return function(Config, ctx)
	local Window = {}

	function Window.draw()
		reaper.ImGui_SetNextWindowDockID(
			ctx,
			Config.window.default_dock_id,
			reaper.ImGui_Cond_FirstUseEver()
		)

		local visible, open = reaper.ImGui_Begin(
			ctx,
			Config.window.title,
			true,
			reaper.ImGui_WindowFlags_NoCollapse()
		)

		if visible then
			reaper.ImGui_Text(ctx, "Hardware check")
			reaper.ImGui_End(ctx)
		end

		return open
	end

	return Window
end
