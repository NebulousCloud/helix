--[[
	mysql - 1.0.3
	A simple MySQL wrapper for Garry's Mod.

	Alexander Grist-Hucker
	http://www.alexgrist.com


	The MIT License (MIT)

	Copyright (c) 2014 Alex Grist-Hucker

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
--]]

mysql = mysql or {
	module = "sqlite"
};

local QueueTable = {};
local tostring = tostring;
local table = table;

--[[
	Replacement tables
--]]

local Replacements = {
	sqlite = {
		Create = {
			{"UNSIGNED ", ""},
			{"NOT NULL AUTO_INCREMENT", ""}, -- assuming primary key
			{"AUTO_INCREMENT", ""},
			{"INT%(%d*%)", "INTEGER"},
			{"INT ", "INTEGER"}
		}
	}
};

--[[
	Phrases
--]]

local MODULE_NOT_EXIST = "[mysql] The %s module does not exist!\n";

--[[
	Begin Query Class.
--]]

local QUERY_CLASS = {};
QUERY_CLASS.__index = QUERY_CLASS;

function QUERY_CLASS:New(tableName, queryType)
	local newObject = setmetatable({}, QUERY_CLASS);
		newObject.queryType = queryType;
		newObject.tableName = tableName;
		newObject.selectList = {};
		newObject.insertList = {};
		newObject.updateList = {};
		newObject.createList = {};
		newObject.whereList = {};
		newObject.orderByList = {};
	return newObject;
end;

function QUERY_CLASS:Escape(text)
	return mysql:Escape(tostring(text));
end;

function QUERY_CLASS:ForTable(tableName)
	self.tableName = tableName;
end;

function QUERY_CLASS:Where(key, value)
	self:WhereEqual(key, value);
end;

