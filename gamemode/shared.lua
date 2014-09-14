-- Define gamemode information.
GM.Name = "NutScript 1.1"
GM.Author = "Chessnut"
GM.Website = "http://chessnut.info"

-- Fix for client:SteamID64() returning nil when in single-player.
do
	local playerMeta = FindMetaTable("Player")
	playerMeta.nutSteamID64 = playerMeta.nutSteamID64 or playerMeta.SteamID64

	-- Overwrite the normal SteamID64 method.
	function playerMeta:SteamID64()
		-- Return 0 if the SteamID64 could not be found.
		return self:nutSteamID64() or 0
	end
end

-- Include core framework files.
nut.util.include("core/cl_skin.lua")
nut.util.includeDir("core/libs/external")
nut.util.include("core/sh_config.lua")
nut.util.includeDir("core/libs")
nut.util.includeDir("core/derma")
nut.util.includeDir("core/hooks")

-- Include language and default base items.
nut.lang.loadFromDir("nutscript/gamemode/languages")
nut.item.loadFromDir("nutscript/gamemode/items")

-- Called after the gamemode has loaded.
function GM:Initialize()
	-- Load all of the NutScript plugins.
	nut.plugin.initialize()
	-- Restore the configurations from earlier if applicable.
	nut.config.load()
end

-- Called when a file has been modified.
function GM:OnReloaded()
	-- Initialize the plugin and configurations.
	self:Initialize()

	-- Reload the default fonts.
	if (CLIENT) then
		hook.Run("LoadFonts", nut.config.get("font"))
	end
end

-- Include default NutScript chat commands.
nut.util.include("core/sh_commands.lua")