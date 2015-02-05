--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]

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
			
			if (recognized != "" and recognized:find(","..id..",")) then
				return false;
			end;

			self:setData("rgn", recognized..","..id..",")

			return true
		end
	end

	function character:doesRecognize(id)
		if (type(id) != "number" and id.getID) then
			id = id:getID()
		end

		return hook.Run("IsCharRecognised", self, id)
	end

	function PLUGIN:IsCharRecognised(char, id)
		local recognized = char:getData("rgn", "");
		
		if (recognized == "") then
			return false;
		end;
		
		return recognized:find(","..id..",");
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
						description = description:utf8sub(1, 37).."..."
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
		hook.Run("OnCharRecognized", client, id)
	end)

	function PLUGIN:OnCharRecognized(client, recogCharID)
		surface.PlaySound("buttons/button17.wav")
	end
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
			local i = 0

			for k, v in ipairs(targets) do
				if (v:getChar():recognize(id)) then
					i = i + 1
				end
			end

			if (i > 0) then
				netstream.Start(client, "rgnDone")
				hook.Run("OnCharRecognized", client, id)
			end
		end
	end)
end