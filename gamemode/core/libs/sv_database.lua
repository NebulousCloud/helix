
ix.db = ix.db or {
	schema = {},
	schemaQueue = {},
	type = {
		-- TODO: more specific types, lengths, and defaults
		-- i.e INT(11) UNSIGNED, SMALLINT(4), LONGTEXT, VARCHAR(350), NOT NULL, DEFAULT NULL, etc
		[ix.type.string] = "VARCHAR(255)",
		[ix.type.text] = "TEXT",
		[ix.type.number] = "INT(11)",
		[ix.type.steamid] = "VARCHAR(20)",
		[ix.type.bool] = "TINYINT(1)"
	}
}

ix.db.config = ix.config.server.database or {}

function ix.db.Connect()
	ix.db.config.adapter = ix.db.config.adapter or "sqlite"

	local dbmodule = ix.db.config.adapter
	local hostname = ix.db.config.hostname
	local username = ix.db.config.username
	local password = ix.db.config.password
	local database = ix.db.config.database
	local port = ix.db.config.port

	mysql:SetModule(dbmodule)
	mysql:Connect(hostname, username, password, database, port)
end

function ix.db.AddToSchema(schemaType, field, fieldType)
	if (!ix.db.type[fieldType]) then
		error(string.format("attempted to add field in schema with invalid type '%s'", fieldType))
		return
	end

	if (!mysql:IsConnected() or !ix.db.schema[schemaType]) then
		ix.db.schemaQueue[#ix.db.schemaQueue + 1] = {schemaType, field, fieldType}
		return
	end

	ix.db.InsertSchema(schemaType, field, fieldType)
end

-- this is only ever used internally
function ix.db.InsertSchema(schemaType, field, fieldType)
	local schema = ix.db.schema[schemaType]

	if (!schema) then
		error(string.format("attempted to insert into schema with invalid schema type '%s'", schemaType))
		return
	end

	if (!schema[field]) then
		schema[field] = true

		local query = mysql:Update("ix_schema")
			query:Update("columns", util.TableToJSON(schema))
		query:Execute()

		query = mysql:Alter(schemaType)
			query:Add(field, ix.db.type[fieldType])
		query:Execute()
	end
end

function ix.db.LoadTables()
	local query

	query = mysql:Create("ix_schema")
		query:Create("table", "VARCHAR(64) NOT NULL")
		query:Create("columns", "TEXT NOT NULL")
		query:PrimaryKey("table")
	query:Execute()

	-- table structure will be populated with more fields when vars
	-- are registered using ix.char.RegisterVar
	query = mysql:Create("ix_characters")
		query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
		query:PrimaryKey("id")
	query:Execute()

	query = mysql:Create("ix_inventories")
		query:Create("inventory_id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
		query:Create("character_id", "INT(11) UNSIGNED NOT NULL")
		query:Create("inventory_type", "VARCHAR(150) DEFAULT NULL")
		query:PrimaryKey("inventory_id")
	query:Execute()

	query = mysql:Create("ix_items")
		query:Create("item_id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
		query:Create("inventory_id", "INT(11) UNSIGNED NOT NULL")
		query:Create("unique_id", "VARCHAR(60) NOT NULL")
		query:Create("character_id", "INT(11) UNSIGNED DEFAULT NULL")
		query:Create("player_id", "VARCHAR(20) DEFAULT NULL")
		query:Create("data", "TEXT DEFAULT NULL")
		query:Create("x", "SMALLINT(4) NOT NULL")
		query:Create("y", "SMALLINT(4) NOT NULL")
		query:PrimaryKey("item_id")
	query:Execute()

	query = mysql:Create("ix_players")
		query:Create("steamid", "VARCHAR(20) NOT NULL")
		query:Create("steam_name", "VARCHAR(32) NOT NULL")
		query:Create("play_time", "INT(11) UNSIGNED DEFAULT NULL")
		query:Create("address", "VARCHAR(15) DEFAULT NULL")
		query:Create("last_join_time", "INT(11) UNSIGNED DEFAULT NULL")
		query:Create("data", "TEXT")
		query:PrimaryKey("steamid")
	query:Execute()

	-- populate schema table if rows don't exist
	query = mysql:InsertIgnore("ix_schema")
		query:Insert("table", "ix_characters")
		query:Insert("columns", util.TableToJSON({}))
	query:Execute()

	-- load schema from database
	query = mysql:Select("ix_schema")
		query:Callback(function(result)
			if (!istable(result)) then
				return
			end

			for _, v in pairs(result) do
				ix.db.schema[v.table] = util.JSONToTable(v.columns)
			end

			-- update schema if needed
			for i = 1, #ix.db.schemaQueue do
				local entry = ix.db.schemaQueue[i]
				ix.db.InsertSchema(entry[1], entry[2], entry[3])
			end
		end)
	query:Execute()
end

function ix.db.WipeTables(callback)
	local query

	query = mysql:Drop("ix_schema")
	query:Execute()

	query = mysql:Drop("ix_characters")
	query:Execute()

	query = mysql:Drop("ix_inventories")
	query:Execute()

	query = mysql:Drop("ix_items")
	query:Execute()

	query = mysql:Drop("ix_players")
		query:Callback(callback)
	query:Execute()
end

hook.Add("InitPostEntity", "ixDatabaseConnect", function()
	-- Connect to the database using SQLite, mysqoo, or tmysql4.
	ix.db.Connect()
end)

local resetCalled = 0

concommand.Add("ix_wipedb", function(client, cmd, arguments)
	-- can only be ran through the server's console
	if (!IsValid(client)) then
		if (resetCalled < RealTime()) then
			resetCalled = RealTime() + 3

			MsgC(Color(255, 0, 0),
				"[Helix] WIPING THE DATABASE WILL PERMENANTLY REMOVE ALL PLAYER, CHARACTER, ITEM, AND INVENTORY DATA.\n")
			MsgC(Color(255, 0, 0), "[Helix] THE SERVER WILL RESTART TO APPLY THESE CHANGES WHEN COMPLETED.\n")
			MsgC(Color(255, 0, 0), "[Helix] TO CONFIRM DATABASE RESET, RUN 'ix_wipedb' AGAIN WITHIN 3 SECONDS.\n")
		else
			resetCalled = 0
			MsgC(Color(255, 0, 0), "[Helix] DATABASE WIPE IN PROGRESS...\n")

			hook.Run("OnWipeTables")
			ix.db.WipeTables(function()
				MsgC(Color(255, 255, 0), "[Helix] DATABASE WIPE COMPLETED!\n")
				RunConsoleCommand("changelevel", game.GetMap())
			end)
		end
	end
end)
