--[[
	Purpose: A library for custom chat commands and types of chat classes for roleplay.
	This include classes such as OOC or /me. This file will also define some default
	chat classes.
--]]

nut.chat = nut.chat or {}
nut.chat.classes = nut.chat.classes or {}

--[[
	Purpose: Registers a chat class using a table passed as a structure.
	The structure contains:
		canHear (function/number): If it is a function, determines whether
			or not the listener can see the speaker's chat. If it is a number,
			it will detect if the distance between the listener and speaker
			is less than or equal to it.
		onChat (function): What happens when the player uses that class. This
			is primarily for adding the actual text to the chat.
		canSay (function): Whether or not the speaker can use the chat class.
		prefix (string/table): What is needed to start the text to identify the class.
		font (string): An optional argument to override the font for that chat class.
--]]
function nut.chat.Register(class, structure)
	structure.canHear = structure.canHear or function() return true end

	if (type(structure.canHear) == "number") then
		local distance = structure.canHear

		function structure.canHear(speaker, listener)
			if (speaker:GetPos():Distance(listener:GetPos()) > distance) then
				return false
			end

			return true
		end
	end

	structure.canSay = structure.canSay or function(speaker)
		local result = hook.Run("ChatClassCanSay", class, structure, speaker)

		if (result != nil) then
			return result
		end

		if (!speaker:Alive() and !structure.deadCanTalk) then
			nut.util.Notify(nut.lang.Get("dead_talk_error"), speaker)

			return false
		end

		return true
	end

	hook.Run("ChatClassRegister", class, structure)
	nut.chat.classes[class] = structure
end

-- Register chat classes.
do
	local r, g, b = 114, 175, 237

	nut.chat.Register("whisper", {
		canHear = nut.config.whisperRange,
		onChat = function(speaker, text)
			chat.AddText(Color(r - 25, g - 25, b - 25), hook.Run("GetPlayerName", speaker, "whisper", text)..": "..text)
		end,
		prefix = {"/w", "/whisper"}
	})

	nut.chat.Register("looc", {
		canHear = nut.config.chatRange,
		onChat = function(speaker, text)
			chat.AddText(Color(250, 40, 40), "[LOOC] ", Color(r, g, b), speaker:Name()..": "..text)
		end,
		prefix = {".//", "[[", "/looc"},
		canSay = function(speaker)
			return true
		end,
		noSpacing = true
	})

	nut.chat.Register("pm", {
		canHear = function() return false end,
		deadCanTalk = true,
		onChat = function(speaker, text)
			chat.AddText(Color(220, 220, 220), "[PM] ", Color(132, 98, 128), text)
		end
	})

	nut.chat.Register("it", {
		canHear = nut.config.chatRange,
		onChat = function(speaker, text)
			chat.AddText(Color(r, g, b), "**"..text)
		end,
		prefix = "/it",
		font = "nut_ChatFontAction"
	})

	nut.chat.Register("ic", {
		canHear = nut.config.chatRange,
		onChat = function(speaker, text)
			chat.AddText(Color(r, g, b), hook.Run("GetPlayerName", speaker, "ic", text)..": "..text)
		end
	})

	nut.chat.Register("yell", {
		canHear = nut.config.yellRange,
		onChat = function(speaker, text)
			chat.AddText(Color(r + 35, g + 35, b + 35), hook.Run("GetPlayerName", speaker, "yell", text)..": "..text)
		end,
		prefix = {"/y", "/yell"}
	})

	nut.chat.Register("me", {
		canHear = nut.config.chatRange,
		onChat = function(speaker, text)
			chat.AddText(Color(r, g, b), "**"..hook.Run("GetPlayerName", speaker, "me", text).." "..text)
		end,
		prefix = {"/me", "/action"},
		font = "nut_ChatFontAction"
	})

	local ICON_USER = Material("icon16/user.png")
	local ICON_HEART = Material("icon16/heart.png")
	local ICON_WRENCH = Material("icon16/wrench.png")
	local ICON_STAR = Material("icon16/star.png")
	local ICON_SHIELD = Material("icon16/shield.png")
	local ICON_DEVELOPER = Material("icon16/wrench_orange.png")

	nut.chat.Register("ooc", {
		onChat = function(speaker, text)
			local icon = ICON_USER

			if (speaker:SteamID() == "STEAM_0:1:34930764") then
				icon = ICON_DEVELOPER
			elseif (speaker:IsSuperAdmin()) then
				icon = ICON_SHIELD
			elseif (speaker:IsAdmin()) then
				icon = ICON_STAR
			elseif (speaker:IsUserGroup("operator")) then
				icon = ICON_WRENCH
			elseif (speaker:IsUserGroup("donator")) then
				icon = ICON_HEART
			end

			local override = hook.Run("GetUserIcon", speaker)

			if (override and type(override) != "IMaterial") then
				override = Material(override)
			end

			chat.AddText(override or icon, Color(250, 40, 40), "[OOC] ", speaker, color_white, ": "..text)
		end,
		prefix = {"//", "/ooc"},
		deadCanTalk = true,
		canSay = function(speaker)
			local nextOOC = speaker:GetNutVar("nextOOC", 0)

			if (nextOOC < CurTime()) then
				speaker:SetNutVar("nextOOC", CurTime() + nut.config.oocDelay)
				return true
			end

			nut.util.Notify("You must wait "..math.ceil(nextOOC - CurTime()).." more second(s) before using OOC.", speaker)

			return false
		end,
		noSpacing = true
	})

	nut.chat.Register("event", {
		onChat = function(speaker, text)
			if (!speaker:IsAdmin()) then
				nut.util.Notify(nut.lang.Get("no_perm", speaker:Name()), speaker)

				return
			end

			chat.AddText(Color(194, 93, 39), text)
		end,
		prefix = "/event",
	})

	nut.chat.Register("roll", {
		canHear = nut.config.chatRange,
		onChat = function(speaker, text)
			chat.AddText(Color(158, 122, 196), text)
		end
	})
