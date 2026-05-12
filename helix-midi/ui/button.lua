-- Button UI element
return function(Config)
  local MIDI = dofile(Config.script_path .. "core/midi.lua")

  local Button = {
    x = Config.button.x,
    y = Config.button.y,
    width = Config.button.width,
    height = Config.button.height,
    text = Config.button.text,
    is_down = false
  }

  function Button.draw()
    -- Draw button background
    gfx.set(0.3, 0.5, 0.7, 1)
    gfx.rect(Button.x, Button.y, Button.width, Button.height, 1)

    -- Draw button text
    gfx.set(1, 1, 1, 1)
    gfx.x = Button.x + 40
    gfx.y = Button.y + 12
    gfx.drawstr(Button.text)
  end

  function Button.handle_click()
    if gfx.mouse_cap & 1 == 1 then
      local mx, my = gfx.mouse_x, gfx.mouse_y
      if mx > Button.x and mx < Button.x + Button.width and
        my > Button.y and my < Button.y + Button.height then
        if not Button.is_down then
          MIDI.create_midi_block()
          Button.is_down = true
        end
      end
    else
      Button.is_down = false
    end
  end

  return Button
end