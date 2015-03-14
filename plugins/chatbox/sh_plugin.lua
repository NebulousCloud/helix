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