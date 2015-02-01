--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

-- Define gamemode information.
GM.Name = "NutScript 1.1"
GM.Author = "Chessnut and Black Tea"
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

	NutTranslateModel = NutTranslateModel or player_manager.TranslateToPlayerModelName

	function player_manager.TranslateToPlayerModelName(model)
		model = model:lower():gsub("\\", "/")
		local result = NutTranslateModel(model)

		if (result == "kleiner" and !model:find("kleiner")) then
			local model2 = model:gsub("models/", "models/player/")
			result = NutTranslateModel(model2)

			if (result != "kleiner") then
				return result
			end

			model2 = model:gsub("models/humans", "models/player")
			result = NutTranslateModel(model2)

			if (result != "kleiner") then
				return result
			end

			model2 = model:gsub("models/zombie/", "models/player/zombie_")
			result = NutTranslateModel(model2)

			if (result != "kleiner") then
				return result
			end
		end

		return result
	end

	local entityMeta = FindMetaTable("Entity")

	-- Developer branch stuff
	if (VERSION <= 140714 and 
		!entityMeta.GetSubMaterial and
		!entityMeta.SetSubMaterial) then
		ErrorNoHalt("Warning! Some features may not work completely since you are not using the developer branch of Garry's Mod.\n")

		entityMeta.GetSubMaterial = function() end
		entityMeta.SetSubMaterial = function() end

		--[[---------------------------------------------------------
		   Name: string.PatternSafe( string )
		   Desc: Takes a string and escapes it for insertion in to a Lua pattern
		-----------------------------------------------------------]]
		local pattern_escape_replacements = {
			["("] = "%(",
			[")"] = "%)",
			["."] = "%.",
			["%"] = "%%",
			["+"] = "%+",
			["-"] = "%-",
			["*"] = "%*",
			["?"] = "%?",
			["["] = "%[",
			["]"] = "%]",
			["^"] = "%^",
			["$"] = "%$",
			["\0"] = "%z"
		}

		function string.PatternSafe( str )

			return ( str:gsub( ".", pattern_escape_replacements ) )

		end
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

	if (SERVER and hook.Run("ShouldCleanDataItems") != false) then
		nut.db.query("DELETE FROM nut_items WHERE _invID = 0")
	end
end

-- Called when a file has been modified.
function GM:OnReloaded()
	-- Load all of the NutScript plugins.
	nut.plugin.initialize()
	-- Restore the configurations from earlier if applicable.
	nut.config.load()

	-- Reload the default fonts.
	if (CLIENT) then
		hook.Run("LoadFonts", nut.config.get("font"))

		-- Reload the scoreboard.
		if (IsValid(nut.gui.score)) then
			nut.gui.score:Remove()
		end
	end
end

-- Include default NutScript chat commands.
nut.util.include("core/sh_commands.lua")

if (SERVER and game.IsDedicated()) then
	concommand.Remove("gm_save")
	
	concommand.Add("gm_save", function(client, command, arguments)
		client:ChatPrint("You are not allowed to do that, administrators have been notified.")

		if ((client.nutNextWarn or 0) < CurTime()) then
			local message = client:Name().." ["..client:SteamID().."] has possibly attempted to crash the server with 'gm_save'"

			for k, v in ipairs(player.GetAll()) do
				if (v:IsAdmin()) then
					v:ChatPrint(message)
				end
			end

			MsgC(Color(255, 255, 0), message.."\n")
			client.nutNextWarn = CurTime() + 60
		end
	end)
end