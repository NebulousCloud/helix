
ix.db = ix.db or {}
ix.util.Include("helix/gamemode/config/sv_database.lua")

function ix.db.Connect()
	local dbmodule = ix.db.module
	local hostname = ix.db.hostname
	local username = ix.db.username
	local password = ix.db.password
	local database = ix.db.database
	local port = ix.db.port

	mysql:SetModule(dbmodule)
	mysql:Connect(hostname, username, password, database, port)
end

function ix.db.LoadTables()
	local query

	query = mysql:Create("ix_characters")
		query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
		query:Create("name", "VARCHAR(70) NOT NULL")
		query:Create("description", "TEXT NOT NULL")
		query:Create("model", "VARCHAR(160) NOT NULL")
		query:Create("attributes", "VARCHAR(500) DEFAULT NULL")
		query:Create("schema", "VARCHAR(24) NOT NULL")
		query:Create("create_time", "INT(11) UNSIGNED NOT NULL")
		query:Create("last_join_time", "INT(4) DEFAULT NULL")
		query:Create("steamid", "BIGINT(20) UNSIGNED NOT NULL")
		query:Create("data", "LONGTEXT")
		query:Create("money", "INT(11) UNSIGNED DEFAULT NULL")
		query:Create("faction", "VARCHAR(50) NOT NULL")
		query:PrimaryKey("id")
	query:Execute()


	query = mysql:Create("ix_inventories")
		query:Create("inventory_id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
		query:Create("character_id", "INT(11) UNSIGNED NOT NULL")
		query:Create("inventory_type", "VARCHAR(24) DEFAULT NULL")
		query:PrimaryKey("inventory_id")
	query:Execute()

	query = mysql:Create("ix_items")
		query:Create("item_id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
		query:Create("inventory_id", "INT(11) UNSIGNED NOT NULL")
		query:Create("unique_id", "VARCHAR(60) NOT NULL")
		query:Create("data", "VARCHAR(500) DEFAULT NULL")
		query:Create("x", "SMALLINT(4) NOT NULL")
		query:Create("y", "SMALLINT(4) NOT NULL")
		query:PrimaryKey("item_id")
	query:Execute()

	query = mysql:Create("ix_players")
		query:Create("steamid", "BIGINT(20) NOT NULL")
		query:Create("steam_name", "VARCHAR(32) NOT NULL")
		query:Create("play_time", "INT(11) UNSIGNED DEFAULT NULL")
		query:Create("address", "VARCHAR(15) DEFAULT NULL")
		query:Create("last_join_time", "INT(11) UNSIGNED DEFAULT NULL")
		query:Create("data", "TEXT")
		query:PrimaryKey("steamid")
	query:Execute()
end

function ix.db.WipeTables()
	local query

	query = mysql:Drop("ix_characters")
	query:Execute()

	query = mysql:Drop("ix_inventories")
	query:Execute()

	query = mysql:Drop("ix_items")
	query:Execute()

	query = mysql:Drop("ix_players")
	query:Execute()

	ix.db.LoadTables()
end

local resetCalled = 0
concommand.Add("ix_recreatedb", function(client, cmd, arguments)
	-- this command can be run in RCON or SERVER CONSOLE
	if (!IsValid(client)) then
		if (resetCalled < RealTime()) then
			resetCalled = RealTime() + 3

			MsgC(Color(255, 0, 0), "[Helix] TO CONFIRM DATABASE RESET, RUN 'ix_recreatedb' AGAIN in 3 SECONDS.\n")
		else
			resetCalled = 0

			MsgC(Color(255, 0, 0), "[Helix] DATABASE WIPE IN PROGRESS.\n")

			hook.Run("OnWipeTables")
			ix.db.WipeTables()
		end
	end
end)
