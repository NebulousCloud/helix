--[[
	Purpose: Provides a wrapper for database interaction so switching from mysqloo or tmysql4
	can be quickly done without much hassle. There are also some utility functions for the
	database.
--]]

nut.db = nut.db or {}

local dbModule = nut.config.dbModule

-- SQLite doesn't need a module!
if (dbModule != "sqlite") then
	require(nut.config.dbModule)
else
	local SQL_CURR_VERSION = 0
	local SQL_CONFIRMING = 0
	SQL_LOCAL_VERSION = SQL_LOCAL_VERSION or tonumber(file.Read("nutscript/db.txt", "DATA") or 0)

	-- But it does require the script to setup a table.
	local QUERY_CREATE = [[
	CREATE TABLE ]]..nut.config.dbTable..[[ (
		steamid int,
		charname varchar(60),
		description varchar(240),
		gender varchar(6),
		money int,
		inv mediumtext,
		faction int,
		id int,
		chardata mediumtext,
		rpschema varchar(16),
		model tinytext
	);
	]]
	local QUERY_CREATE_PLAYERS = [[
	CREATE TABLE ]]..nut.config.dbPlyTable..[[ (
		steamid int,
		whitelists tinytext,
		plydata mediumtext,
		rpschema tinytext
	);
	]]

	local function initializeTables(recreate)
		local success = true

		if (recreate) then
			sql.Query("DROP TABLE "..nut.config.dbTable)
			sql.Query("DROP TABLE "..nut.config.dbPlyTable)
		end

		if (!sql.TableExists(nut.config.dbTable)) then
			local result = sql.Query(QUERY_CREATE)

			if (result == false) then
				MsgC(Color(255, 0, 0), "NutScript could not create characters table!\n")
				print(sql.LastError())
				success = false
			else
				MsgC(Color(0, 255, 0), "NutScript has created characters table.\n")
			end
		else
			success = false
		end

		if (!sql.TableExists(nut.config.dbPlyTable)) then
			local result = sql.Query(QUERY_CREATE_PLAYERS)

			if (result == false) then
				MsgC(Color(255, 0, 0), "NutScript could not create players table!\n")
				print(sql.LastError())
				success = false
			else
				MsgC(Color(0, 255, 0), "NutScript has created players table.\n")
			end
		else
			success = false
		end

		if (success) then
			MsgC(Color(0, 255, 0), "NutScript has created database tables correctly!\n")
			file.Write("nutscript/db.txt", SQL_CURR_VERSION)
			SQL_LOCAL_VERSION = SQL_CURR_VERSION
		end
	end

	initializeTables()

	if (SQL_LOCAL_VERSION != SQL_CURR_VERSION) then
		MsgC(Color(255, 255, 0), "\nNutScript has had its database tables updated.\n")
		MsgC(Color(255, 255, 0), "You will need to enter the command: "); MsgN("nut_recreatedb")
		MsgC(Color(255, 255, 0), "You will need to enter the command: "); MsgN("nut_recreatedb")
		MsgC(Color(255, 255, 0), "Updating the tables will remove ALL pre-existing data.\n")
		MsgC(Color(255, 255, 0), "Not updating the tables MAY CAUSE SAVING/LOADED ERRORS!\n\n")
	end

	concommand.Add("nut_recreatedb", function(client, command, arguments)
		if (!IsValid(client) or client:IsListenServerHost()) then
			if ((!SQL_CONFIRMING or SQL_CONFIRMING < CurTime()) and SQL_LOCAL_VERSION == SQL_CURR_VERSION) then
				MsgN("NutScript has verified that the table versions match.")
				MsgN("If you would like to recreate the tables, type the command again within 10 seconds.")
				SQL_CONFIRMING = CurTime() + 10

				return
			end

			initializeTables(true)
			SQL_CONFIRMING = 0
		end
	end)
end

