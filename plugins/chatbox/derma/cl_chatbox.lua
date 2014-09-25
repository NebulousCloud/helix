local PANEL = {}
	local gradient = Material("vgui/gradient-d")
	local gradient2 = Material("vgui/gradient-u")

	function PANEL:Init()
		local border = 32
		local scrW, scrH = ScrW(), ScrH()
		local w, h = scrW * 0.4, scrH * 0.375

		self:SetSize(w, h)
		self:SetPos(border, scrH - h - border)

		self.active = false

		self.tabs = self:Add("DPanel")
		self.tabs:Dock(TOP)
		self.tabs:SetTall(24)
		self.tabs:DockMargin(4, 4, 4, 4)
		self.tabs:SetVisible(false)

		self.scroll = self:Add("DScrollPanel")
		self.scroll:SetPos(4, 30)
		self.scroll:SetSize(w - 8, h - 70)
		self.scroll:GetVBar():SetWide(0)

		self.lastY = 0

		chat.GetChatBoxPos = function()
			return self:LocalToScreen(0, 0)
		end

		chat.GetChatBoxSize = function()
			return self:GetSize()
		end
	end

	function PANEL:Paint(w, h)
		if (self.active) then
			surface.SetDrawColor(50, 50, 50, 200)
			surface.DrawRect(0, 0, w, h)

			surface.SetDrawColor(0, 0, 0, 130)
			surface.SetMaterial(gradient)
			surface.DrawTexturedRect(0, 0, w, h)

			surface.SetDrawColor(0, 0, 0, 240)
			surface.DrawOutlinedRect(0, 0, w, h)
		end
	end

	local TEXT_COLOR = Color(255, 255, 255, 200)

	function PANEL:setActive(state)
		self.active = state

		if (state) then

			self.entry = self:Add("EditablePanel")
			self.entry:SetPos(self.x + 4, self.y + self:GetTall() - 32)
			self.entry:SetWide(self:GetWide() - 8)
			self.entry.Paint = function(this, w, h)
			end
			self.entry:SetTall(28)

			self.text = self.entry:Add("DTextEntry")
			self.text:Dock(FILL)
			self.text:DockMargin(3, 3, 3, 3)
			self.text.OnEnter = function(this)
				local text = this:GetText()

				self.tabs:SetVisible(false)
				self.active = false
				self.entry:Remove()

				if (text:find("%S")) then
					netstream.Start("msg", text)
				end
			end
			self.text:SetAllowNonAsciiCharacters(true)
			self.text.Paint = function(this, w, h)
				surface.SetDrawColor(250, 250, 250, 10)
				surface.DrawRect(0, 0, w, h)

				surface.SetDrawColor(0, 0, 0, 10)
				surface.SetMaterial(gradient2)
				surface.DrawTexturedRect(0, 0, w, h)

				surface.SetDrawColor(0, 0, 0, 200)
				surface.DrawOutlinedRect(0, 0, w, h)

				this:DrawTextEntryText(TEXT_COLOR, nut.config.get("color"), TEXT_COLOR)
			end

			self.entry:MakePopup()
			self.text:RequestFocus()
			self.tabs:SetVisible(true)
		end
	end

	local function OnDrawText(text, font, x, y, color, alignX, alignY, alpha)
		draw.TextShadow({
			pos = {x, y},
			color = ColorAlpha(color, alpha),
			text = text,
			xalign = 0,
			yalign = alignY,
			font = font
		}, 1, alpha)
	end

	function PANEL:addText(...)
		local text = "<font=nutChatFont>"

		for k, v in ipairs({...}) do
			if (type(v) == "IMaterial") then
				text = text.."<img="..tostring(v)..","..v:Width().."x"..v:Height()..">"
			elseif (type(v) == "table" and v.r and v.g and v.b) then
				text = text.."<color="..v.r..","..v.g..","..v.b..">"
			elseif (type(v) == "Player") then
				local color = team.GetColor(v:Team())

				text = text.."<color="..color.r..","..color.g..","..color.b..">"..v:Name()
			else
				text = text..tostring(v)
			end
		end

		text = text.."</font>"

		local panel = self.scroll:Add("nutMarkupPanel")
		panel:SetPos(0, self.lastY)
		panel:SetWide(self:GetWide() - 8)
		panel:setMarkup(text, OnDrawText)
		panel.start = CurTime() + 15
		panel.finish = panel.start + 20
		panel.Think = function(this)
			if (self.active) then
				this:SetAlpha(255)
			else
				this:SetAlpha((1 - math.TimeFraction(this.start, this.finish, CurTime())) * 255)
			end
		end

		self.lastY = self.lastY + panel:GetTall() + 2
		self.scroll:ScrollToChild(panel)
	end
vgui.Register("nutChatBox", PANEL, "DPanel")