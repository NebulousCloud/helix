
--[[--
Chat manipulation and helper functions.
]]
-- @module ix.chat

ix.chat = ix.chat or {}
ix.chat.classes = ix.chat.classes or {}

if (!ix.command) then
	include("sh_command.lua")
end

CAMI.RegisterPrivilege({
	Name = "Helix - Bypass OOC Timer",
	MinAccess = "admin"
})

--- Registers a new chat type with the information provided.
-- @realm shared
-- @string chatType Name of the chat type
-- @tab data Table Properties and functions to assign to this chat class. If fields are missing from the table, then it
-- will use a default value
-- @usage ix.chat.Register("me", {
-- 	format = "** %s %s",
-- 	GetColor = Color(255, 50, 50),
-- 	CanHear = ix.config.Get("chatRange", 280) * 2,
-- 	prefix = {"/Me", "/Action"},
-- 	description = "@cmdMe",
-- 	indicator = "chatPerforming",
-- 	deadCanChat = true
-- })
function ix.chat.Register(chatType, data)
	chatType = string.lower(chatType)

	if (!data.CanHear) then
		-- Have a substitute if the canHear property is not found.
		function data:CanHear(speaker, listener)
			-- The speaker will be heard by everyone.
			return true
		end
	elseif (isnumber(data.CanHear)) then
		-- Use the value as a range and create a function to compare distances.
		local range = data.CanHear * data.CanHear
		data.range = range

		function data:CanHear(speaker, listener)
			-- Length2DSqr is faster than Length2D, so just check the squares.
			return (speaker:GetPos() - listener:GetPos()):LengthSqr() <= range
		end
	end

	-- Allow players to use this chat type by default.
	if (!data.CanSay) then
		function data:CanSay(speaker, text)
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
			local name = anonymous and
				L"someone" or hook.Run("GetCharacterName", speaker, chatType) or
				(IsValid(speaker) and speaker:Name() or "Console")

			if (self.GetColor) then
				color = self:GetColor(speaker, text, info)
			end

			local translated = L2(chatType.."Format", name, text)

			chat.AddText(color, translated or string.format(self.format, name, text))
		end
	end

	if (CLIENT and data.prefix) then
		if (istable(data.prefix)) then
			for _, v in ipairs(data.prefix) do
				if (v:sub(1, 1) == "/") then
					ix.command.Add(v:sub(2), {
						description = data.description,
						arguments = ix.type.text,
						indicator = data.indicator,
						bNoIndicator = data.bNoIndicator,
						chatClass = data,
						OnCheckAccess = function() return true end,
						OnRun = function(self, client, message) end
					})
				end
			end
		else
			ix.command.Add(isstring(data.prefix) and data.prefix:sub(2) or chatType, {
				description = data.description,
				arguments = ix.type.text,
				indicator = data.indicator,
				bNoIndicator = data.bNoIndicator,
				chatClass = data,
				OnCheckAccess = function() return true end,
				OnRun = function(self, client, message) end
			})
		end
	end

	data.filter = data.filter or "ic"
	data.uniqueID = chatType

	-- Add the chat type to the list of classes.
	ix.chat.classes[chatType] = data
end

