FLAG_NORMAL = 0
FLAG_SUCCESS = 1
FLAG_WARNING = 2
FLAG_DANGER = 3
FLAG_SERVER = 4
FLAG_DEV = 5

nut.log = nut.log or {}
nut.log.color = {
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
	if (!nut.db) then
		include("sv_database.lua")
	end

	local SQLITE_CREATE_LOG = [[
		CREATE TABLE IF NOT EXISTS `nut_logs` (
			`_id` INTEGER PRIMARY KEY,
			`_date` INTEGER,
			`_text` TEXT
		);
	]]

	local MYSQL_CREATE_LOG = [[
		CREATE TABLE IF NOT EXISTS `nut_logs` (
			`_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
			`_date` int(11) unsigned NOT NULL,
			`_text` tinytext NOT NULL,
			PRIMARY KEY (`_id`)
		);
	]]

	function nut.log.loadTables()
		if (nut.db.object) then
			nut.db.query(MYSQL_CREATE_LOG)
		else
			nut.db.query(SQLITE_CREATE_LOG)
		end
	end

	function nut.log.resetTables()
		nut.db.query("DROP TABLE IF EXISTS `nut_logs`")
		nut.log.loadTables()
	end

	function nut.log.add(logString, flag, logLevel, noSave)
		flag = flag or FLAG_NORMAL

		if (flag != FLAG_SERVER) then
			nut.log.send(nut.util.getAdmins(), logString, flag)
		end

		MsgC(consoleColor, "[LOG] ", nut.log.color[flag] or color_white, logString .. "\n")
		
		if (!noSave) then
			nut.db.insertTable({
				_date = nut.util.getUTCTime(),
				_text = logString
			}, nil, "logs")
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