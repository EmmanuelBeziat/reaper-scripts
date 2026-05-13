-- Numeric fields for Helix parameters (gfx: label, value, - / +)
return function(Config, callbacks)
	local C = Config.helix_fields
	local fields = {
		{ key = "setlist", label = "Setlist", min = 0, max = 7, value = 0 },
		{ key = "preset", label = "Preset", min = 0, max = 127, value = 0 },
		{ key = "snapshot", label = "Snapshot", min = 0, max = 7, value = 0 },
		{ key = "expr1", label = "Expression pedal 1", min = 0, max = 127, value = 0 },
	}

	local cb = {
		setlist = callbacks.on_setlist_change,
		preset = callbacks.on_preset_change,
		snapshot = callbacks.on_snapshot_change,
		expr1 = callbacks.on_expression_pedal1_change,
	}

	local HelixFields = {
		_mouse_was_down = false,
	}

	local function row_layout(index)
		local y = C.y + (index - 1) * C.row_height
		local lx = C.x
		local vx = C.x + C.label_width
		local bw = C.button_width
		local gap = C.button_gap
		local minus_x = vx + C.value_width + gap
		local plus_x = minus_x + bw + gap
		return y, lx, vx, minus_x, plus_x, bw
	end

	local function hit(mx, my, x, y, w, h)
		return mx >= x and mx < x + w and my >= y and my < y + h
	end

	local function clamp(v, lo, hi)
		if v < lo then
			return lo
		end
		if v > hi then
			return hi
		end
		return v
	end

	local function apply_delta(row, delta)
		local nv = clamp(row.value + delta, row.min, row.max)
		if nv ~= row.value then
			row.value = nv
			local fn = cb[row.key]
			if fn then
				fn(nv)
			end
		end
	end

	function HelixFields.draw()
		for i, row in ipairs(fields) do
			local y, lx, vx, minus_x, plus_x, bw = row_layout(i)
			local rh = C.row_height - 2

			gfx.set(0.85, 0.85, 0.85, 1)
			gfx.x = lx
			gfx.y = y + 6
			gfx.drawstr(row.label)

			gfx.set(0.12, 0.12, 0.12, 1)
			gfx.rect(vx, y, C.value_width, rh, 1)
			gfx.set(1, 1, 1, 1)
			gfx.x = vx + 6
			gfx.y = y + 6
			gfx.drawstr(tostring(row.value))

			gfx.set(0.35, 0.35, 0.4, 1)
			gfx.rect(minus_x, y, bw, rh, 1)
			gfx.rect(plus_x, y, bw, rh, 1)
			gfx.set(1, 1, 1, 1)
			gfx.x = minus_x + 7
			gfx.y = y + 6
			gfx.drawstr("-")
			gfx.x = plus_x + 6
			gfx.y = y + 6
			gfx.drawstr("+")
		end
	end

	function HelixFields.handle_click()
		local down = (gfx.mouse_cap & 1) == 1
		if down and not HelixFields._mouse_was_down then
			local mx, my = gfx.mouse_x, gfx.mouse_y
			for i, row in ipairs(fields) do
				local y, _, vx, minus_x, plus_x, bw = row_layout(i)
				local rh = C.row_height - 2
				if hit(mx, my, minus_x, y, bw, rh) then
					apply_delta(row, -1)
					break
				end
				if hit(mx, my, plus_x, y, bw, rh) then
					apply_delta(row, 1)
					break
				end
			end
		end
		HelixFields._mouse_was_down = down
	end

	return HelixFields
end
