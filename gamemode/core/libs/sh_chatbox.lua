nut.chat = nut.chat or {}
nut.chat.classes = nut.char.classes or {}

local DUMMY_COMMAND = {syntax = "<string text>", OnRun = function() end}

if (!nut.command) then
	include("sh_command.lua")
end

-- Registers a new chat type with the information provided.
function nut.chat.Register(chatType, data)
	if (!data.OnCanHear) then
		-- Have a substitute if the canHear property is not found.
		function data:OnCanHear(speaker, listener)
			-- The speaker will be heard by everyone.
			return true
		end
	elseif (type(data.OnCanHear) == "number") then
		-- Use the value as a range and create a function to compare distances.
		local range = data.OnCanHear * data.OnCanHear

		function data:OnCanHear(speaker, listener)
			-- Length2DSqr is faster than Length2D, so just check the squares.
			return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= range
		end
	end

	-- Allow players to use this chat type by default.
	if (!data.OnCanSay) then
		function data:OnCanSay(speaker, text)
			if (!self.deadCanChat and !speaker:Alive()) then
				speaker:NotifyLocalized("noPerm")

				return false
			end

			return true
		end
	end

	-- Chat text color.
	data.color = data.color or Color(242, 230, 160)

	if (!data.OnChatAdd) then
		data.format = data.format or "%s: \"%s\""

		function data:OnChatAdd(speaker, text, anonymous, info)
			local color = self.color
			local name = anonymous and L"someone" or hook.Run("GetDisplayedName", speaker, chatType) or (IsValid(speaker) and speaker:Name() or "Console")

			if (self.OnGetColor) then
				color = self:OnGetColor(speaker, text)
			end

			local translated = L2(chatType.."Format", name, text)

			chat.AddText(color, translated or string.format(self.format, name, text))
		end
	end

	if (CLIENT and data.prefix) then
		if (type(data.prefix) == "table") then
			for k, v in ipairs(data.prefix) do
				if (v:sub(1, 1) == "/") then
					nut.command.Add(v:sub(2), DUMMY_COMMAND)
				end
			end
		else
			nut.command.Add(chatType, DUMMY_COMMAND)
		end
	end

	data.filter = data.filter or "ic"

	-- Add the chat type to the list of classes.
	nut.chat.classes[string.lower(chatType)] = data
end

