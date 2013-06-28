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

	structure.onChat = structure.onChat or function(speaker, text)
		chat.AddText(speaker, Color(255, 255, 255), ": "..text)
	end
	structure.canSay = structure.canSay or function(speaker)
		local result = nut.schema.Call("ChatClassCanSay", class, structure, speaker)

		if (result != nil) then
			return result
		end

		if (!speaker:Alive()) then
			speaker:ChatPrint(nut.lang.Get("dead_talk_error"))

			return false
		end

		return true
	end

	nut.schema.Call("ChatClassRegister", class, structure)
	nut.chat.classes[class] = structure
end

-- Register chat classes.
do
	nut.chat.Register("whisper", {
		canHear = nut.config.whisperRange,
		onChat = function(speaker, text)
			chat.AddText(Color(149, 187, 212), speaker:Name()..": "..text)
		end,
		prefix = {"/w", "/whisper"}
	})

	nut.chat.Register("looc", {
		canHear = nut.config.chatRange,
		onChat = function(speaker, text)
			chat.AddText(Color(169, 207, 232), "[LOOC] "..speaker:Name()..": "..text)
		end,
		prefix = {".//", "[[", "/looc"},
		canSay = function(speaker)
			return true
		end
	})

	nut.chat.Register("it", {
		canHear = nut.config.chatRange,
		onChat = function(speaker, text)
			chat.AddText(Color(169, 207, 232), "**"..text)
		end,
		prefix = "/it",
		font = "nut_ChatFontAction"
	})

	nut.chat.Register("ic", {
		canHear = nut.config.chatRange,
		onChat = function(speaker, text)
			chat.AddText(Color(169, 207, 232), speaker:Name()..": "..text)
		end
	})

	nut.chat.Register("yell", {
		canHear = nut.config.yellRange,
		onChat = function(speaker, text)
			chat.AddText(Color(219, 257, 282), speaker:Name()..": "..text)
		end,
		prefix = {"/y", "/yell"}
	})

	nut.chat.Register("me", {
		canHear = nut.config.chatRange,
		onChat = function(speaker, text)
			chat.AddText(Color(179, 217, 242), "**"..speaker:Name().." "..text)
		end,
		prefix = {"/me", "/action"},
		font = "nut_ChatFontAction"
	})

	nut.chat.Register("ooc", {
		onChat = function(speaker, text)
			chat.AddText(Color(250, 40, 40), "[OOC] ", speaker, color_white, ": "..text)
		end,
		prefix = {"//", "/ooc"},
	})

	nut.chat.Register("event", {
		onChat = function(speaker, text)
			if (!speaker:IsAdmin()) then
				speaker:ChatPrint(nut.lang.Get("no_perm", speaker:Name()))

				return
			end

			chat.AddText(Color(194, 93, 39), text)
		end,
		prefix = "/event",
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
			net.Start("nut_Typing")
				net.WriteString("1")
			net.SendToServer()
		end
	end)

	hook.Add("FinishChat", "nut_Typing", function(teamChat)
		net.Start("nut_Typing")
			net.WriteString("")
		net.SendToServer()
	end)

	local nextSend = 0

	hook.Add("ChatTextChanged", "nut_Typing", function(text)
		if (nut.config.showTypingText) then
			if (nextSend < CurTime()) then
				net.Start("nut_Typing")
					net.WriteString(text)
				net.SendToServer()

				nextSend = CurTime() + 0.25
			end
		end
	end)

	-- Handle a chat message from the server and parse it with the appropriate chat class.
	net.Receive("nut_ChatMessage", function(length)
		local speaker = net.ReadEntity()
		local mode = net.ReadString()
		local text = net.ReadString()
		local class = nut.chat.classes[mode]

		if (!IsValid(speaker) or !speaker.character or !class or isChatFiltered(mode)) then
			return
		end

		nut.schema.Call("ChatClassPreText", class, speaker, text)
			class.onChat(speaker, text)
		nut.schema.Call("ChatClassPostText", class, speaker, text)
	end)
else
	util.AddNetworkString("nut_ChatMessage")
	util.AddNetworkString("nut_Typing")

	net.Receive("nut_Typing", function(length, client)
		client:SetNetVar("typing", net.ReadString())
	end)

	-- Send a chat class to the clients that can hear it based off the classes's canHear function.
	function nut.chat.Send(client, mode, text)
		local listeners = {client}
		local class = nut.chat.classes[mode]

		if (!class.canSay(client)) then
			return ""
		end

		for k, v in pairs(player.GetAll()) do
			if (class.canHear(client, v)) then
				listeners[#listeners + 1] = v
			end
		end

		net.Start("nut_ChatMessage")
			net.WriteEntity(client)
			net.WriteString(mode)
			net.WriteString(text)
		if (#listeners == 0) then
			net.Broadcast()
		else
			net.Send(listeners)
		end

		print(client:Name()..": ("..string.upper(mode)..") "..text)
	end

	-- Proccess the text and see if it is a chat class or chat command.
	function nut.chat.Process(client, text)
		if (!client.character) then
			client:ChatPrint(nut.lang.Get("nochar_talk_error"))
			
			return
		end

		local mode
		local text2 = string.lower(text)

		for k, v in pairs(nut.chat.classes) do
			if (type(v.prefix) == "table") then
				for k2, v2 in pairs(v.prefix) do
					local length = string.len(v2) + 1
					if (string.Left(text2, length) == v2.." ") then
						mode = k
						text = string.sub(text, length + 1)

						break
					end
				end
			else
				if (v.prefix) then
					local length = string.len(v.prefix) + 1
					if (string.Left(text2, length) == v.prefix.." ") then
						mode = k
						text = string.sub(text, length + 1)

						break
					end
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

		nut.chat.Send(client, mode, text)

		return ""
	end
end

local playerMeta = FindMetaTable("Player")

function playerMeta:IsTyping()
	return self:GetNetVar("typing", "") != ""
end