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
	-- Restore the configurations from earlier if applicable.
	ix.config.Load()
end

IX_RELOADED = false

-- Called when a file has been modified.
function GM:OnReloaded()
	if (!IX_RELOADED) then
		-- Load all of the Helix plugins.
		ix.plugin.Initialize()
		-- Restore the configurations from earlier if applicable.
		ix.config.Load()

		IX_RELOADED = true
	end

	-- Reload the default fonts.
	if (CLIENT) then
		hook.Run("LoadFonts", ix.config.Get("font"))

		-- Reload the scoreboard.
		if (IsValid(ix.gui.score)) then
			ix.gui.score:Remove()
		end
	else
		-- Auto-reload support for faction pay timers.
		for index, faction in ipairs(ix.faction.indices) do
			for k, v in ipairs(team.GetPlayers(index)) do
				if (faction.pay and faction.pay > 0) then
					timer.Adjust("ixSalary"..v:UniqueID(), faction.payTime or 300, 0)
				else
					timer.Remove("ixSalary"..v:UniqueID())
				end
			end
		end
	end
end

-- Include default Helix chat commands.
ix.util.Include("core/sh_commands.lua")

if (SERVER and game.IsDedicated()) then
	concommand.Remove("gm_save")
	
	concommand.Add("gm_save", function(client, command, arguments)
		client:ChatPrint("You are not allowed to do that, administrators have been notified.")

		if ((client.ixNextWarn or 0) < CurTime()) then
			local message = client:Name().." ["..client:SteamID().."] has possibly attempted to crash the server with 'gm_save'"

			for k, v in ipairs(player.GetAll()) do
				if (v:IsAdmin()) then
					v:ChatPrint(message)
				end
			end

			MsgC(Color(255, 255, 0), message.."\n")
			client.ixNextWarn = CurTime() + 60
		end
	end)
end

-- add entries for c_viewmodels that aren't set by default
player_manager.AddValidModel("group02male01", "models/humans/group02/male_01.mdl")
player_manager.AddValidHands("group02male01", "models/weapons/c_arms_citizen.mdl", 1, "0000000")
player_manager.AddValidModel("group02male03", "models/humans/group02/male_03.mdl")
player_manager.AddValidHands("group02male03", "models/weapons/c_arms_citizen.mdl", 1, "0000000")
player_manager.AddValidModel("group01female07", "models/player/group01/female_07.mdl")
player_manager.AddValidHands("group01female07", "models/weapons/c_arms_citizen.mdl", 1, "0000000")
player_manager.AddValidModel("group02female03", "models/player/group01/female_03.mdl")
player_manager.AddValidHands("group02female03", "models/weapons/c_arms_citizen.mdl", 1, "0000000")
