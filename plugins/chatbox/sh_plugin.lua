
local PLUGIN = PLUGIN

PLUGIN.name = "Chatbox"
PLUGIN.author = "Chessnut"
PLUGIN.description = "Adds a chatbox that replaces the default one."

if (CLIENT) then
	ix.option.Add("chatNotices", ix.type.bool, false, {
		category = "chat"
	})

	ix.option.Add("chatTimestamps", ix.type.bool, false, {
		category = "chat"
	})

	ix.option.Add("chatFilter", ix.type.string, "", {
		bHidden = true,
		category = "chat"
	})

	function PLUGIN:CreateChat()
		if (IsValid(self.panel)) then
			return
		end

		self.panel = vgui.Create("ixChatBox")
		hook.Run("OnChatboxCreated")
	end

	function PLUGIN:InitPostEntity()
		self:CreateChat()
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		bind = bind:lower()

		if (bind:find("messagemode") and pressed) then
			self.panel:SetActive(true)

			return true
		end
	end

	function PLUGIN:HUDShouldDraw(element)
		if (element == "CHudChat") then
			return false
		end
	end

	-- luacheck: globals chat
	chat.ixAddText = chat.ixAddText or chat.AddText

	function chat.AddText(...)
		local show = true

		if (IsValid(PLUGIN.panel)) then
			show = PLUGIN.panel:AddText(...)
		end

		if (show) then
			chat.ixAddText(...)
			chat.PlaySound()
		end
	end

	function PLUGIN:ChatText(index, name, text, messageType)
		if (messageType == "none" and IsValid(self.panel)) then
			self.panel:AddText(text)
			chat.PlaySound()
		end
	end

	concommand.Add("fixchatplz", function()
		if (IsValid(PLUGIN.panel)) then
			PLUGIN.panel:Remove()
			PLUGIN:CreateChat()
		end
	end)
else
	netstream.Hook("msg", function(client, text)
		if ((client.ixNextChat or 0) < CurTime() and text:find("%S")) then
			hook.Run("PlayerSay", client, text)
			client.ixNextChat = CurTime() + math.max(#text / 250, 0.4)
		end
	end)
end
