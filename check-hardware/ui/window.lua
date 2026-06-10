return function(Config, ReaImGui, ctx)
	local Window = {}

	function Window.draw()
		ReaImGui.call(
			"SetNextWindowDockID",
			ctx,
			Config.window.default_dock_id,
			ReaImGui.flag("Cond_FirstUseEver")
		)

		local visible, open = ReaImGui.call(
			"Begin",
			ctx,
			Config.window.title,
			true,
			ReaImGui.flag("WindowFlags_NoCollapse")
		)

		if visible then
			ReaImGui.call("Text", ctx, "Hardware check")
			ReaImGui.call("End", ctx)
		end

		return open
	end

	return Window
end
