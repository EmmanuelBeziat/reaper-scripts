-- Numeric fields for Helix parameters (gfx: label, value, - / +)
-- Large ranges: horizontal scrub on value box + mouse wheel when pointer is over the value
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
		_scrub = nil, -- { row, anchor_x, anchor_val } while dragging value box
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

	local function set_value(row, nv)
		nv = clamp(math.floor(nv + 0.5), row.min, row.max)
		if nv ~= row.value then
			row.value = nv
			local fn = cb[row.key]
			if fn then
				fn(nv)
			end
		end
	end

	local function apply_delta(row, delta)
		set_value(row, row.value + delta)
	end

	local function row_at_mouse(mx, my)
		local rh = C.row_height - 2
		for i, row in ipairs(fields) do
			local y, _, vx = row_layout(i)
			if hit(mx, my, vx, y, C.value_width, rh) then
				return row, i, y, rh, vx
			end
		end
		return nil
	end

	function HelixFields.draw()
		for i, row in ipairs(fields) do
			local y, lx, vx, minus_x, plus_x, bw = row_layout(i)
			local rh = C.row_height - 2
			local wide = (row.max - row.min) > 15

			gfx.set(0.85, 0.85, 0.85, 1)
			gfx.x = lx
			gfx.y = y + 6
			gfx.drawstr(row.label)

			gfx.set(0.12, 0.12, 0.12, 1)
			gfx.rect(vx, y, C.value_width, rh, 1)
			if wide then
				gfx.set(0.28, 0.28, 0.32, 1)
				gfx.rect(vx, y + rh - 3, C.value_width, 3, 1)
			end
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
		local mx, my = gfx.mouse_x, gfx.mouse_y
		local down = (gfx.mouse_cap & 1) == 1
		local rh = C.row_height - 2

		local w = gfx.mouse_wheel
		gfx.mouse_wheel = 0
		if w ~= 0 then
			local row = select(1, row_at_mouse(mx, my))
			if row then
				local notch = C.wheel_pixels_per_notch or 80
				local mag = math.max(1, math.floor(math.abs(w) / notch))
				local dir = w > 0 and 1 or -1
				set_value(row, row.value + dir * mag)
			end
		end

		if HelixFields._scrub and down then
			local sens = C.scrub_pixels_per_step or 2
			set_value(HelixFields._scrub.row, HelixFields._scrub.anchor_val
				+ math.floor((mx - HelixFields._scrub.anchor_x) / sens))
		end

		if not down then
			HelixFields._scrub = nil
		else
			if down and not HelixFields._mouse_was_down then
				local hit_row = false
				for i, row in ipairs(fields) do
					local y, _, vx, minus_x, plus_x, bw = row_layout(i)
					if hit(mx, my, minus_x, y, bw, rh) then
						apply_delta(row, -1)
						hit_row = true
						break
					end
					if hit(mx, my, plus_x, y, bw, rh) then
						apply_delta(row, 1)
						hit_row = true
						break
					end
				end
				if not hit_row then
					for i, row in ipairs(fields) do
						local y, _, vx = row_layout(i)
						if hit(mx, my, vx, y, C.value_width, rh) then
							HelixFields._scrub = {
								row = row,
								anchor_x = mx,
								anchor_val = row.value,
							}
							break
						end
					end
				end
			end
		end

		HelixFields._mouse_was_down = down
	end

	function HelixFields.get_values()
		local out = {}
		for _, row in ipairs(fields) do
			out[row.key] = row.value
		end
		return out
	end

	return HelixFields
end
