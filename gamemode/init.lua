--[[
	Purpose: The framework needs to define this so the schemas can reference
	the framework without GM.BaseClass since it the baseclass is not defined in time.
--]]

-- Define this so the SCHEMA knows what the baseclass is, since self.BaseClass isn't
-- set in time.
nut = nut or GM

-- Needed includes.
include("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

-- Switch this to false or set version.txt to no-check
local shouldCheckVersion = true

if (!shouldCheckVersion) then
	return
end

local function checkVersion()
	http.Fetch("https://raw.github.com/Chessnut/NutScript/master/version.txt", function(body)
		local version = file.Read("gamemodes/"..nut.FolderName.."/version.txt", "GAME")

		if (version and version != "" and version != "no-check") then
			if (body != version) then
				MsgC(Color(255, 0, 255), "You're running an older version of NutScript!\n")

				timer.Create("nut_VersionNotify", 300, 0, function()
					MsgC(Color(255, 0, 255), "You're running an older version of NutScript!\n")
				end)
			else
				timer.Remove("nut_VersionNotify")
			end
		end
	end)
end

timer.Create("nut_CheckVersion", 900, 0, function()
	checkVersion()
end)

timer.Simple(5, function()
	checkVersion()
end)