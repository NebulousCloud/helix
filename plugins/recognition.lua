PLUGIN.name = "Recognition"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds the ability to recognize people."

do
	local character = FindMetaTable("Character")

	if (SERVER) then
		function character:recognize(id)
			if (type(id) != "number" and id.getID) then
				id = id:getID()
			end

			local recognized = self:getData("rgn", "")

			if (recognized:find(id..",")) then
				return false
			end

			self:setData("rgn", recognized..id..",")
		end
	end

	function character:doesRecognize(id)
		if (type(id) != "number" and id.getID) then
			id = id:getID()
		end

		return self:getData("rgn", ""):find(id..",")
	end
end

if (CLIENT) then
	local whitelist = {}
	whitelist["ic"] = true
	whitelist["y"] = true
	whitelist["w"] = true

	function PLUGIN:IsRecognizedChatType(chatType)
		return whitelist[chatType]
	end

	function PLUGIN:GetDisplayedName(client, chatType)
		if (client != LocalPlayer()) then
			local character = client:getChar()
			local ourCharacter = LocalPlayer():getChar()

			if (ourCharacter and character and (!ourCharacter:doesRecognize(character) or hook.Run("IsPlayerRecognized", client))) then
				if (hook.Run("IsRecognizedChatType", chatType)) then
					local description = character:getDesc()

					if (#description > 40) then
						description = description:sub(1, 37).."..."
					end

					return "["..description.."]"
				else
					return L"unknown"
				end
			end
		end
	end

	netstream.Hook("rgnMenu", function()
		local menu = DermaMenu()
			menu:AddOption(L"rgnLookingAt", function()
				netstream.Start("rgn", 1)
			end)
			menu:AddOption(L"rgnWhisper", function()
				netstream.Start("rgn", 2)
			end)
			menu:AddOption(L"rgnTalk", function()
				netstream.Start("rgn", 3)
			end)
			menu:AddOption(L"rgnYell", function()
				netstream.Start("rgn", 4)
			end)
		menu:Open()
		menu:MakePopup()
		menu:Center()
	end)

	netstream.Hook("rgnDone", function()
		surface.PlaySound("buttons/button17.wav")
	end)
else
	function PLUGIN:ShowSpare1(client)
		if (client:getChar()) then
			netstream.Start(client, "rgnMenu")
		end
	end

	netstream.Hook("rgn", function(client, level)
		local targets = {}

		if (level < 2) then
			local entity = client:GetEyeTraceNoCursor().Entity

			if (IsValid(entity) and entity:IsPlayer() and entity:getChar() and nut.chat.classes.ic.onCanHear(client, entity)) then
				targets[1] = entity
			end
		else
			local class = "w"

			if (level == 3) then
				class = "ic"
			elseif (level == 4) then
				class = "y"
			end

			class = nut.chat.classes[class]

			for k, v in ipairs(player.GetAll()) do
				if (client != v and v:getChar() and class.onCanHear(client, v)) then
					targets[#targets + 1] = v
				end
			end
		end

		if (#targets > 0) then
			local id = client:getChar():getID()

			for k, v in ipairs(targets) do
				v:getChar():recognize(id)
			end

			netstream.Start(client, "rgnDone")
		end
	end)
end