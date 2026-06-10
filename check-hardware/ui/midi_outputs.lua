return function(Config, ReaImGui, MidiOutput)
	local MidiOutputsUi = {}

	local function text_color(r, g, b)
		return ReaImGui.call("ColorConvertNative", reaper.ColorToNative(r, g, b))
	end

	local function draw_colored_text(ctx, r, g, b, label)
		ReaImGui.call("PushStyleColor", ctx, ReaImGui.flag("Col_Text"), text_color(r, g, b))
		ReaImGui.call("Text", ctx, label)
		ReaImGui.call("PopStyleColor", ctx, 1)
	end

	function MidiOutputsUi.draw(ctx)
		local checks = MidiOutput.check_all()

		for _, entry in ipairs(checks) do
			local device = entry.device
			local result = entry.result
			local label = device.label or "MIDI Output"

			ReaImGui.call("Text", ctx, label .. ":")

			if result.ok then
				draw_colored_text(ctx, Config.colors.ok[1], Config.colors.ok[2], Config.colors.ok[3], result.name)
			else
				draw_colored_text(ctx, Config.colors.error[1], Config.colors.error[2], Config.colors.error[3], device.name)
			end

			ReaImGui.call("Spacing", ctx)
		end
	end

	return MidiOutputsUi
end