--[[
	Purpose: Connects to the database using the configuration values from sv_config.lua
	and connects using the defined modules from the config file.
--]]
function nut.db.Connect()
	if (dbModule == "sqlite") then
		if (nut.db.sqliteInit == true) then return end
		
		print("NutScript using SQLite for database.")
		nut.db.sqliteInit = true

		return
	end

	if (nut.db.object) then
		return
	end

	local hostname = nut.config.dbHost
	local username = nut.config.dbUser
	local password = nut.config.dbPassword
	local database = nut.config.dbDatabase
	local port = nut.config.dbPort

	if (dbModule == "tmysql4") then
		local fault;

		nut.db.object, fault = tmysql.initialize(hostname, username, password, database, port)

		if (!fault) then
			print("NutScript has connected to the database via tmysql4.");
		else
			print("NutScript could not connect to the database!")
			print(fault)
		end
	else
		nut.db.object = mysqloo.connect(hostname, username, password, database, port)
		nut.db.object.onConnected = function()
			print("NutScript has connected to the database via mysqloo.")
		end
		nut.db.object.onConnectionFailed = function(_, fault)
			print("NutScript could not connect to the database!")
			print(fault)
		end
		nut.db.object:connect()
	end
end

nut.db.Connect()

--[[
	Purpose: An alias to the current module's function to escape a string.
--]]
function nut.db.Escape(value)
	if (dbModule == "tmysql4") then
		return tmysql.escape(value)
	elseif (dbModule == "mysqloo") then
		return nut.db.object:escape(value)
	else
		return sql.SQLStr(value)
	end
end

--[[
	Purpose: Makes a query using either tmysql4 or mysqloo and runs the callback
	function passing the data.
--]]
function nut.db.Query(query, callback)
	if (dbModule == "tmysql4") then
		nut.db.object:Query(query, function(result, status, fault)
			if (status == false) then
				print("Query Error: "..query)
				print(fault)
			elseif (callback) then
				callback(result[1], result)
			end
		end, QUERY_FLAG_ASSOC)
	elseif (dbModule == "mysqloo") then
		local result = nut.db.object:query(query)

		if (result) then
			if (callback) then
				result.onSuccess = function(_, data)
					callback(data[1], data)
				end
			end
			result.onError = function(_, fault)
				print("Query Error: "..query);
				print(fault)
			end
			result:start()
		end
	else
		local data = sql.Query(query)

		if (data == false) then
			print("Query Error: "..query)
			print(sql.LastError())
		else
			local value = {}

			if (data and data[1]) then
				value = data[1]

				value.faction = tonumber(value.faction)
				value.id = tonumber(value.id)
			end

			if (callback) then
				callback(value, data or {})
			end
		end
	end
end

--[[
	Purpose: Inserts a table matching the key with a field in the database and a value
	as the value for the field.
--]]
function nut.db.InsertTable(data, callback, dbTable)
	local query = "INSERT INTO "..(dbTable or nut.config.dbTable).." ("

	for k, v in pairs(data) do
		query = query..k..", "
	end

	query = string.sub(query, 1, -3)..") VALUES ("

	for k, v in pairs(data) do
		if (type(k) == "string" and k != "steamid") then
			if (type(v) == "table") then
				v = von.serialize(v)
			end

			-- SQLite doesn't play nice with quotations.
			if (type(v) == "string") then
				if (dbModule == "sqlite") then
					v = nut.db.Escape(v)
				else
					v = "'"..nut.db.Escape(v).."'"
				end
			end
		end

		query = query..v..", "
	end

	query = string.sub(query, 1, -3)..")"
	nut.db.Query(query, callback)
end

--[[
	Purpose: Similar to insert table, it will update the values that are passed through
	the second argument given the condition is true.
--]]
function nut.db.UpdateTable(condition, data, dbTable)
	local query = "UPDATE "..(dbTable or nut.config.dbTable).." SET "

	for k, v in pairs(data) do
		query = query..nut.db.Escape(k).." = "

		if (type(k) == "string" and k != "steamid") then
			if (type(v) == "table") then
				v = von.serialize(v)
			end

			-- SQLite doesn't play nice with quotations.
			if (type(v) == "string") then
				if (dbModule == "sqlite") then
					v = nut.db.Escape(v)
				else
					v = "'"..nut.db.Escape(v).."'"
				end
			end
		end

		query = query..v..", "
	end

	query = string.sub(query, 1, -3).." WHERE "..condition
	nut.db.Query(query, callback)
end

--[[
	Purpose: Returns the values of given fields that are seperated by a comma and passes
	them into the callback function given the condition provided is true.
--]]
function nut.db.FetchTable(condition, tables, callback, dbTable)
	local query = "SELECT "..tables.." FROM "..(dbTable or nut.config.dbTable).." WHERE "..condition

	nut.db.Query(query, callback)
end