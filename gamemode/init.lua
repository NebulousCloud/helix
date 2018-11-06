
-- Include Helix content.
resource.AddWorkshop("1267236756")

-- Include features from the Sandbox gamemode.
DeriveGamemode("sandbox")
-- Define a global shared table to store Helix information.
ix = ix or {util = {}, meta = {}}

-- Send the following files to players.
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("core/sh_util.lua")
AddCSLuaFile("core/sh_data.lua")
AddCSLuaFile("shared.lua")

-- Include utility functions, data storage functions, and then shared.lua
include("core/sh_util.lua")
include("core/sh_data.lua")
include("shared.lua")

-- Resources that are required for players to download are here.
resource.AddFile("materials/helix/gui/vignette.png")
resource.AddFile("resource/fonts/fontello.ttf")
resource.AddFile("sound/helix/intro.mp3")
resource.AddFile("sound/helix/ui/press.wav")
resource.AddFile("sound/helix/ui/rollover.wav")
resource.AddFile("sound/helix/ui/whoosh1.wav")
resource.AddFile("sound/helix/ui/whoosh2.wav")
resource.AddFile("sound/helix/ui/whoosh3.wav")
resource.AddFile("sound/helix/ui/whoosh4.wav")
resource.AddFile("sound/helix/ui/whoosh5.wav")
resource.AddFile("sound/helix/ui/whoosh6.wav")

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
