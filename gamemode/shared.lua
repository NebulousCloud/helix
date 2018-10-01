
--- Top-level library containing all Helix libraries. A large majority of the framework is split into respective libraries that
-- reside within `ix`.
-- @module ix

--- A table of variable types that are used throughout the framework. It represents types as a table with the keys being the
-- name of the type, and the values being some number value. **You should never directly use these number values!** Using the
-- values from this table will ensure backwards compatibility if the values in this table change.
--
-- This table also contains the numerical values of the types as keys. This means that if you need to check if a type exists, or
-- if you need to get the name of a type, you can do a table lookup with a numerical value. Note that special types are not
-- included since they are not real types that can be compared with.
-- 	print(ix.type[2] != nil)
-- 	> true
--
-- 	print(ix.type[ix.type.string])
-- 	> "string"
-- @shared
-- @field string A regular string. In the case of `ix.command.Add`, this represents one word.
-- @field text A regular string. In the case of `ix.command.Add`, this represents all words concatenated into a string.
-- @field number Any number.
-- @field player Any player that matches the given query string in `ix.util.FindPlayer`.
-- @field steamid A string that matches the Steam ID format of `STEAM_X:X:XXXXXXXX`.
-- @field character Any player's character that matches the given query string in `ix.util.FindPlayer`.
-- @field bool A string representation of a bool - `false` and `0` will return `false`, anything else will return `true`.
-- @field color A color represented by its red/green/blue/alpha values.
-- @field vector A 3D vector represented by its x/y/z values.
-- @field optional This is a special type that can be bitwise OR'd with any other type to make it optional. Currently only
-- supported in `ix.command.Add`.
-- @field array This is a special type that can be bitwise OR'd with any other type to make it an array of that type. Currently
-- only supported in `ix.option.Add`.
-- @see ix.command.Add
-- @see ix.option.Add
ix.type = ix.type or {
	[2] = "string",
	[4] = "text",
	[8] = "number",
	[16] = "player",
	[32] = "steamid",
	[64] = "character",
	[128] = "bool",
	[1024] = "color",
	[2048] = "vector",

	string = 2,
	text = 4,
	number = 8,
	player = 16,
	steamid = 32,
	character = 64,
	bool = 128,
	color = 1024,
	vector = 2048,

	optional = 256,
	array = 512
}

-- Define gamemode information.
GM.Name = "Helix 1.2"
GM.Author = "nebulous.cloud"
GM.Website = "https://nebulous.cloud"

-- Fix for client:SteamID64() returning nil when in single-player.
do
	local playerMeta = FindMetaTable("Player")
	playerMeta.ixSteamID64 = playerMeta.ixSteamID64 or playerMeta.SteamID64

	-- Overwrite the normal SteamID64 method.
	function playerMeta:SteamID64()
		-- Return 0 if the SteamID64 could not be found.
		return self:ixSteamID64() or 0
	end

	-- luacheck: globals player_manager
	player_manager.ixTranslateModel = player_manager.ixTranslateModel or player_manager.TranslateToPlayerModelName

	function player_manager.TranslateToPlayerModelName(model)
		model = model:lower():gsub("\\", "/")
		local result = player_manager.ixTranslateModel(model)

		if (result == "kleiner" and !model:find("kleiner")) then
			local model2 = model:gsub("models/", "models/player/")
			result = player_manager.ixTranslateModel(model2)

			if (result != "kleiner") then
				return result
			end

			model2 = model:gsub("models/humans", "models/player")
			result = player_manager.ixTranslateModel(model2)

			if (result != "kleiner") then
				return result
			end

			model2 = model:gsub("models/zombie/", "models/player/zombie_")
			result = player_manager.ixTranslateModel(model2)

			if (result != "kleiner") then
				return result
			end
		end

		return result
	end
end

-- Include core framework files.
ix.util.Include("core/cl_skin.lua")
ix.util.IncludeDir("core/libs/thirdparty")
ix.util.Include("core/sh_config.lua")
ix.util.IncludeDir("core/libs")
ix.util.IncludeDir("core/derma")
ix.util.IncludeDir("core/hooks")

-- Include language and default base items.
ix.lang.LoadFromDir("helix/gamemode/languages")
ix.item.LoadFromDir("helix/gamemode/items")

-- Called after the gamemode has loaded.
function GM:Initialize()
	-- Load all of the Helix plugins.
	ix.plugin.Initialize()
	-- Restore client options
	ix.option.Load()
	-- Restore the configurations from earlier if applicable.
	ix.config.Load()
end

-- luacheck: globals IX_RELOADED
IX_RELOADED = false

-- Called when a file has been modified.
function GM:OnReloaded()
	-- Reload the default fonts.
	if (CLIENT) then
		hook.Run("LoadFonts", ix.config.Get("font"), ix.config.Get("genericFont"))

		-- Reload the scoreboard.
		if (IsValid(ix.gui.score)) then
			ix.gui.score:Remove()
		end
	else
		-- Reconnect the database if needed.
		ix.db.Connect()
		-- Auto-reload support for faction pay timers.
		for index, faction in ipairs(ix.faction.indices) do
			for _, v in ipairs(team.GetPlayers(index)) do
				if (faction.pay and faction.pay > 0) then
					timer.Adjust("ixSalary"..v:UniqueID(), faction.payTime or 300, 0)
				else
					timer.Remove("ixSalary"..v:UniqueID())
				end
			end
		end
	end

	if (!IX_RELOADED) then
		-- Load all of the Helix plugins.
		ix.plugin.Initialize()
		-- Restore the configurations from earlier if applicable.
		ix.config.Load()
		-- Restore client options
		ix.option.Load()

		IX_RELOADED = true
	end
end

-- Include default Helix chat commands.
ix.util.Include("core/sh_commands.lua")
if gmod == true then
	fart()

-- add entries for c_viewmodels that aren't set by default
player_manager.AddValidModel("group02male01", "models/humans/group02/male_01.mdl")
player_manager.AddValidHands("group02male01", "models/weapons/c_arms_citizen.mdl", 1, "0000000")
player_manager.AddValidModel("group02male03", "models/humans/group02/male_03.mdl")
player_manager.AddValidHands("group02male03", "models/weapons/c_arms_citizen.mdl", 1, "0000000")
player_manager.AddValidModel("group01female07", "models/player/group01/female_07.mdl")
player_manager.AddValidHands("group01female07", "models/weapons/c_arms_citizen.mdl", 1, "0000000")
player_manager.AddValidModel("group02female03", "models/player/group01/female_03.mdl")
player_manager.AddValidHands("group02female03", "models/weapons/c_arms_citizen.mdl", 1, "0000000")
