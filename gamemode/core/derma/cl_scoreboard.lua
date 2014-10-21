local PANEL = {}
	local paintFunctions = {}
	paintFunctions[0] = function(this, w, h)
		surface.SetDrawColor(0, 0, 0, 50)
		surface.DrawRect(0, 0, w, h)
	end
	paintFunctions[1] = function(this, w, h)
	end

	function PANEL:Init()
		if (IsValid(nut.gui.score)) then
			nut.gui.score:Remove()
		end

		nut.gui.score = self

		self:SetSize(ScrW() * 0.325, ScrH() * 0.825)
		self:Center()

		self.title = self:Add("DLabel")
		self.title:SetText(GetConVarString("hostname"))
		self.title:SetFont("nutBigFont")
		self.title:SetContentAlignment(5)
		self.title:SetTextColor(color_white)
		self.title:SetExpensiveShadow(1, color_black)
		self.title:Dock(TOP)
		self.title:SizeToContentsY()
		self.title:SetTall(self.title:GetTall() + 16)
		self.title.Paint = function(this, w, h)
			surface.SetDrawColor(0, 0, 0, 150)
			surface.DrawRect(0, 0, w, h)
		end

		self.scroll = self:Add("DListLayout")
		self.scroll:Dock(FILL)
		self.scroll:DockMargin(1, 0, 1, 0)

		self.nextUpdate = 0

		self:populate()
	end

	function PANEL:populate()
		self.scroll:Clear()
		self.teams = {}
		self.tallies = {}

		for k, v in ipairs(nut.faction.indices) do
			self.teams[k] = {}

			local color = team.GetColor(k)
			local r, g, b = color.r, color.g, color.b

			local list = self.scroll:Add("DListLayout")
			list:Dock(TOP)
			list:SetTall(0)

			local panel = list:Add("DLabel")
			panel:Dock(TOP)
			panel.Paint = function(this, w, h)
				surface.SetDrawColor(r, g, b, 50)
				surface.DrawRect(0, 0, w, h)
			end
			panel:SetText(L(v.name))
			panel:SetTall(0)
			panel:SetTextInset(3, 0)
			panel:SetFont("nutMediumFont")
			panel:SetTextColor(color_white)
			panel:SetExpensiveShadow(1, color_black)
			panel.Think = function()
				local players = team.NumPlayers(k)
				local tall = panel:GetTall()

				if (players > 0 and tall == 0) then
					panel:SetTall(28)
				elseif (players < 1 and tall == 28) then
					panel:SetTall(0)
				end
			end

			self.teams[k] = list
			self.tallies[k] = team.NumPlayers(k)

			self.i = 0

			for k, v in ipairs(team.GetPlayers(k)) do
				self:addPlayer(v, list)
			end
		end
	end

	function PANEL:Think()
		if (self.nextUpdate < CurTime()) then
			for k, v in ipairs(nut.faction.indices) do
				local players = team.GetPlayers(k)

				if ((self.tallies[k] or 0) != #players) then
					for k2, v2 in ipairs(players) do
						if (!IsValid(v2.nutScoreSlot)) then
							self:addPlayer(v2, self.teams[k])
						end
					end

					self.tallies[k] = #players
				end
			end

			self.nextUpdate = CurTime() + 0.25
		end
	end

	function PANEL:addPlayer(client, parent)
		local slot = parent:Add("DPanel")
		slot:Dock(TOP)
		slot:SetTall(64)
		slot:DockMargin(0, 0, 0, 1)
		slot.Paint = paintFunctions[self.i]

		client.nutScoreSlot = slot

		slot.model = slot:Add("SpawnIcon")
		slot.model:SetModel(client:GetModel())
		slot.model:SetSize(64, 64)
		slot.model.PaintOver = function() end
		slot.model:SetToolTip(L("sbOptions", client:Name()))
		slot.model.OnMousePressed = function()
			local menu = DermaMenu()
				hook.Run("ShowPlayerOptions", client, menu)
			menu:Open()
		end

		slot.name = slot:Add("DLabel")
		slot.name:SetText(client:Name())
		slot.name:Dock(TOP)
		slot.name:DockMargin(65, 0, 48, 0)
		slot.name:SetTall(18)
		slot.name:SetFont("nutGenericFont")
		slot.name:SetTextColor(color_white)
		slot.name:SetExpensiveShadow(1, color_black)

		slot.ping = slot:Add("DLabel")
		slot.ping:SetPos(self:GetWide() - 48, 0)
		slot.ping:SetSize(48, 64)
		slot.ping:SetText("0")
		slot.ping.Think = function(this)
			if (IsValid(client)) then
				this:SetText(client:Ping())
			else
				slot:Remove()
			end
		end
		slot.ping:SetFont("nutGenericFont")
		slot.ping:SetContentAlignment(6)
		slot.ping:SetTextColor(color_white)
		slot.ping:SetTextInset(16, 0)
		slot.ping:SetExpensiveShadow(1, color_black)

		slot.desc = slot:Add("DLabel")
		slot.desc:Dock(FILL)
		slot.desc:DockMargin(65, 0, 48, 0)
		slot.desc:SetWrap(true)
		slot.desc:SetContentAlignment(7)
		slot.desc:SetText(client:getChar() and client:getChar():getDesc())
		slot.desc:SetTextColor(color_white)
		slot.desc:SetExpensiveShadow(1, Color(0, 0, 0, 100))
		slot.desc:SetFont("nutSmallFont")

		self.i = math.abs(self.i - 1)

		return slot
	end

	function PANEL:Paint(w, h)
		nut.util.drawBlur(self, 10)

		surface.SetDrawColor(30, 30, 30, 100)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
vgui.Register("nutScoreboard", PANEL, "EditablePanel")