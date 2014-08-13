DeriveGamemode("sandbox")

GM.Name = "NutScript 1.1"
GM.Author = "Chessnut"
GM.Website = "http://chessnut.info"

nut.util.include("core/cl_skin.lua")
nut.util.includeDir("core/libs/external")
nut.util.include("core/sh_config.lua")
nut.util.includeDir("core/libs")
nut.util.includeDir("core/derma")
nut.util.includeDir("core/hooks")

function GM:Initialize()
	nut.plugin.initialize()
	nut.config.load()
end

function GM:OnReloaded()
	self:Initialize()

	if (CLIENT) then
		hook.Run("LoadFonts", nut.config.get("font", "arial"))
	end
end

nut.lang.loadFromDir("nutscript/gamemode/languages")
nut.faction.loadFromDir("nutscript/gamemode/factions")
nut.item.loadFromDir("nutscript/gamemode/items")