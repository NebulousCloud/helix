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

PLUGIN.name = "Chatbox"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds a chatbox that replaces the default one."

if (CLIENT) then
	NUT_CVAR_CHATFILTER = CreateClientConVar("nut_chatfilter", "", true, false)

	function PLUGIN:createChat()
		if (IsValid(self.panel)) then
			return
		end

		self.panel = vgui.Create("nutChatBox")
	end

	function PLUGIN:InitPostEntity()
		self:createChat()
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		bind = bind:lower()

		if (bind:find("messagemode") and pressed) then
			self.panel:setActive(true)

			return true
		end
	end

	function PLUGIN:HUDShouldDraw(element)
		if (element == "CHudChat") then
			return false
		end
	end

	chat.nutAddText = chat.nutAddText or chat.AddText

	local PLUGIN = PLUGIN

	function chat.AddText(...)
		local show = true

		if (IsValid(PLUGIN.panel)) then
			show = PLUGIN.panel:addText(...)
		end

		if (show) then
			chat.nutAddText(...)
			chat.PlaySound()
		end
	end

	function PLUGIN:ChatText(index, name, text, messageType)
		if (messageType == "none" and IsValid(self.panel)) then
			self.panel:addText(text)
			chat.PlaySound()
		end
	end

	concommand.Add("fixchatplz", function()
		if (IsValid(PLUGIN.panel)) then
			PLUGIN.panel:Remove()
			PLUGIN:createChat()
		end
	end)
else
	netstream.Hook("msg", function(client, text)
		if ((client.nutNextChat or 0) < CurTime() and text:find("%S")) then
			hook.Run("PlayerSay", client, text)
			client.nutNextChat = CurTime() + math.max(#text / 250, 0.4)
		end
	end)
end