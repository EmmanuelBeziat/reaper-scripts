-- MIDI Device List UI component
return function(Config, MIDI)
  local DeviceList = {
    x = Config.device_list.x,
    y = Config.device_list.y,
    width = Config.device_list.width,
    height = Config.device_list.height,
    helix_found = false
  }

  function DeviceList.init()
    DeviceList.helix_found = MIDI.find_helix() ~= nil
  end

  function DeviceList.draw()
    -- Draw status box
    gfx.set(0.2, 0.2, 0.2, 1)
    gfx.rect(DeviceList.x, DeviceList.y, DeviceList.width, 40, 1)

    -- Draw status text
    gfx.set(1, 1, 1, 1)
    gfx.x = DeviceList.x + 5
    gfx.y = DeviceList.y + 5
    gfx.drawstr("Line 6 Helix Status:")

    -- Draw status
    gfx.x = DeviceList.x + 10
    gfx.y = DeviceList.y + 25
    if DeviceList.helix_found then
      gfx.set(0, 0.8, 0, 1)  -- Green for found
      gfx.drawstr("Connected")
    else
      gfx.set(0.8, 0, 0, 1)  -- Red for not found
      gfx.drawstr("Not Found")
    end
  end

  function DeviceList.handle_click()
    -- No click handling needed
  end

  return DeviceList
end