--- Identifies which chat mode should be used.
-- @realm shared
-- @player client Player who is speaking
-- @string message Message to parse
-- @bool[opt=false] bNoSend Whether or not to send the chat message after parsing
-- @treturn string Name of the chat type
-- @treturn string Message that was parsed
-- @treturn bool Whether or not the speaker should be anonymous
function ix.chat.Parse(client, message, bNoSend)
	local anonymous = false
	local chatType = "ic"

	-- Loop through all chat classes and see if the message contains their prefix.
	for k, v in pairs(ix.chat.classes) do
		local isChosen = false
		local chosenPrefix = ""
		local noSpaceAfter = v.noSpaceAfter

		-- Check through all prefixes if the chat type has more than one.
		if (istable(v.prefix)) then
			for _, prefix in ipairs(v.prefix) do
				prefix = prefix:lower()

				-- Checking if the start of the message has the prefix.
				if (message:sub(1, #prefix + (noSpaceAfter and 0 or 1)):lower() == prefix..(noSpaceAfter and "" or " "):lower()) then
					isChosen = true
					chosenPrefix = prefix..(v.noSpaceAfter and "" or " ")

					break
				end
			end
		-- Otherwise the prefix itself is checked.
		elseif (isstring(v.prefix)) then
			local prefix = v.prefix:lower()

			isChosen = message:sub(1, #prefix + (noSpaceAfter and 0 or 1)):lower() == prefix..(noSpaceAfter and "" or " "):lower()
			chosenPrefix = prefix..(v.noSpaceAfter and "" or " ")
		end

		-- If the checks say we have the proper chat type, then the chat type is the chosen one!
		-- If this is not chosen, the loop continues. If the loop doesn't find the correct chat
		-- type, then it falls back to IC chat as seen by the chatType variable above.
		if (isChosen) then
			-- Set the chat type to the chosen one.
			chatType = k
			-- Remove the prefix from the chat type so it does not show in the message.
			message = message:sub(#chosenPrefix + 1)

			if (ix.chat.classes[k].noSpaceAfter and message:sub(1, 1):match("%s")) then
				message = message:sub(2)
			end

			break
		end
	end

	if (!message:find("%S")) then
		return
	end

	-- Only send if needed.
	if (SERVER and !bNoSend) then
		-- Send the correct chat type out so other player see the message.
		ix.chat.Send(client, chatType, hook.Run("PlayerMessageSend", client, chatType, message, anonymous) or message, anonymous)
	end

	-- Return the chosen chat type and the message that was sent if needed for some reason.
	-- This would be useful if you want to send the message on your own.
	return chatType, message, anonymous
end

if (SERVER) then
	util.AddNetworkString("ixChatMessage")

	--- Send a chat message using the specified chat type.
	-- @realm server
	-- @player speaker Player who is speaking
	-- @string chatType Name of the chat type
	-- @string text Message to send
	-- @bool[opt=false] anonymous Whether or not the speaker should be anonymous
	-- @tab[opt=nil] receivers The players to replicate send the message to
	-- @tab[opt=nil] data Additional data for this chat message
	function ix.chat.Send(speaker, chatType, text, anonymous, receivers, data)
		if (!chatType) then
			return
		end

		data = data or {}
		chatType = string.lower(chatType)

		local class = ix.chat.classes[chatType]

		if (class and class:CanSay(speaker, text, data) != false) then
			if (class.CanHear and !receivers) then
				receivers = {}

				for _, v in ipairs(player.GetAll()) do
					if (v:GetCharacter() and class:CanHear(speaker, v, data) != false) then
						receivers[#receivers + 1] = v
					end
				end

				if (#receivers == 0) then
					return
				end
			end

			-- Format the message if needed before we run the hook.
			local rawText = text
			local maxLength = ix.config.Get("chatMax")

			if (text:len() > maxLength) then
				text = text:sub(0, maxLength)
			end

			if (ix.config.Get("chatAutoFormat") and hook.Run("CanAutoFormatMessage", speaker, chatType, text)) then
				local last = text:sub(-1)

				if (last != "." and last != "?" and last != "!" and last != "-" and last != "\"") then
					text = text .. "."
				end

				text = text:sub(1, 1):upper() .. text:sub(2)
			end

			text = hook.Run("PlayerMessageSend", speaker, chatType, text, anonymous, receivers, rawText) or text

			net.Start("ixChatMessage")
				net.WriteEntity(speaker)
				net.WriteString(chatType)
				net.WriteString(text)
				net.WriteBool(anonymous or false)
				net.WriteTable(data or {})
			net.Send(receivers)

			return text
		end
	end
else
	function ix.chat.Send(speaker, chatType, text, anonymous, data)
		local class = ix.chat.classes[chatType]

		if (class) then
			-- luacheck: globals CHAT_CLASS
			CHAT_CLASS = class
				class:OnChatAdd(speaker, text, anonymous, data)
			CHAT_CLASS = nil
		end
	end

	-- Call OnChatAdd for the appropriate chatType.
	net.Receive("ixChatMessage", function()
		local client = net.ReadEntity()
		local chatType = net.ReadString()
		local text = net.ReadString()
		local anonymous = net.ReadBool()
		local data = net.ReadTable()

		if (IsValid(client)) then
			local info = {
				chatType = chatType,
				text = text,
				anonymous = anonymous,
				data = data
			}

			hook.Run("MessageReceived", client, info)
			ix.chat.Send(client, info.chatType or chatType, info.text or text, info.anonymous or anonymous, info.data)
		else
			ix.chat.Send(nil, chatType, text, anonymous, data)
		end
	end)
end

-- Add the default chat types here.
do
	-- Load the chat types after the configs so we can access changed configs.
	hook.Add("InitializedConfig", "ixChatTypes", function()
		-- The default in-character chat.
		ix.chat.Register("ic", {
			format = "%s says \"%s\"",
			indicator = "chatTalking",
			GetColor = function(self, speaker, text)
				-- If you are looking at the speaker, make it greener to easier identify who is talking.
				if (LocalPlayer():GetEyeTrace().Entity == speaker) then
					return ix.config.Get("chatListenColor")
				end

				-- Otherwise, use the normal chat color.
				return ix.config.Get("chatColor")
			end,
			CanHear = ix.config.Get("chatRange", 280)
		})

		-- Actions and such.
		ix.chat.Register("me", {
			format = "** %s %s",
			GetColor = ix.chat.classes.ic.GetColor,
			CanHear = ix.config.Get("chatRange", 280) * 2,
			prefix = {"/Me", "/Action"},
			description = "@cmdMe",
			indicator = "chatPerforming",
			deadCanChat = true
		})

		-- Actions and such.
		ix.chat.Register("it", {
			OnChatAdd = function(self, speaker, text)
				chat.AddText(ix.config.Get("chatColor"), "** "..text)
			end,
			CanHear = ix.config.Get("chatRange", 280) * 2,
			prefix = {"/It"},
			description = "@cmdIt",
			indicator = "chatPerforming",
			deadCanChat = true
		})

		-- Whisper chat.
		ix.chat.Register("w", {
			format = "%s whispers \"%s\"",
			GetColor = function(self, speaker, text)
				local color = ix.chat.classes.ic:GetColor(speaker, text)

				-- Make the whisper chat slightly darker than IC chat.
				return Color(color.r - 35, color.g - 35, color.b - 35)
			end,
			CanHear = ix.config.Get("chatRange", 280) * 0.25,
			prefix = {"/W", "/Whisper"},
			description = "@cmdW",
			indicator = "chatWhispering"
		})

		-- Yelling out loud.
		ix.chat.Register("y", {
			format = "%s yells \"%s\"",
			GetColor = function(self, speaker, text)
				local color = ix.chat.classes.ic:GetColor(speaker, text)

				-- Make the yell chat slightly brighter than IC chat.
				return Color(color.r + 35, color.g + 35, color.b + 35)
			end,
			CanHear = ix.config.Get("chatRange", 280) * 2,
			prefix = {"/Y", "/Yell"},
			description = "@cmdY",
			indicator = "chatYelling"
		})

		-- Out of character.
		ix.chat.Register("ooc", {
			CanSay = function(self, speaker, text)
				if (!ix.config.Get("allowGlobalOOC")) then
					speaker:NotifyLocalized("Global OOC is disabled on this server.")
					return false
				else
					local delay = ix.config.Get("oocDelay", 10)

					-- Only need to check the time if they have spoken in OOC chat before.
					if (delay > 0 and speaker.ixLastOOC) then
						local lastOOC = CurTime() - speaker.ixLastOOC

						-- Use this method of checking time in case the oocDelay config changes.
						if (lastOOC <= delay and !CAMI.PlayerHasAccess(speaker, "Helix - Bypass OOC Timer", nil)) then
							speaker:NotifyLocalized("oocDelay", delay - math.ceil(lastOOC))

							return false
						end
					end

					-- Save the last time they spoke in OOC.
					speaker.ixLastOOC = CurTime()
				end
			end,
			OnChatAdd = function(self, speaker, text)
				-- @todo remove and fix actual cause of speaker being nil
				if (!IsValid(speaker)) then
					return
				end

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

				chat.AddText(icon, Color(255, 50, 50), "[OOC] ", speaker, color_white, ": "..text)
			end,
			prefix = {"//", "/OOC"},
			description = "@cmdOOC",
			noSpaceAfter = true
		})

		-- Local out of character.
		ix.chat.Register("looc", {
			CanSay = function(self, speaker, text)
				local delay = ix.config.Get("loocDelay", 0)

				-- Only need to check the time if they have spoken in OOC chat before.
				if (delay > 0 and speaker.ixLastLOOC) then
					local lastLOOC = CurTime() - speaker.ixLastLOOC

					-- Use this method of checking time in case the oocDelay config changes.
					if (lastLOOC <= delay and !CAMI.PlayerHasAccess(speaker, "Helix - Bypass OOC Timer", nil)) then
						speaker:NotifyLocalized("loocDelay", delay - math.ceil(lastLOOC))

						return false
					end
				end

				-- Save the last time they spoke in OOC.
				speaker.ixLastLOOC = CurTime()
			end,
			OnChatAdd = function(self, speaker, text)
				chat.AddText(Color(255, 50, 50), "[LOOC] ", ix.config.Get("chatColor"), speaker:Name()..": "..text)
			end,
			CanHear = ix.config.Get("chatRange", 280),
			prefix = {".//", "[[", "/LOOC"},
			description = "@cmdLOOC",
			noSpaceAfter = true
		})

		-- Roll information in chat.
		ix.chat.Register("roll", {
			format = "** %s has rolled %s out of %s.",
			color = Color(155, 111, 176),
			CanHear = ix.config.Get("chatRange", 280),
			deadCanChat = true,
			OnChatAdd = function(self, speaker, text, bAnonymous, data)
				chat.AddText(self.color, string.format(self.format,
					speaker:GetName(), text, data.max or 100
				))
			end
		})

		-- run a hook after we add the basic chat classes so schemas/plugins can access their info as soon as possible if needed
		hook.Run("InitializedChatClasses")
	end)
end

-- Private messages between players.
ix.chat.Register("pm", {
	format = "[PM] %s -> %s: %s",
	color = Color(125, 150, 75, 255),
	deadCanChat = true,

	OnChatAdd = function(self, speaker, text, bAnonymous, data)
		chat.AddText(self.color, string.format(self.format, speaker:GetName(), data.target:GetName(), text))

		if (LocalPlayer() != speaker) then
			surface.PlaySound("hl1/fvox/bell.wav")
		end
	end
})

-- Global events.
ix.chat.Register("event", {
	CanHear = 1000000,
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(255, 150, 0), text)
	end,
	indicator = "chatPerforming"
})

ix.chat.Register("connect", {
	CanSay = function(self, speaker, text)
		return !IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text)
		local icon = ix.util.GetMaterial("icon16/user_add.png")

		chat.AddText(icon, Color(150, 150, 200), L("playerConnected", text))
	end,
	noSpaceAfter = true
})

ix.chat.Register("disconnect", {
	CanSay = function(self, speaker, text)
		return !IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text)
		local icon = ix.util.GetMaterial("icon16/user_delete.png")

		chat.AddText(icon, Color(200, 150, 200), L("playerDisconnected", text))
	end,
	noSpaceAfter = true
})

ix.chat.Register("notice", {
	CanSay = function(self, speaker, text)
		return !IsValid(speaker)
	end,
	OnChatAdd = function(self, speaker, text, bAnonymous, data)
		local icon = ix.util.GetMaterial(data.bError and "icon16/comment_delete.png" or "icon16/comment.png")
		chat.AddText(icon, data.bError and Color(200, 175, 200, 255) or Color(175, 200, 255), text)
	end,
	noSpaceAfter = true
})

-- Why does ULX even have a /me command?
hook.Remove("PlayerSay", "ULXMeCheck")
