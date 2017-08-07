nut.db = nut.db or {}
nut.util.include("nutscript/gamemode/config/sv_database.lua")

local function ThrowQueryFault(query, fault)
	MsgC(Color(255, 0, 0), "* "..query.."\n")
	MsgC(Color(255, 0, 0), fault.."\n")
end

local function ThrowConnectionFault(fault)
	MsgC(Color(255, 0, 0), "NutScript has failed to connect to the database.\n")
	MsgC(Color(255, 0, 0), fault.."\n")

	setNetVar("dbError", fault)
end

local modules = {}

-- SQLite for local storage.
modules.sqlite = {
	query = function(query, callback)
		local data = sql.Query(query)
		local fault = sql.LastError()

		if (data == false) then
			ThrowQueryFault(query, fault)
		end

		if (callback) then
			local lastID = tonumber(sql.QueryValue("SELECT last_insert_rowid()"))

			callback(data, lastID)
		end
	end,
	escape = function(value)
		return sql.SQLStr(value, true)
	end,
	connect = function(callback)
		if (callback) then
			callback()
		end
	end
}

-- tmysql4 module for MySQL storage.
modules.tmysql4 = {
	query = function(query, callback)
		if (nut.db.object) then
			nut.db.object:Query(query, function(data, status, lastID)
				if (QUERY_SUCCESS and status == QUERY_SUCCESS) then
					if (callback) then
						callback(data, lastID)
					end
				else
					if (data and data[1]) then
						if (data[1].status) then
							if (callback) then
								callback(data[1].data, data[1].lastid)
							end

							return
						else
							lastID = data[1].error
						end
					end

					file.Write("nut_queryerror.txt", query)
					ThrowQueryFault(query, lastID or "")
				end
			end, 3)
		end
	end,
	escape = function(value)
		if (nut.db.object) then
			return nut.db.object:Escape(value)
		end

		return tmysql and tmysql.escape and tmysql.escape(value) or sql.SQLStr(value, true)
	end,
	connect = function(callback)
		if (!pcall(require, "tmysql4")) then
			return setNetVar("dbError", system.IsWindows() and "Server is missing VC++ redistributables!" or "Server is missing binaries for tmysql4!")
		end

		local hostname = nut.db.hostname
		local username = nut.db.username
		local password = nut.db.password
		local database = nut.db.database
		local port = nut.db.port
		local object, fault = tmysql.initialize(hostname, username, password, database, port)

		if (object) then
			nut.db.object = object
			nut.db.escape = modules.tmysql4.escape
			nut.db.query = modules.tmysql4.query

			if (callback) then
				callback()
			end
		else
			ThrowConnectionFault(fault)
		end	
	end
}

MYSQLOO_QUEUE = MYSQLOO_QUEUE or {}

