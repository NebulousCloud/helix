
PLUGIN.name = "Recognition"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds the ability to recognize people."

do
	local character = ix.meta.character

	if (SERVER) then
		function character:Recognize(id)
			if (!isnumber(id) and id.GetID) then
				id = id:GetID()
			end

			local recognized = self:GetData("rgn", "")

			if (recognized != "" and recognized:find(","..id..",")) then
				return false
			end

			self:SetData("rgn", recognized..","..id..",")

			return true
		end
	end

	function character:DoesRecognize(id)
		if (!isnumber(id) and id.GetID) then
			id = id:GetID()
		end

		return hook.Run("IsCharacterRecognized", self, id)
	end

	function PLUGIN:IsCharacterRecognized(char, id)
		if (char.id == id) then
			return true
		end

		local other = ix.char.loaded[id]

		if (other) then
			local faction = ix.faction.indices[other:GetFaction()]

			if (faction and faction.isGloballyRecognized) then
				return true
			end
		end

		local recognized = char:GetData("rgn", "")

		if (recognized != "" and recognized:find(","..id..",")) then
			return true
		end
	end
end

if (CLIENT) then
	CHAT_RECOGNIZED = CHAT_RECOGNIZED or {}
	CHAT_RECOGNIZED["ic"] = true
	CHAT_RECOGNIZED["y"] = true
	CHAT_RECOGNIZED["w"] = true
	CHAT_RECOGNIZED["me"] = true

	function PLUGIN:IsRecognizedChatType(chatType)
		if (CHAT_RECOGNIZED[chatType]) then
			return true
		end
	end

	function PLUGIN:GetCharacterDescription(client)
		if (client:GetCharacter() and client != LocalPlayer() and LocalPlayer():GetCharacter() and
			!LocalPlayer():GetCharacter():DoesRecognize(client:GetCharacter()) and !hook.Run("IsPlayerRecognized", client)) then
			return L"noRecog"
		end
	end

	function PLUGIN:ShouldAllowScoreboardOverride(client)
		if (ix.config.Get("scoreboardRecognition")) then
			return true
		end
	end

	function PLUGIN:GetCharacterName(client, chatType)
		if (client != LocalPlayer()) then
			local character = client:GetCharacter()
			local ourCharacter = LocalPlayer():GetCharacter()

			if (ourCharacter and character and !ourCharacter:DoesRecognize(character) and !hook.Run("IsPlayerRecognized", client)) then
				if (chatType and hook.Run("IsRecognizedChatType", chatType)) then
					local description = character:GetDescription()

					if (#description > 40) then
						description = description:utf8sub(1, 37).."..."
					end

					return "["..description.."]"
				elseif (!chatType) then
					return L"unknown"
				end
			end
		end
	end

	local function Recognize(level)
		net.Start("ixRecognize")
			net.WriteUInt(level, 2)
		net.SendToServer()
	end

	net.Receive("ixRecognizeMenu", function(length)
		local menu = DermaMenu()
			menu:AddOption(L"rgnLookingAt", function()
				Recognize(0)
			end)
			menu:AddOption(L"rgnWhisper", function()
				Recognize(1)
			end)
			menu:AddOption(L"rgnTalk", function()
				Recognize(2)
			end)
			menu:AddOption(L"rgnYell", function()
				Recognize(3)
			end)
		menu:Open()
		menu:MakePopup()
		menu:Center()
	end)

	net.Receive("ixRecognizeDone", function(length)
		hook.Run("CharacterRecognized")
	end)

	function PLUGIN:CharacterRecognized(client, recogCharID)
		surface.PlaySound("buttons/button17.wav")
	end
else
	util.AddNetworkString("ixRecognize")
	util.AddNetworkString("ixRecognizeMenu")
	util.AddNetworkString("ixRecognizeDone")

	function PLUGIN:ShowSpare1(client)
		if (client:GetCharacter()) then
			net.Start("ixRecognizeMenu")
			net.Send(client)
		end
	end

	net.Receive("ixRecognize", function(length, client)
		local level = net.ReadUInt(2)

		if (isnumber(level)) then
			local targets = {}

			if (level < 1) then
				local entity = client:GetEyeTraceNoCursor().Entity

				if (IsValid(entity) and entity:IsPlayer() and entity:GetCharacter()
				and ix.chat.classes.ic:CanHear(client, entity)) then
					targets[1] = entity
				end
			else
				local class = "w"

				if (level == 2) then
					class = "ic"
				elseif (level == 3) then
					class = "y"
				end

				class = ix.chat.classes[class]

				for _, v in player.Iterator() do
					if (client != v and v:GetCharacter() and class:CanHear(client, v)) then
						targets[#targets + 1] = v
					end
				end
			end

			if (#targets > 0) then
				local id = client:GetCharacter():GetID()
				local i = 0

				for _, v in ipairs(targets) do
					if (v:GetCharacter():Recognize(id)) then
						i = i + 1
					end
				end

				if (i > 0) then
					net.Start("ixRecognizeDone")
					net.Send(client)

					hook.Run("CharacterRecognized", client, id)
				end
			end
		end
	end)
end
