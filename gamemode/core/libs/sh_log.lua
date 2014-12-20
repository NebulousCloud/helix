FLAG_NORMAL = 0
FLAG_SUCCESS = 1
FLAG_WARNING = 2
FLAG_DANGER = 3
FLAG_SERVER = 4

nut.log = nut.log or {}
nut.log.color = {
	[FLAG_NORMAL] = Color(200, 200, 200),
	[FLAG_SUCCESS] = Color(50, 200, 50),
	[FLAG_WARNING] = Color(255, 255, 0),
	[FLAG_DANGER] = Color(255, 50, 50),
	[FLAG_SERVER] = Color(200, 200, 220),
}
local consoleColor = Color(50, 200, 50)

-- TODO: Creating MYSQL/SQLLite Query for the logging.

if (SERVER) then
	function nut.log.add(logString, flag, logLevel, noSave)
		flag = flag or FLAG_NORMAL

		if (flag != FLAG_SERVER) then
				nut.log.send(nut.util.getAdmins(), logString, flag)
		end

		MsgC(consoleColor, "[LOG] ", nut.log.color[flag] or color_white, logString .. "\n")
		
		if (!noSave) then
			-- insert mysql query
		end
	end

	function nut.log.load(lines)
		return
	end

	function nut.log.search(client)
		return
	end

	function nut.log.open(client)
		local logData = {}

		netstream.Hook(client, "nutLogView", logData)
	end

	function nut.log.save()
		-- SAVE QUERY
	end

	function nut.log.send(client, logString, flag)
		netstream.Start(client, "nutLogStream", logString, flag)
	end
else
	netstream.Hook("nutLogStream", function(logString, flag)
		MsgC(consoleColor, "[LOG] ", nut.log.color[flag] or color_white, logString .. "\n")
	end)
end