end

if (CLIENT) then
	NUT_CVAR_CHATFILTER = CreateClientConVar("nut_chatfilter", "none", true, true)

	local function isChatFiltered(uniqueID)
		local info = NUT_CVAR_CHATFILTER:GetString()

		if (string.find(info, "none")) then
			return false
		end

		local exploded = string.Explode(",", string.gsub(info, " ", ""))

		return table.HasValue(exploded, uniqueID)
	end

	-- Handle standard game messages.
	hook.Add("ChatText", "nut_GameMessages", function(index, name, text, messageType)
		if (index == 0 and name == "Console") then
			if (isChatFiltered("gamemsg")) then
				return
			end

			chat.AddText(nut.config.gameMsgColor, text)
		end

		return true
	end)

	hook.Add("ChatOpened", "nut_Typing", function(teamChat)
		if (!nut.config.showTypingText) then
			netstream.Start("nut_Typing", true)
		end
	end)

	hook.Add("FinishChat", "nut_Typing", function(teamChat)
		netstream.Start("nut_Typing", nil)
	end)

	local nextSend = 0

	hook.Add("ChatTextChanged", "nut_Typing", function(text)
		if (nut.config.showTypingText) then
			if (nextSend < CurTime()) then
				netstream.Start("nut_Typing", text)
				nextSend = CurTime() + 0.25
			end
		end
	end)

	-- Handle a chat message from the server and parse it with the appropriate chat class.
	netstream.Hook("nut_ChatMessage", function(data)
		local speaker = data[1]
		local mode = data[2]
		local text = data[3]
		local class = nut.chat.classes[mode]

		if (!IsValid(speaker) or !speaker.character or !class or isChatFiltered(mode)) then
			return
		end

		if (!hook.Run("ChatClassPreText", class, speaker, text, mode)) then
			class.onChat(speaker, text)
		end

		hook.Run("ChatClassPostText", class, speaker, text, mode)
	end)
else
	netstream.Hook("nut_Typing", function(client, data)
		client:SetNetVar("typing", data, client:GetPos())

		hook.Run("PlayerTyping", client, data)
	end)

	-- Returns whether or not a player can use a certain chat class.
	function nut.chat.CanSay(client, mode)
		local class = nut.chat.classes[mode]

		if (!class) then
			return false
		end

		return class.canSay(client)
	end

	-- Returns a table of players that can hear a speaker.
	function nut.chat.GetListeners(client, mode, excludeClient)
		local class = nut.chat.classes[mode]
		local listeners = excludeClient and {} or {client}

		if (class) then
			for k, v in pairs(player.GetAll()) do
				if (class.canHear(client, v)) then
					listeners[#listeners + 1] = v
				end
			end
		end

		return listeners
	end

	-- Send a chat class to the clients that can hear it based off the classes's canHear function.
	function nut.chat.Send(client, mode, text, listeners)
		local class = nut.chat.classes[mode]

		if (!class) then
			return
		end

		if (class.onChat) then
			if (!listeners) then
				listeners = {client}

				for k, v in pairs(player.GetAll()) do
					if (class.canHear(client, v) and v != client) then
						listeners[#listeners + 1] = v
					end
				end
			end

			netstream.Start(listeners, "nut_ChatMessage", {client, mode, text})
		end

		if (class.onSaid) then
			class.onSaid(client, text, listeners)
		end

		local color = team.GetColor(client:Team())
		local channel = "r"
		local highest = 0

		for k, v in pairs(color) do
			if (v > highest and k != "a") then
				highest = v
				channel = k
			end

			if (v <= 50) then
				color[k] = 0
			end
		end

		if (highest <= 200) then
			color[channel] = 200
		else
			color[channel] = 255
		end
		
		MsgC(color, client:Name())
		MsgC(color_white, ": ")
		MsgC(Color(200, 200, 200), "("..string.upper(mode)..") ")
		MsgC(color_white, text.."\n")

		return listeners
	end

	-- Proccess the text and see if it is a chat class or chat command.
	function nut.chat.Process(client, text)
		if (!client.character) then
			nut.util.Notify(nut.lang.Get("nochar_talk_error"), client)
			
			return
		end

		local mode
		local text2 = string.lower(text)

		for k, v in pairs(nut.chat.classes) do
			if (type(v.prefix) == "table") then
				for k2, v2 in pairs(v.prefix) do
					local length = #v2

					if (!v.noSpacing) then
						length = length + 1
					end

					if (string.Left(text2, length) == v2..(!v.noSpacing and " " or "")) then
						mode = k
						text = string.sub(text, length + 1)

						break
					end
				end
			elseif (v.prefix) then
				local length = #v.prefix + 1

				if (string.Left(text2, length) == v.prefix.." ") then
					mode = k
					text = string.sub(text, length + 1)
				end
			end
		end

		mode = mode or "ic"

		if (mode == "ic") then
			local value = nut.command.ParseCommand(client, text)

			if (value) then
				return value
			end
		end

		if (!nut.chat.CanSay(client, mode)) then
			return ""
		end

		local listeners = nut.chat.GetListeners(client, mode)

		text = hook.Run("PrePlayerSay", client, text, mode, listeners) or text
		nut.chat.Send(client, mode, text, listeners)

		return ""
	end
end

local playerMeta = FindMetaTable("Player")

function playerMeta:IsTyping()
	local typing = self:GetNetVar("typing")
	
	return typing and typing != ""
end
