FLAG_NORMAL = 0
FLAG_SUCCESS = 1
FLAG_WARNING = 2
FLAG_DANGER = 3
FLAG_SERVER = 4
FLAG_DEV = 5

ix.log = ix.log or {}
ix.log.color = {
	[FLAG_NORMAL] = Color(200, 200, 200),
	[FLAG_SUCCESS] = Color(50, 200, 50),
	[FLAG_WARNING] = Color(255, 255, 0),
	[FLAG_DANGER] = Color(255, 50, 50),
	[FLAG_SERVER] = Color(200, 200, 220),
	[FLAG_DEV] = Color(200, 200, 220),
}
local consoleColor = Color(50, 200, 50)

-- TODO: Creating MYSQL/SQLLite Query for the logging.
-- SUGG: Do I have to get Seperated Database? For ChatLog, For EventLog.

if (SERVER) then
	if (!ix.db) then
		include("sv_database.lua")
	end

	function ix.log.LoadTables()
		file.CreateDir("helix/logs")
	end

	function ix.log.ResetTables()
	end

	ix.log.types = ix.log.types or {}
	function ix.log.AddType(logType, func)
		ix.log.types[logType] = func
	end

	function ix.log.GetString(client, logType, ...)
		local text = ix.log.types[logType]

		if (text) then
			if (isfunction(text)) then
				text = text(client, ...)
			end
		else
			text = -1
		end

		return text
	end

	function ix.log.AddRaw(logString)
		ix.log.Send(ix.util.GetAdmins(), logString)

		Msg("[LOG] ", logString .. "\n")

		if (!noSave) then
			file.Append("helix/logs/"..os.date("%x"):gsub("/", "-")..".txt", "["..os.date("%X").."]\t"..logString.."\r\n")
		end
	end

	function ix.log.Add(client, logType, ...)
		local logString = ix.log.GetString(client, logType, ...)
		if (logString == -1) then return end

		ix.log.Send(ix.util.GetAdmins(), logString)

		Msg("[LOG] ", logString .. "\n")

		if (!noSave) then
			file.Append("helix/logs/"..os.date("%x"):gsub("/", "-")..".txt", "["..os.date("%X").."]\t"..logString.."\r\n")
		end
	end

	function ix.log.Open(client)
		local logData = {}

		netstream.Hook(client, "ixLogView", logData)
	end

	function ix.log.Send(client, logString, flag)
		netstream.Start(client, "ixLogStream", logString, flag)
	end
else
	netstream.Hook("ixLogStream", function(logString, flag)
		MsgC(consoleColor, "[SERVER] ", color_white, logString .. "\n")
	end)
end
