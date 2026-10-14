-- Network checks run in a background shell job (ping, curl and system_profiler
-- take seconds); the job writes key=value lines that update() polls each frame.
return function(Config, Status)
	local Network = {}
	local script_file = os.tmpname()
	local output_file = script_file .. ".out"
	local results = nil
	local started_at = nil
	local finished_at = nil

	local function check_host(host)
		if type(host) ~= "string" or not host:match("^[%w%.%-]+$") then
			error("Show Check: invalid host in config: " .. tostring(host), 0)
		end
		return host
	end

	local function check_port(port)
		if math.type(port) ~= "integer" or port < 1 or port > 65535 then
			error("Show Check: invalid port in config: " .. tostring(port), 0)
		end
		return port
	end

	local function shell_script()
		local web_host = check_host(Config.web_interfaces.host)
		local lines = {
			'out="$1"',
			'tmp="$out.tmp"',
			"T=" .. math.floor(Config.network.timeout_seconds),
			': > "$tmp"',
			'emit() { echo "$1=$2" >> "$tmp"; }',
			[[http() { emit "http_$2" "$(curl -s -o /dev/null -w '%{http_code}' --max-time "$T" "http://$1:$2/")"; }]],
			'reach() { if ping -c 1 -t "$T" "$2" > /dev/null 2>&1; then emit "$1" ok; else emit "$1" fail; fi; }',
			"wifi() {",
			[[	iface=$(networksetup -listallhardwareports | awk '/Wi-Fi/ { getline; print $2; exit }')]],
			[[	emit wifi_ip "$(ipconfig getifaddr "$iface")"]],
			[[	emit wifi_ssid "$(ipconfig getsummary "$iface" | awk -F ' : ' '/^ +SSID :/ { print $2; exit }')"]],
			[[	emit wifi_channel "$(system_profiler SPAirPortDataType | awk '/Current Network Information/ { f = 1 } f && /Channel:/ { sub(/^ *Channel: */, ""); print; exit }')"]],
			[[	gw=$(route -n get default 2> /dev/null | awk '/gateway:/ { print $2; exit }')]],
			[[	[ -n "$gw" ] && emit wifi_router_mac "$(arp -n "$gw" | awk '{ print $4; exit }')"]],
			"}",
			"wifi &",
		}
		for _, port in ipairs(Config.web_interfaces.ports) do
			table.insert(lines, "http " .. web_host .. " " .. check_port(port) .. " &")
		end
		table.insert(lines, "reach artnet " .. check_host(Config.artnet_host) .. " &")
		table.insert(lines, "wait")
		table.insert(lines, 'mv "$tmp" "$out"')
		return table.concat(lines, "\n") .. "\n"
	end

	-- arp drops leading zeros ("4:f4:..."), so compare zero-padded bytes
	local function normalize_mac(mac)
		local bytes = {}
		for part in (mac or ""):gmatch("%x+") do
			table.insert(bytes, string.format("%02x", tonumber(part, 16)))
		end
		if #bytes ~= 6 then
			return ""
		end
		return table.concat(bytes, ":")
	end

	local function write_script()
		local file = assert(io.open(script_file, "w"))
		file:write(shell_script())
		file:close()
	end

	local function read_output()
		local file = io.open(output_file, "r")
		if not file then
			return nil
		end

		local parsed = {}
		for line in file:lines() do
			local key, value = line:match("^([%w_]+)=(.*)$")
			if key then
				parsed[key] = value
			end
		end
		file:close()
		os.remove(output_file)
		return parsed
	end

	local function start()
		started_at = reaper.time_precise()
		-- os.tmpname paths have no spaces, so no quoting is needed
		reaper.ExecProcess("/bin/sh " .. script_file .. " " .. output_file, -1)
	end

	function Network.update()
		local now = reaper.time_precise()
		if started_at then
			local parsed = read_output()
			if parsed then
				results, started_at, finished_at = parsed, nil, now
			elseif now - started_at > Config.network.stale_seconds then
				started_at = nil
			end
			return
		end

		if not finished_at or now - finished_at >= Config.network.refresh_seconds then
			start()
		end
	end

	function Network.refresh()
		if not started_at then
			start()
		end
	end

	function Network.is_running()
		return started_at ~= nil
	end

	function Network.cleanup()
		os.remove(script_file)
		os.remove(output_file)
		os.remove(output_file .. ".tmp")
	end

	function Network.wifi()
		if not results then
			return Status.pending()
		end

		local wifi = Config.wifi
		local ip = results.wifi_ip or ""
		local ssid = results.wifi_ssid or ""
		local channel = results.wifi_channel or ""

		local router_mac = normalize_mac(results.wifi_router_mac)

		if ip == "" then
			return Status.fail("Wi-Fi not connected")
		end
		if router_mac ~= normalize_mac(wifi.router_mac) then
			return Status.fail("Wrong network (router " .. (router_mac ~= "" and router_mac or "unknown") .. ")")
		end
		if not channel:find(wifi.band, 1, true) then
			return Status.fail("Not on " .. wifi.band .. " (channel " .. (channel ~= "" and channel or "unknown") .. ")")
		end
		if ssid == "" or ssid == "<redacted>" then
			return Status.ok(ip .. ", " .. channel)
		end
		if ssid:sub(1, #wifi.ssid):lower() ~= wifi.ssid:lower() then
			return Status.fail("Network " .. ssid)
		end
		return Status.ok(ssid .. ", " .. ip .. ", " .. channel)
	end

	function Network.web(port)
		if not results then
			return Status.pending()
		end

		local code = tonumber(results["http_" .. port]) or 0
		if code >= 200 and code < 400 then
			return Status.ok("HTTP " .. code)
		end
		if code == 0 then
			return Status.fail("No response")
		end
		return Status.fail("HTTP " .. code)
	end

	function Network.artnet()
		if not results then
			return Status.pending()
		end

		if results.artnet == "ok" then
			return Status.ok("Ping OK")
		end
		return Status.fail("No ping reply")
	end

	write_script()

	return Network
end