-- since it's really sensitive. localized.

local timeColor = Color(0, 255, 0)
local textColor = Color(255, 255, 255)

if SERVER then
	local serverLog = {}
	local autosavePerLines = 1000

	-- for later filter use.
	LOG_FILTER_DEVELOPER = 0
	LOG_FILTER_CRITICAL = 1
	LOG_FILTER_MAJOR = 2
	LOG_FILTER_ITEM = 3
	LOG_FILTER_CHAT = 4
	LOG_FILTER_NOSAVE = 5
	LOG_FILTER_CONCOMMAND = 6

	--[[
		Purpose: Add a line to the log.
	--]]
	function nut.util.AddLog(string, filter, consoleprint)
		if (consoleprint != false) then
			MsgC(timeColor, "[" .. os.date() .. "] ")
			MsgC(textColor, string .. "\n")
			
			for k, client in pairs(player.GetAll()) do
				if (client:IsAdmin() and client:GetInfoNum("nut_showlogs", 1) > 0) then
					netstream.Start(client, "nut_SendLogLine", string)
				end
			end
		end

		if (filter != LOG_FILTER_NOSAVE) then
			table.insert(serverLog, "[" .. os.date() .. "] " .. string)
		end

		if (#serverLog >= autosavePerLines) then
			nut.util.SaveLog()
		end
	end
	--[[
		Purpose: Get the current log
	--]]
	function nut.util.GetLog()
		return serverLog
	end

	--[[
		Purpose: Get a log.
	--]]
	function nut.util.SendLog(client)
		-- body
	end

	--[[
		Purpose: Save the log to the server.
	--]]
	function nut.util.SaveLog(autosave)
		/*
		-- for later use.
		local filename = string.Replace(os.date(),":","_")
		filename = string.Replace(filename,"/","_")
		file.CreateDir("nutscript/"..SCHEMA.uniqueID.."/logs")
		nut.util.WriteTable("logs/"..filename, serverLog, true)
		*/
		local string = ""
		for k, v in pairs(serverLog) do
			string = string .. v .. "\n"
		end
		local filename = string.Replace(os.date(),":","_")
		filename = string.Replace(filename,"/","_")
		filename = filename .. "_readable"
		file.CreateDir("nutscript/"..SCHEMA.uniqueID.."/logs")
		file.Write("nutscript/"..SCHEMA.uniqueID.."/logs/".. filename ..".txt", string)
		serverLog = {}
	end
	/*
		--[[
			Purpose: Load the log and send to the admin.
			Reserved for next feature.
		--]]
		function nut.util.LoadLog()
			-- body
		end
	*/

	hook.Add("PlayerSay", "nut_ChatLogging", function(player, text)
		if nut.config.savechat then
			nut.util.AddLog(Format("%s: %s", player:Name(), text), LOG_FILTER_CHAT, false)
		else
			nut.util.AddLog(Format("%s: %s", player:Name(), text), LOG_FILTER_NOSAVE, false)
		end
	end)

	hook.Add("ShutDown", "nut_SaveLog", function(player, text)
		nut.util.SaveLog()
	end)
else
	NUT_CVAR_SHOWLOGS = CreateClientConVar("nut_showlogs", "1", true, true)

	netstream.Hook("nut_SendLogLine", function(string)
		if (LocalPlayer():IsAdmin()) then
			MsgC(timeColor, "[" .. os.date() .. "] ")
			MsgC(textColor, string .. "\n")
		end
	end)
end