function QUERY_CLASS:WhereEqual(key, value)
	self.whereList[#self.whereList + 1] = "`"..key.."` = \""..self:Escape(value).."\"";
end;

function QUERY_CLASS:WhereNotEqual(key, value)
	self.whereList[#self.whereList + 1] = "`"..key.."` != \""..self:Escape(value).."\"";
end;

function QUERY_CLASS:WhereLike(key, value, format)
	format = format or "%%%s%%"
	self.whereList[#self.whereList + 1] = "`"..key.."` LIKE \""..string.format(format, self:Escape(value)).."\"";
end;

function QUERY_CLASS:WhereNotLike(key, value, format)
	format = format or "%%%s%%"
	self.whereList[#self.whereList + 1] = "`"..key.."` NOT LIKE \""..string.format(format, self:Escape(value)).."\"";
end;

function QUERY_CLASS:WhereGT(key, value)
	self.whereList[#self.whereList + 1] = "`"..key.."` > \""..self:Escape(value).."\"";
end;

function QUERY_CLASS:WhereLT(key, value)
	self.whereList[#self.whereList + 1] = "`"..key.."` < \""..self:Escape(value).."\"";
end;

function QUERY_CLASS:WhereGTE(key, value)
	self.whereList[#self.whereList + 1] = "`"..key.."` >= \""..self:Escape(value).."\"";
end;

function QUERY_CLASS:WhereLTE(key, value)
	self.whereList[#self.whereList + 1] = "`"..key.."` <= \""..self:Escape(value).."\"";
end;

function QUERY_CLASS:WhereIn(key, value)
	value = istable(value) and value or {value}

	local values = "";
	local bFirst = true;

	for k, v in pairs(value) do
		values = values .. (bFirst and "" or ", ") .. self:Escape(v);
		bFirst = false
	end;

	self.whereList[#self.whereList + 1] = "`"..key.."` IN ("..values..")";
end

function QUERY_CLASS:OrderByDesc(key)
	self.orderByList[#self.orderByList + 1] = "`"..key.."` DESC";
end;

function QUERY_CLASS:OrderByAsc(key)
	self.orderByList[#self.orderByList + 1] = "`"..key.."` ASC";
end;

function QUERY_CLASS:Callback(queryCallback)
	self.callback = queryCallback;
end;

function QUERY_CLASS:Select(fieldName)
	self.selectList[#self.selectList + 1] = "`"..fieldName.."`";
end;

function QUERY_CLASS:Insert(key, value)
	self.insertList[#self.insertList + 1] = {"`"..key.."`", "\""..self:Escape(value).."\""};
end;

function QUERY_CLASS:Update(key, value)
	self.updateList[#self.updateList + 1] = {"`"..key.."`", "\""..self:Escape(value).."\""};
end;

function QUERY_CLASS:Create(key, value)
	self.createList[#self.createList + 1] = {"`"..key.."`", value};
end;

function QUERY_CLASS:Add(key, value)
	self.add = {"`"..key.."`", value};
end;

function QUERY_CLASS:Drop(key)
	self.drop = "`"..key.."`";
end;

function QUERY_CLASS:PrimaryKey(key)
	self.primaryKey = "`"..key.."`";
end;

function QUERY_CLASS:Limit(value)
	self.limit = value;
end;

function QUERY_CLASS:Offset(value)
	self.offset = value;
end;

local function ApplyQueryReplacements(mode, query)
	if (!Replacements[mysql.module]) then
		return query
	end

	local result = query
	local entries = Replacements[mysql.module][mode]

	for i = 1, #entries do
		result = string.gsub(result, entries[i][1], entries[i][2])
	end

	return result
end

local function BuildSelectQuery(queryObj)
	local queryString = {"SELECT"};

	if (!istable(queryObj.selectList) or #queryObj.selectList == 0) then
		queryString[#queryString + 1] = " *";
	else
		queryString[#queryString + 1] = " "..table.concat(queryObj.selectList, ", ");
	end;

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " FROM `"..queryObj.tableName.."` ";
	else
		ErrorNoHalt("[mysql] No table name specified!\n");
		return;
	end;

	if (istable(queryObj.whereList) and #queryObj.whereList > 0) then
		queryString[#queryString + 1] = " WHERE ";
		queryString[#queryString + 1] = table.concat(queryObj.whereList, " AND ");
	end;

	if (istable(queryObj.orderByList) and #queryObj.orderByList > 0) then
		queryString[#queryString + 1] = " ORDER BY ";
		queryString[#queryString + 1] = table.concat(queryObj.orderByList, ", ");
	end;

	if (isnumber(queryObj.limit)) then
		queryString[#queryString + 1] = " LIMIT ";
		queryString[#queryString + 1] = queryObj.limit;
	end;

	return table.concat(queryString);
end;

local function BuildInsertQuery(queryObj, bIgnore)
	local suffix = (bIgnore and (mysql.module == "sqlite" and "INSERT OR IGNORE INTO" or "INSERT IGNORE INTO") or "INSERT INTO");
	local queryString = {suffix};
	local keyList = {};
	local valueList = {};

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `"..queryObj.tableName.."`";
	else
		ErrorNoHalt("[mysql] No table name specified!\n");
		return;
	end;

	for i = 1, #queryObj.insertList do
		keyList[#keyList + 1] = queryObj.insertList[i][1];
		valueList[#valueList + 1] = queryObj.insertList[i][2];
	end;

	if (#keyList == 0) then
		return;
	end;

	queryString[#queryString + 1] = " ("..table.concat(keyList, ", ")..")";
	queryString[#queryString + 1] = " VALUES ("..table.concat(valueList, ", ")..")";

	return table.concat(queryString);
end;

local function BuildUpdateQuery(queryObj)
	local queryString = {"UPDATE"};

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `"..queryObj.tableName.."`";
	else
		ErrorNoHalt("[mysql] No table name specified!\n");
		return;
	end;

	if (istable(queryObj.updateList) and #queryObj.updateList > 0) then
		local updateList = {};

		queryString[#queryString + 1] = " SET";

		for i = 1, #queryObj.updateList do
			updateList[#updateList + 1] = queryObj.updateList[i][1].." = "..queryObj.updateList[i][2];
		end;

		queryString[#queryString + 1] = " "..table.concat(updateList, ", ");
	end;

	if (istable(queryObj.whereList) and #queryObj.whereList > 0) then
		queryString[#queryString + 1] = " WHERE ";
		queryString[#queryString + 1] = table.concat(queryObj.whereList, " AND ");
	end;

	if (isnumber(queryObj.offset)) then
		queryString[#queryString + 1] = " OFFSET ";
		queryString[#queryString + 1] = queryObj.offset;
	end;

	return table.concat(queryString);
end;

local function BuildDeleteQuery(queryObj)
	local queryString = {"DELETE FROM"}

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `"..queryObj.tableName.."`";
	else
		ErrorNoHalt("[mysql] No table name specified!\n");
		return;
	end;

	if (istable(queryObj.whereList) and #queryObj.whereList > 0) then
		queryString[#queryString + 1] = " WHERE ";
		queryString[#queryString + 1] = table.concat(queryObj.whereList, " AND ");
	end;

	if (isnumber(queryObj.limit)) then
		queryString[#queryString + 1] = " LIMIT ";
		queryString[#queryString + 1] = queryObj.limit;
	end;

	return table.concat(queryString);
end;

local function BuildDropQuery(queryObj)
	local queryString = {"DROP TABLE"}

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `"..queryObj.tableName.."`";
	else
		ErrorNoHalt("[mysql] No table name specified!\n");
		return;
	end;

	return table.concat(queryString);
end;

local function BuildTruncateQuery(queryObj)
	local queryString = {"TRUNCATE TABLE"}

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `"..queryObj.tableName.."`";
	else
		ErrorNoHalt("[mysql] No table name specified!\n");
		return;
	end;

	return table.concat(queryString);
end;

local function BuildCreateQuery(queryObj)
	local queryString = {"CREATE TABLE IF NOT EXISTS"};

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `"..queryObj.tableName.."`";
	else
		ErrorNoHalt("[mysql] No table name specified!\n");
		return;
	end;

	queryString[#queryString + 1] = " (";

	if (istable(queryObj.createList) and #queryObj.createList > 0) then
		local createList = {};

		for i = 1, #queryObj.createList do
			if (mysql.module == "sqlite") then
				createList[#createList + 1] = queryObj.createList[i][1].." "..ApplyQueryReplacements("Create", queryObj.createList[i][2]);
			else
				createList[#createList + 1] = queryObj.createList[i][1].." "..queryObj.createList[i][2];
			end;
		end;

		queryString[#queryString + 1] = " "..table.concat(createList, ", ");
	end;

	if (isstring(queryObj.primaryKey)) then
		queryString[#queryString + 1] = ", PRIMARY KEY";
		queryString[#queryString + 1] = " ("..queryObj.primaryKey..")";
	end;

	queryString[#queryString + 1] = " )";

	return table.concat(queryString);
end;

local function BuildAlterQuery(queryObj)
	local queryString = {"ALTER TABLE"};

	if (isstring(queryObj.tableName)) then
		queryString[#queryString + 1] = " `"..queryObj.tableName.."`";
	else
		ErrorNoHalt("[mysql] No table name specified!\n");
		return;
	end;

	if (istable(queryObj.add)) then
		queryString[#queryString + 1] = " ADD "..queryObj.add[1].." "..ApplyQueryReplacements("Create", queryObj.add[2]);
	elseif (isstring(queryObj.drop)) then
		if (mysql.module == "sqlite") then
			ErrorNoHalt("[mysql] Cannot drop columns in sqlite!\n");
			return;
		end;

		queryString[#queryString + 1] = " DROP COLUMN "..queryObj.drop;
	end;

	return table.concat(queryString);
end;

function QUERY_CLASS:Execute(bQueueQuery)
	local queryString = nil;
	local queryType = string.lower(self.queryType);

	if (queryType == "select") then
		queryString = BuildSelectQuery(self);
	elseif (queryType == "insert") then
		queryString = BuildInsertQuery(self);
	elseif (queryType == "insert ignore") then
		queryString = BuildInsertQuery(self, true);
	elseif (queryType == "update") then
		queryString = BuildUpdateQuery(self);
	elseif (queryType == "delete") then
		queryString = BuildDeleteQuery(self);
	elseif (queryType == "drop") then
		queryString = BuildDropQuery(self);
	elseif (queryType == "truncate") then
		queryString = BuildTruncateQuery(self);
	elseif (queryType == "create") then
		queryString = BuildCreateQuery(self);
	elseif (queryType == "alter") then
		queryString = BuildAlterQuery(self);
	end;

	if (isstring(queryString)) then
		if (!bQueueQuery) then
			return mysql:RawQuery(queryString, self.callback);
		else
			return mysql:Queue(queryString, self.callback);
		end;
	end;
end;

--[[
	End Query Class.
--]]

function mysql:Select(tableName)
	return QUERY_CLASS:New(tableName, "SELECT");
end;

function mysql:Insert(tableName)
	return QUERY_CLASS:New(tableName, "INSERT");
end;

function mysql:InsertIgnore(tableName)
	return QUERY_CLASS:New(tableName, "INSERT IGNORE");
end;

function mysql:Update(tableName)
	return QUERY_CLASS:New(tableName, "UPDATE");
end;

function mysql:Delete(tableName)
	return QUERY_CLASS:New(tableName, "DELETE");
end;

function mysql:Drop(tableName)
	return QUERY_CLASS:New(tableName, "DROP");
end;

function mysql:Truncate(tableName)
	return QUERY_CLASS:New(tableName, "TRUNCATE");
end;

function mysql:Create(tableName)
	return QUERY_CLASS:New(tableName, "CREATE");
end;

function mysql:Alter(tableName)
	return QUERY_CLASS:New(tableName, "ALTER");
end;

local UTF8MB4 = "ALTER DATABASE %s CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci"

-- A function to connect to the MySQL database.
function mysql:Connect(host, username, password, database, port, socket, flags)
	port = port or 3306;

	if (self.module == "mysqloo") then
		if (!istable(mysqloo)) then
			require("mysqloo");
		end;

		if (mysqloo) then
			if (self.connection and self.connection:ping()) then
				return;
			end;

			local clientFlag = flags or 0;

			if (!isstring(socket)) then
				self.connection = mysqloo.connect(host, username, password, database, port);
			else
				self.connection = mysqloo.connect(host, username, password, database, port, socket, clientFlag);
			end;

			self.connection.onConnected = function(connection)
		        local success, error_message = connection:setCharacterSet("utf8mb4")

		        if (!success) then
					ErrorNoHalt("Failed to set MySQL encoding!\n")
					ErrorNoHalt(error_message .. "\n")
				else
					self:RawQuery(string.format(UTF8MB4, database))
		        end

				mysql:OnConnected();
			end;

			self.connection.onConnectionFailed = function(database, errorText)
				mysql:OnConnectionFailed(errorText);
			end;

			self.connection:connect();

			timer.Create("mysql.KeepAlive", 300, 0, function()
				self.connection:ping();
			end);
		else
			ErrorNoHalt(string.format(MODULE_NOT_EXIST, self.module));
		end;
	elseif (self.module == "sqlite") then
		mysql:OnConnected();
	end;
end;

-- A function to query the MySQL database.
function mysql:RawQuery(query, callback, flags, ...)
	if (self.module == "mysqloo") then
		local queryObj = self.connection:query(query);

		queryObj:setOption(mysqloo.OPTION_NAMED_FIELDS);

		queryObj.onSuccess = function(queryObj, result)
			if (callback) then
				local bStatus, value = pcall(callback, result, true, tonumber(queryObj:lastInsert()));

				if (!bStatus) then
					error(string.format("[mysql] MySQL Callback Error!\n%s\n", value));
				end;
			end;
		end;

		queryObj.onError = function(queryObj, errorText)
			ErrorNoHalt(string.format("[mysql] MySQL Query Error!\nQuery: %s\n%s\n", query, errorText));
		end;

		queryObj:start();
	elseif (self.module == "sqlite") then
		local result = sql.Query(query);

		if (result == false) then
			error(string.format("[mysql] SQL Query Error!\nQuery: %s\n%s\n", query, sql.LastError()));
		else
			if (callback) then
				local bStatus, value = pcall(callback, result, true, tonumber(sql.QueryValue("SELECT last_insert_rowid()")));

				if (!bStatus) then
					error(string.format("[mysql] SQL Callback Error!\n%s\n", value));
				end;
			end;
		end;
	else
		ErrorNoHalt(string.format("[mysql] Unsupported module \"%s\"!\n", self.module));
	end;
end;

-- A function to add a query to the queue.
function mysql:Queue(queryString, callback)
	if (isstring(queryString)) then
		QueueTable[#QueueTable + 1] = {queryString, callback};
	end;
end;

-- A function to escape a string for MySQL.
function mysql:Escape(text)
	if (self.connection) then
		if (self.module == "mysqloo") then
			return self.connection:escape(text);
		end;
	else
		return sql.SQLStr(string.gsub(text, "\"", "\"\""), true);
	end;
end;

-- A function to disconnect from the MySQL database.
function mysql:Disconnect()
	if (self.connection) then
		if (self.module == "mysqloo") then
			self.connection:disconnect(true);
		end;
	end;
end;

function mysql:Think()
	if (#QueueTable > 0) then
		if (istable(QueueTable[1])) then
			local queueObj = QueueTable[1];
			local queryString = queueObj[1];
			local callback = queueObj[2];

			if (isstring(queryString)) then
				self:RawQuery(queryString, callback);
			end;

			table.remove(QueueTable, 1);
		end;
	end;
end;

-- A function to set the module that should be used.
function mysql:SetModule(moduleName)
	self.module = moduleName;
end;

-- Called when the database connects sucessfully.
function mysql:OnConnected()
	MsgC(Color(25, 235, 25), "[mysql] Connected to the database!\n");

	hook.Run("DatabaseConnected");
end;

-- Called when the database connection fails.
function mysql:OnConnectionFailed(errorText)
	ErrorNoHalt("[mysql] Unable to connect to the database!\n"..errorText.."\n");

	hook.Run("DatabaseConnectionFailed", errorText);
end;

-- A function to check whether or not the module is connected to a database.
function mysql:IsConnected()
	return self.module == "mysqloo" and (self.connection and self.connection:ping()) or self.module == "sqlite";
end;

return mysql;
