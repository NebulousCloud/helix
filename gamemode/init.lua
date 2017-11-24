-- Include Helix content.
resource.AddWorkshop("207739713")

-- Include features from the Sandbox gamemode.
DeriveGamemode("sandbox")
-- Define a global shared table to store Helix information.
ix = ix or {util = {}, meta = {}}

-- Send the following files to players.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("core/sh_util.lua")
AddCSLuaFile("shared.lua")

-- Include utility functions, data storage functions, and then shared.lua
include("core/sh_util.lua")
include("core/sv_data.lua")
include("shared.lua")

-- Connect to the database using SQLite, mysqloo, or tmysql4.
timer.Simple(0, function()
	hook.Run("SetupDatabase")

	ix.db.Connect(function()
		-- Create the SQL tables if they do not exist.
		ix.db.LoadTables()
		ix.log.LoadTables()

		MsgC(Color(0, 255, 0), "Helix has connected to the database.\n")
		MsgC(Color(0, 255, 0), "Database Type: " .. ix.db.module .. ".\n")
	end)
end)

-- Resources that are required for players to download are here.
resource.AddFile("materials/helix/gui/vignette.png")
resource.AddFile("resource/fonts/fontello.ttf")

concommand.Add("ix_setowner", function(client, command, arguments)
	if (!IsValid(client)) then
		MsgC(Color(255, 0, 0), "** 'ix_setowner' has been deprecated in Helix 1.1\n")
		MsgC(Color(255, 0, 0), "** Instead, please install an admin mod and use that instead.\n")
	end
end)

cvars.AddChangeCallback( "sbox_persist", function( name, old, new )

	-- A timer in case someone tries to rapily change the convar, such as addons with "live typing" or whatever
	timer.Create( "sbox_persist_change_timer", 1, 1, function()
		hook.Run( "PersistenceSave", old )

		--game.CleanUpMap() -- Maybe this should be moved to PersistenceLoad?
		--seriously you just did this for 2 years? fuck off

		if ( new == "" ) then return end

		hook.Run( "PersistenceLoad", new )
	end )

end, "sbox_persist_load" )
