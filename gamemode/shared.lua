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
end

-- Include core framework files.
nut.util.include("core/cl_skin.lua")
nut.util.includeDir("core/libs/thirdparty")
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
	else
		-- Auto-reload support for faction pay timers.
		for index, faction in ipairs(nut.faction.indices) do
			for k, v in ipairs(team.GetPlayers(index)) do
				if (faction.pay and faction.pay > 0) then
					timer.Adjust("nutSalary"..v:UniqueID(), faction.payTime or 300, 0, function()
						local pay = hook.Run("GetSalaryAmount", v, faction) or faction.pay

						v:getChar():giveMoney(pay)
						v:notifyLocalized("salary", nut.currency.get(pay))
					end)
				else
					timer.Remove("nutSalary"..v:UniqueID())
				end
			end
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