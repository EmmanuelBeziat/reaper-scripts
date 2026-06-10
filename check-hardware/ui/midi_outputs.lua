return function(Config, ReaImGui, MidiOutput)
	local MidiOutputsUi = {}

	local function color_u32(r, g, b, a)
		return ReaImGui.call("ColorConvertDouble4ToU32", r / 255, g / 255, b / 255, a or 1)
	end

	local function draw_colored_text(ctx, r, g, b, text)
		ReaImGui.call("TextColored", ctx, color_u32(r, g, b, 1), text)
	end

	local function status_detail(result)
		if result.ok then
			return "connected"
		end
		if result.status == "wrong_name" then
			return string.format("wrong name at id %s (got %q)", tostring(result.id), result.name or "")
		end
		return string.format("not found (%d output(s) enabled)", result.num_outputs or 0)
	end

	function MidiOutputsUi.draw(ctx)
		local checks = MidiOutput.check_all()
		local outputs = MidiOutput.list_all_outputs()

		MidiOutput.log_snapshot(checks, outputs)

		for _, entry in ipairs(checks) do
			local device = entry.device
			local result = entry.result
			local label = device.label or "MIDI Output"
			local display_name = result.ok and result.name or device.name

			ReaImGui.call("Text", ctx, label .. ":")
			ReaImGui.call("SameLine", ctx)
			if result.ok then
				draw_colored_text(ctx, Config.colors.ok[1], Config.colors.ok[2], Config.colors.ok[3], display_name)
			else
				draw_colored_text(ctx, Config.colors.error[1], Config.colors.error[2], Config.colors.error[3], display_name)
			end

			ReaImGui.call("TextDisabled", ctx, status_detail(result))
			ReaImGui.call("Spacing", ctx)
		end

		ReaImGui.call("Separator", ctx)
		ReaImGui.call("Text", ctx, string.format("All MIDI outputs (%d)", #outputs))

		if #outputs == 0 then
			ReaImGui.call("TextDisabled", ctx, "No enabled MIDI outputs. Check Preferences > MIDI Devices.")
		else
			for _, output in ipairs(outputs) do
				local line = string.format("[%d] %s", output.id, output.name ~= "" and output.name or "(empty name)")
				ReaImGui.call("BulletText", ctx, line)
			end
		end

		if Config.debug and Config.debug.console_log then
			ReaImGui.call("Spacing", ctx)
			ReaImGui.call("TextDisabled", ctx, "Debug log: View > Show console")
		end
	end

	return MidiOutputsUi
end