-- mysqloo for MySQL storage.
modules.mysqloo = {
	query = function(query, callback)
		if (nut.db.object) then
			local object = nut.db.object:query(query)

			if (callback) then
				function object:onSuccess(data)
					callback(data, self:lastInsert())
				end
			end

			function object:onError(fault)
				if (nut.db.object:status() == mysqloo.DATABASE_NOT_CONNECTED) then
					MYSQLOO_QUEUE[#MYSQLOO_QUEUE + 1] = {query, callback}
					nut.db.connect()

					return
				end

				ThrowQueryFault(query, fault)
			end

			object:start()
		end
	end,
	escape = function(value)
		local object = nut.db.object

		if (object) then
			return object:escape(value)
		else
			return sql.SQLStr(value, true)
		end
	end,
	connect = function(callback)
		if (!pcall(require, "mysqloo")) then
			return setNetVar("dbError", system.IsWindows() and "Server is missing VC++ redistributables!" or "Server is missing binaries for mysqloo!")
		end

		local hostname = nut.db.hostname
		local username = nut.db.username
		local password = nut.db.password
		local database = nut.db.database
		local port = nut.db.port
		local object = mysqloo.connect(hostname, username, password, database, port)

		function object:onConnected()
			nut.db.object = self
			nut.db.escape = modules.mysqloo.escape
			nut.db.query = modules.mysqloo.query

			for k, v in ipairs(MYSQLOO_QUEUE) do
				nut.db.query(v[1], v[2])
			end

			MYSQLOO_QUEUE = {}

			if (callback) then
				callback()
			end
		end

		function object:onConnectionFailed(fault)
			ThrowConnectionFault(fault)
		end

		object:connect()

		timer.Create("nutMySQLWakeUp", 300, 0, function()
			nut.db.query("SELECT 1 + 1")
		end)
	end
}

-- Add default values here.
nut.db.escape = modules.sqlite.escape
nut.db.query = modules.sqlite.query

function nut.db.connect(callback)
	local dbModule = modules[nut.db.module]

	if (dbModule) then
		if (!nut.db.object) then
			dbModule.connect(callback)
		end

		nut.db.escape = dbModule.escape
		nut.db.query = dbModule.query
	else
		ErrorNoHalt("[NutScript] '"..(nut.db.module or "nil").."' is not a valid data storage method!\n")
	end
end

local MYSQL_CREATE_TABLES = [[
CREATE TABLE IF NOT EXISTS `nut_characters` (
	`_id` int(11) unsigned NOT NULL AUTO_INCREMENT,
	`_name` varchar(70) NOT NULL,
	`_desc` text NOT NULL,
	`_model` varchar(160) NOT NULL,
	`_attribs` varchar(500) DEFAULT NULL,
	`_schema` varchar(24) NOT NULL,
	`_createTime` int(11) unsigned NOT NULL,
	`_lastJoinTime` int(4) DEFAULT NULL,
	`_steamID` bigint(20) unsigned NOT NULL,
	`_data` longtext,
	`_money` int(11) unsigned DEFAULT NULL,
	`_faction` varchar(50) NOT NULL,
	PRIMARY KEY (`_id`)
);

CREATE TABLE IF NOT EXISTS `nut_inventories` (
	`_invID` int(11) unsigned NOT NULL AUTO_INCREMENT,
	`_charID` int(11) unsigned NOT NULL,
	`_invType` varchar(24) DEFAULT NULL,
	PRIMARY KEY (`_invID`)
);

CREATE TABLE IF NOT EXISTS `nut_items` (
	`_itemID` int(11) unsigned NOT NULL AUTO_INCREMENT,
	`_invID` int(11) unsigned NOT NULL,
	`_uniqueID` varchar(60) NOT NULL,
	`_data` varchar(500) DEFAULT NULL,
	`_x` smallint(4) NOT NULL,
	`_y` smallint(4) NOT NULL,
	PRIMARY KEY (`_itemID`)
);

CREATE TABLE IF NOT EXISTS `nut_players` (
	`_steamID` bigint(20) NOT NULL,
	`_steamName` varchar(32) NOT NULL,
	`_playTime` int(11) unsigned DEFAULT NULL,
	`_address` varchar(15) DEFAULT NULL,
	`_lastJoin` int(11) unsigned DEFAULT NULL,
	`_data` text,
	PRIMARY KEY (`_steamID`)
);
]]

local SQLITE_CREATE_TABLES = [[
CREATE TABLE IF NOT EXISTS `nut_characters` (
	`_id` INTEGER PRIMARY KEY,
	`_name` TEXT,
	`_desc` TEXT,
	`_model` TEXT,
	`_attribs` TEXT,
	`_schema` TEXT,
	`_createTime` INTEGER,
	`_lastJoinTime` INTEGER,
	`_steamID` INTEGER,
	`_data` TEXT,
	`_money` INTEGER,
	`_faction` TEXT
);

CREATE TABLE IF NOT EXISTS `nut_inventories` (
	`_invID` INTEGER PRIMARY KEY,
	`_charID` INTEGER,
	`_invType` TEXT
);

CREATE TABLE IF NOT EXISTS `nut_items` (
	`_itemID` INTEGER PRIMARY KEY,
	`_invID` INTEGER,
	`_x` INTEGER,
	`_y` INTEGER,
	`_uniqueID` TEXT,
	`_data` TEXT
);

CREATE TABLE IF NOT EXISTS `nut_players` (
	`_steamID` INTEGER,
	`_steamName` TEXT,
	`_playTime` INTEGER,
	`_address` TEXT,
	`_lastJoin` INTEGER,
	`_data` TEXT
);
]]

local DROP_QUERY = [[
DROP TABLE IF EXISTS `nut_characters`;
DROP TABLE IF EXISTS `nut_items`;
DROP TABLE IF EXISTS `nut_players`;
DROP TABLE IF EXISTS `nut_inventories`;
]]

function nut.db.wipeTables()
	local function callback()
		MsgC(Color(255, 0, 0), "[Nutscript] ALL NUTSCRIPT DATA HAS BEEN WIPED\n")
	end
	
	if (nut.db.object) then
		local queries = string.Explode(";", DROP_QUERY)

		for i = 1, 4 do
			nut.db.query(queries[i], callback)
		end
	else
		nut.db.query(DROP_QUERY, callback)
	end

	nut.db.loadTables()
end

local resetCalled = 0
concommand.Add("nut_recreatedb", function(client, cmd, arguments)
	-- this command can be run in RCON or SERVER CONSOLE
	if (!IsValid(client)) then
		if (resetCalled < RealTime()) then
			resetCalled = RealTime() + 3

			MsgC(Color(255, 0, 0), "[Nutscript] TO CONFIRM DATABASE RESET, RUN 'nut_recreatedb' AGAIN in 3 SECONDS.\n")
		else
			resetCalled = 0
			
			MsgC(Color(255, 0, 0), "[Nutscript] DATABASE WIPE IN PROGRESS.\n")
			
			hook.Run("OnWipeTables")
			nut.db.wipeTables()
		end
	end
end)

function nut.db.loadTables()
	if (nut.db.object) then
		-- This is needed to perform multiple queries since the string is only 1 big query.
		local queries = string.Explode(";", MYSQL_CREATE_TABLES)

		for i = 1, 4 do
			nut.db.query(queries[i])
		end
	else
		nut.db.query(SQLITE_CREATE_TABLES)
	end

	hook.Run("OnLoadTables")
end

function nut.db.convertDataType(value)
	if (type(value) == "string") then
		return "'"..nut.db.escape(value).."'"
	elseif (type(value) == "table") then
		return "'"..nut.db.escape(util.TableToJSON(value)).."'"
	end

	return value
end

function nut.db.insertTable(value, callback, dbTable)
	local query = "INSERT INTO "..("nut_"..(dbTable or "characters")).." ("
	local keys = {}
	local values = {}

	for k, v in pairs(value) do
		keys[#keys + 1] = k
		values[#keys] = k:find("steamID") and v or nut.db.convertDataType(v)
	end

	query = query..table.concat(keys, ", ")..") VALUES ("..table.concat(values, ", ")..")"
	nut.db.query(query, callback)
end

function nut.db.updateTable(value, callback, dbTable, condition)
	local query = "UPDATE "..("nut_"..(dbTable or "characters")).." SET "
	local changes = {}

	for k, v in pairs(value) do
		changes[#changes + 1] = k.." = "..(k:find("steamID") and v or nut.db.convertDataType(v))
	end

	query = query..table.concat(changes, ", ")..(condition and " WHERE "..condition or "")
	nut.db.query(query, callback)
end
