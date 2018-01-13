
-- Include Helix content.
resource.AddWorkshop("1267236756")

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
	ix.db.Connect()
end)

-- Resources that are required for players to download are here.
resource.AddFile("materials/helix/gui/vignette.png")
resource.AddFile("resource/fonts/fontello.ttf")

cvars.AddChangeCallback("sbox_persist", function(name, old, new)
	-- A timer in case someone tries to rapily change the convar, such as addons with "live typing" or whatever
	timer.Create("sbox_persist_change_timer", 1, 1, function()
		hook.Run("PersistenceSave", old)

		if (new == "") then
			return
		end

		hook.Run("PersistenceLoad", new)
	end)
end, "sbox_persist_load")
