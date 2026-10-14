return function(Config, ReaImGui, ctx, fonts, Checks)
	local Window = {}

	local function state_color(state)
		local rgb = Config.colors[state]
		return ReaImGui.call("ColorConvertDouble4ToU32", rgb[1] / 255, rgb[2] / 255, rgb[3] / 255, 1)
	end

	local function summary(rows)
		local failures, pending = 0, 0
		for _, row in ipairs(rows) do
			if row.status.state == "error" then
				failures = failures + 1
			elseif row.status.state == "pending" then
				pending = pending + 1
			end
		end

		if failures > 0 then
			return "error", failures .. (failures == 1 and " problem" or " problems")
		end
		if pending > 0 then
			return "pending", "Checking..."
		end
		return "ok", "Ready"
	end

	local function draw_header(rows)
		local state, text = summary(rows)
		ReaImGui.call("PushFont", ctx, fonts.summary)
		ReaImGui.call("TextColored", ctx, state_color(state), text)
		ReaImGui.call("PopFont", ctx)

		if ReaImGui.call("Button", ctx, "Re-check") then
			Checks.refresh()
		end
		ReaImGui.call("SameLine", ctx)
		ReaImGui.call("TextDisabled", ctx, (Checks.is_running() and "Checking network...  " or "") .. "v" .. Config.version)
		ReaImGui.call("Separator", ctx)
	end

	local function draw_rows(rows)
		if not ReaImGui.call("BeginTable", ctx, "checks", 3, ReaImGui.flag("TableFlags_SizingFixedFit")) then
			return
		end

		for i, row in ipairs(rows) do
			ReaImGui.call("TableNextRow", ctx)
			ReaImGui.call("TableNextColumn", ctx)
			ReaImGui.call("PushFont", ctx, fonts.label)
			ReaImGui.call("TextColored", ctx, state_color(row.status.state), row.label)
			ReaImGui.call("PopFont", ctx)

			ReaImGui.call("TableNextColumn", ctx)
			ReaImGui.call("TextDisabled", ctx, row.status.detail)

			ReaImGui.call("TableNextColumn", ctx)
			if row.action then
				ReaImGui.call("PushID", ctx, tostring(i))
				if ReaImGui.call("Button", ctx, row.action.label) then
					reaper.Main_OnCommand(row.action.command, 0)
					Checks.refresh()
				end
				ReaImGui.call("PopID", ctx)
			end
		end

		ReaImGui.call("EndTable", ctx)
	end

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
			local rows = Checks.rows()
			draw_header(rows)
			draw_rows(rows)
			ReaImGui.call("End", ctx)
		end

		return open
	end

	return Window
end