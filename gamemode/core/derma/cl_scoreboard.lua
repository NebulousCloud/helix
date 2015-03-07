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

		self.scroll = self:Add("DScrollPanel")
		self.scroll:Dock(FILL)
		self.scroll:DockMargin(1, 0, 1, 0)
		self.scroll.VBar:SetWide(0)

		self.nextUpdate = 0
		self.players = {}
		self.slots = {}
		self.i = {}

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
			list.Think = function(this)
				if (#this:GetChildren() <= 1) then
					this:SetVisible(false)
				else
					this:SetVisible(true)
				end
			end

			local panel = list:Add("DLabel")
			panel:Dock(TOP)
			panel.Paint = function(this, w, h)
				surface.SetDrawColor(r, g, b, 50)
				surface.DrawRect(0, 0, w, h)
			end
			panel:SetText(L(v.name))
			panel:SetTextInset(3, 0)
			panel:SetFont("nutMediumFont")
			panel:SetTextColor(color_white)
			panel:SetExpensiveShadow(1, color_black)
			panel:SetTall(28)

			self.teams[k] = list
			self.tallies[k] = team.NumPlayers(k)

			self.i[k] = 0

			for k, v in ipairs(team.GetPlayers(k)) do
				self:addPlayer(v, list)
			end
		end
	end

	function PANEL:Think()
		if ((self.nextUpdate or 0) < CurTime()) then
			for k, v in ipairs(player.GetAll()) do
				if (v:getChar()) then
					if (!IsValid(v:getChar().nutScoreSlot)) then
						local teamID = v:Team()

						self:addPlayer(v, self.teams[teamID])
					end
				end
			end

			for k, v in pairs(self.slots) do
				if (IsValid(v)) then
					v:update()
				end
			end

			self.nextUpdate = CurTime() + 0.25
		end
	end

	function PANEL:addPlayer(client, parent)
		if (!client:getChar()) then return end

		if (!IsValid(parent)) then
			return self:populate()
		end

		local index = client:Team()

		parent:SetTall(28)

		local slot = parent:Add("DPanel")
		slot:Dock(TOP)
		slot:SetTall(64)
		slot:DockMargin(0, 0, 0, 1)
		slot.Paint = paintFunctions[self.i[index] or 0]
		slot.character = client:getChar()

		client:getChar().nutScoreSlot = slot

		slot.model = slot:Add("SpawnIcon")
		slot.model:SetModel(client:GetModel(), client:GetSkin())
		slot.model:SetSize(64, 64)
		slot.model.PaintOver = function() end
		slot.model.OnMousePressed = function()
			local menu = DermaMenu()
				local options = {}

				hook.Run("ShowPlayerOptions", client, options)

				if (table.Count(options) > 0) then
					for k, v in SortedPairs(options) do
						menu:AddOption(L2(k), v[2]):SetImage(v[1])
					end
				end
			menu:Open()

			RegisterDermaMenuForClose(menu)
		end
		slot.model:SetToolTip(L("sbOptions", client:Name()))

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

		function slot:update()
			if (!IsValid(client) or !client:getChar() or !self.character or self.character != client:getChar()) then
				return self:Remove()
			end

			local name = client:Name()
			local model = client:GetModel()
			local desc = client:getChar():getDesc()

			if (self.lastName != name) then
				self.name:SetText(name)
				self.lastName = name
			end

			if (self.lastModel != model) then
				self.model:SetModel(client:GetModel(), client:GetSkin())
				self.model:SetToolTip(L("sbOptions", client:Name()))
				self.lastModel = model
			end

			if (self.lastDesc != desc) then
				self.desc:SetText(desc)
				self.lastDesc = desc
			end
		end

		self.i[index] = math.abs(self.i[index] - 1)
		self.slots[#self.slots + 1] = slot

		parent:SetVisible(true)
		parent:SizeToChildren(false, true)
		parent:InvalidateLayout(true)

		return slot
	end

	function PANEL:OnRemove()
		CloseDermaMenus()
	end

	function PANEL:Paint(w, h)
		nut.util.drawBlur(self, 10)

		surface.SetDrawColor(30, 30, 30, 100)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(0, 0, 0, 150)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
vgui.Register("nutScoreboard", PANEL, "EditablePanel")

concommand.Add("dev_reloadsb", function()
	if (IsValid(nut.gui.score)) then
		nut.gui.score:Remove()
	end
end)