-- Identifies which chat mode should be used.
function nut.chat.Parse(client, message, noSend)
	local anonymous = false
	local chatType = "ic"

	-- Loop through all chat classes and see if the message contains their prefix.
	for k, v in pairs(nut.chat.classes) do
		local isChosen = false
		local chosenPrefix = ""
		local noSpaceAfter = v.noSpaceAfter

		-- Check through all prefixes if the chat type has more than one.
		if (type(v.prefix) == "table") then
			for _, prefix in ipairs(v.prefix) do
				-- Checking if the start of the message has the prefix.
				if (message:sub(1, #prefix + (noSpaceAfter and 0 or 1)):lower() == prefix..(noSpaceAfter and "" or " "):lower()) then
					isChosen = true
					chosenPrefix = prefix..(v.noSpaceAfter and "" or " ")

					break
				end
			end
		-- Otherwise the prefix itself is checked.
		elseif (type(v.prefix) == "string") then
			isChosen = message:sub(1, #v.prefix + (noSpaceAfter and 1 or 0)):lower() == v.prefix..(noSpaceAfter and "" or " "):lower()
			chosenPrefix = v.prefix..(v.noSpaceAfter and "" or " ")
		end

		-- If the checks say we have the proper chat type, then the chat type is the chosen one!
		-- If this is not chosen, the loop continues. If the loop doesn't find the correct chat
		-- type, then it falls back to IC chat as seen by the chatType variable above.
		if (isChosen) then
			-- Set the chat type to the chosen one.
			chatType = k
			-- Remove the prefix from the chat type so it does not show in the message.
			message = message:sub(#chosenPrefix + 1)

			if (nut.chat.classes[k].noSpaceAfter and message:sub(1, 1):match("%s")) then
				message = message:sub(2)
			end

			break
		end
	end

	if (!message:find("%S")) then
		return
	end

	-- Only send if needed.
	if (SERVER and !noSend) then
		-- Send the correct chat type out so other player see the message.
		nut.chat.Send(client, chatType, hook.Run("PlayerMessageSend", client, chatType, message, anonymous) or message, anonymous)
	end

	-- Return the chosen chat type and the message that was sent if needed for some reason.
	-- This would be useful if you want to send the message on your own.
	return chatType, message, anonymous
end

if (SERVER) then
	-- Send a chat message using the specified chat type.
	function nut.chat.Send(speaker, chatType, text, anonymous, receivers)
		local class = nut.chat.classes[chatType]

		if (class and class:OnCanSay(speaker, text) != false) then
			if (class.OnCanHear and !receivers) then
				receivers = {}

				for k, v in ipairs(player.GetAll()) do
					if (v:GetChar() and class:OnCanHear(speaker, v) != false) then
						receivers[#receivers + 1] = v
					end
				end

				if (#receivers == 0) then
					return
				end
			end

			netstream.Start(receivers, "cMsg", speaker, chatType, hook.Run("PlayerMessageSend", speaker, chatType, text, anonymous, receivers) or text, anonymous or false)
		end
	end
else
	-- Call OnChatAdd for the appropriate chatType.
	netstream.Hook("cMsg", function(client, chatType, text, anonymous)
		if (IsValid(client)) then
			local info = {
				chatType = chatType,
				text = text,
				anonymous = anonymous,
				data = {}
			}

			hook.Run("OnChatReceived", client, info)

			local class = nut.chat.classes[info.chatType or chatType]

			if (class) then
				CHAT_CLASS = class
					class:OnChatAdd(client, info.text or text, info.anonymous or anonymous, info.data or {})
				CHAT_CLASS = nil
			end
		end
	end)
end

-- Add the default chat types here.
do
	-- Load the chat types after the configs so we can access changed configs.
	hook.Add("InitializedConfig", "nutChatTypes", function()
		-- The default in-character chat.
		nut.chat.Register("ic", {
			format = "%s says \"%s\"",
			OnGetColor = function(self, speaker, text)
				-- If you are looking at the speaker, make it greener to easier identify who is talking.
				if (LocalPlayer():GetEyeTrace().Entity == speaker) then
					return nut.config.Get("chatListenColor")
				end

				-- Otherwise, use the normal chat color.
				return nut.config.Get("chatColor")
			end,
			OnCanHear = nut.config.Get("chatRange", 280)
		})

		-- Actions and such.
		nut.chat.Register("me", {
			format = "** %s %s",
			OnGetColor = nut.chat.classes.ic.OnGetColor,
			OnCanHear = nut.config.Get("chatRange", 280),
			prefix = {"/me", "/action"},
			filter = "actions",
			deadCanChat = true
		})

		-- Actions and such.
		nut.chat.Register("it", {
			OnChatAdd = function(self, speaker, text)
				chat.AddText(nut.config.Get("chatColor"), "** "..text)
			end,
			OnCanHear = nut.config.Get("chatRange", 280),
			prefix = {"/it"},
			filter = "actions",
			deadCanChat = true
		})

		-- Whisper chat.
		nut.chat.Register("w", {
			format = "%s whispers \"%s\"",
			OnGetColor = function(self, speaker, text)
				local color = nut.chat.classes.ic:OnGetColor(speaker, text)

				-- Make the whisper chat slightly darker than IC chat.
				return Color(color.r - 35, color.g - 35, color.b - 35)
			end,
			OnCanHear = nut.config.Get("chatRange", 280) * 0.25,
			prefix = {"/w", "/whisper"}
		})

		-- Yelling out loud.
		nut.chat.Register("y", {
			format = "%s yells \"%s\"",
			OnGetColor = function(self, speaker, text)
				local color = nut.chat.classes.ic:OnGetColor(speaker, text)

				-- Make the yell chat slightly brighter than IC chat.
				return Color(color.r + 35, color.g + 35, color.b + 35)
			end,
			OnCanHear = nut.config.Get("chatRange", 280) * 2,
			prefix = {"/y", "/yell"}
		})

		-- Out of character.
		nut.chat.Register("ooc", {
			OnCanSay = function(self, speaker, text)
				if (!nut.config.Get("allowGlobalOOC")) then
					speaker:NotifyLocalized("Global OOC is disabled on this server.")
					return false		
				else
					local delay = nut.config.Get("oocDelay", 10)

					-- Only need to check the time if they have spoken in OOC chat before.
					if (delay > 0 and speaker.nutLastOOC) then
						local lastOOC = CurTime() - speaker.nutLastOOC

						-- Use this method of checking time in case the oocDelay config changes.
						if (lastOOC <= delay) then
							speaker:NotifyLocalized("oocDelay", delay - math.ceil(lastOOC))

							return false
						end
					end

					-- Save the last time they spoke in OOC.
					speaker.nutLastOOC = CurTime()
				end
			end,
			OnChatAdd = function(self, speaker, text)
				local icon = "icon16/user.png"

				if (speaker:IsSuperAdmin()) then
					icon = "icon16/shield.png"
				elseif (speaker:IsAdmin()) then
					icon = "icon16/star.png"
				elseif (speaker:IsUserGroup("moderator") or speaker:IsUserGroup("operator")) then
					icon = "icon16/wrench.png"
				elseif (speaker:IsUserGroup("vip") or speaker:IsUserGroup("donator") or speaker:IsUserGroup("donor")) then
					icon = "icon16/heart.png"
				end

				icon = Material(hook.Run("GetPlayerIcon", speaker) or icon)

				chat.AddText(icon, Color(255, 50, 50), " [OOC] ", speaker, color_white, ": "..text)
			end,
			prefix = {"//", "/ooc"},
			noSpaceAfter = true,
			filter = "ooc"
		})

		-- Local out of character.
		nut.chat.Register("looc", {
			OnCanSay = function(self, speaker, text)
				local delay = nut.config.Get("loocDelay", 0)

				-- Only need to check the time if they have spoken in OOC chat before.
				if (delay > 0 and speaker.nutLastLOOC) then
					local lastLOOC = CurTime() - speaker.nutLastLOOC

					-- Use this method of checking time in case the oocDelay config changes.
					if (lastLOOC <= delay) then
						speaker:NotifyLocalized("loocDelay", delay - math.ceil(lastLOOC))

						return false
					end
				end

				-- Save the last time they spoke in OOC.
				speaker.nutLastLOOC = CurTime()
			end,
			OnChatAdd = function(self, speaker, text)
				chat.AddText(Color(255, 50, 50), "[LOOC] ", nut.config.Get("chatColor"), speaker:Name()..": "..text)
			end,
			OnCanHear = nut.config.Get("chatRange", 280),
			prefix = {".//", "[[", "/looc"},
			noSpaceAfter = true,
			filter = "ooc"
		})

		-- Roll information in chat.
		nut.chat.Register("roll", {
			format = "%s has rolled %s.",
			color = Color(155, 111, 176),
			filter = "actions",
			OnCanHear = nut.config.Get("chatRange", 280),
			deadCanChat = true
		})
	end)
end

-- Private messages between players.
nut.chat.Register("pm", {
	format = "[PM] %s: %s.",
	color = Color(249, 211, 89),
	filter = "pm",
	deadCanChat = true
})

-- Global events.
nut.chat.Register("event", {
	OnCanSay = function(self, speaker, text)
		return speaker:IsAdmin()
	end,
	OnCanHear = 1000000,
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(255, 150, 0), text)
	end,
	prefix = {"/event"}
})

nut.chat.Register("connect", {
	OnCanSay = function(self, speaker, text)
		return !IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text)
		local icon = nut.util.GetMaterial("icon16/user_add.png")

		chat.AddText(icon, Color(150, 150, 200), L("playerConnected", nil, text))
	end,
	noSpaceAfter = true,
	filter = "ooc"
})

nut.chat.Register("disconnect", {
	OnCanSay = function(self, speaker, text)
		return !IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text)
		local icon = nut.util.GetMaterial("icon16/user_delete.png")

		chat.AddText(icon, Color(200, 150, 200), L("playerDisconnected", nil, text))
	end,
	noSpaceAfter = true,
	filter = "ooc"
})

-- Why does ULX even have a /me command?
hook.Remove("PlayerSay", "ULXMeCheck")
