return function(Config, ReaImGui, MidiOutput, device_font)
	local MidiOutputsUi = {}

	local function color_u32(r, g, b, a)
		return ReaImGui.call("ColorConvertDouble4ToU32", r / 255, g / 255, b / 255, a or 1)
	end

	function MidiOutputsUi.draw(ctx)
		local checks = MidiOutput.check_all()

		for _, entry in ipairs(checks) do
			local device = entry.device
			local result = entry.result
			local display_name = result.ok and result.name or device.name
			local r, g, b

			if result.ok then
				r, g, b = Config.colors.ok[1], Config.colors.ok[2], Config.colors.ok[3]
			else
				r, g, b = Config.colors.error[1], Config.colors.error[2], Config.colors.error[3]
			end

			ReaImGui.call("PushFont", ctx, device_font, Config.ui.device_font_size)
			ReaImGui.call("TextColored", ctx, color_u32(r, g, b, 1), display_name)
			ReaImGui.call("PopFont", ctx)
		end
	end

	return MidiOutputsUi
end
