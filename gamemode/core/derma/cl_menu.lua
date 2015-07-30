local PANEL = {}
	local gradient = nut.util.getMaterial("vgui/gradient-u")
	local gradient2 = nut.util.getMaterial("vgui/gradient-d")
	local alpha = 80

	function PANEL:Init()
		if (IsValid(nut.gui.menu)) then
			nut.gui.menu:Remove()
		end

		nut.gui.menu = self

		self:SetSize(ScrW(), ScrH())
		self:SetAlpha(0)
		self:AlphaTo(255, 0.25, 0)
		self:SetPopupStayAtBack(true)

		self.tabs = self:Add("DHorizontalScroller")
		self.tabs:SetWide(0)
		self.tabs:SetTall(86)

		self.panel = self:Add("EditablePanel")
		self.panel:SetSize(ScrW() * 0.6, ScrH() * 0.65)
		self.panel:Center()
		self.panel:SetPos(self.panel.x, self.panel.y + 72)
		self.panel:SetAlpha(0)

		self.title = self:Add("DLabel")
		self.title:SetPos(self.panel.x, self.panel.y - 80)
		self.title:SetTextColor(color_white)
		self.title:SetExpensiveShadow(1, Color(0, 0, 0, 150))
		self.title:SetFont("nutTitleFont")
		self.title:SetText("")
		self.title:SetAlpha(0)
		self.title:SetSize(self.panel:GetWide(), 72)

		local tabs = {}

		hook.Run("CreateMenuButtons", tabs)

		self.tabList = {}
		
		for name, callback in SortedPairs(tabs) do
			if (type(callback) == "string") then
				local body = callback

				if (body:sub(1, 4) == "http") then
					callback = function(panel)
						local html = panel:Add("DHTML")
						html:Dock(FILL)
						html:OpenURL(body)
					end
				else
					callback = function(panel)
						local html = panel:Add("DHTML")
						html:Dock(FILL)
						html:SetHTML(body)
					end
				end
			end

			local tab = self:addTab(L(name), callback, name)
			self.tabList[name] = tab
		end
		--[[
		if (lastMenuTab and tabs[lastMenuTab]) then
			if (lastMenuTab == "characters") then
				lastMenuTab = nil
			else
				timer.Simple(.1, function()
					self.tabList[lastMenuTab]:DoClick()
				end)
			end
		end
		--]]
		self.noAnchor = CurTime() + .4
		self.anchorMode = true
		self:MakePopup()

		self.info = vgui.Create("nutCharInfo", self)
		self.info:setup()
		self.info:SetAlpha(0)
		self.info:AlphaTo(255, 0.5)
	end

	function PANEL:OnKeyCodePressed(key)
		self.noAnchor = CurTime() + .5

		if (key == KEY_F1) then
			self:remove()
		end
	end

	function PANEL:Think()
		local key = input.IsKeyDown(KEY_F1)
		if (key and (self.noAnchor or CurTime()+.4) < CurTime() and self.anchorMode == true) then
			self.anchorMode = false
			surface.PlaySound("buttons/lightswitch2.wav")
		end

		if (!self.anchorMode) then
			if (IsValid(self.info) and self.info.desc:IsEditing()) then
				return
			end

			if (!key) then
				self:remove()
			end
		end
	end

	local color_bright = Color(240, 240, 240, 180)

	function PANEL:Paint(w, h)
		nut.util.drawBlur(self, 12)

		surface.SetDrawColor(0, 0, 0)
		surface.SetMaterial(gradient)
		surface.DrawTexturedRect(0, 0, w, h)

		surface.SetDrawColor(30, 30, 30, alpha)
		surface.DrawRect(0, 0, w, 78)

		surface.SetDrawColor(color_bright)
		surface.DrawRect(0, 78, w, 8)
	end

	function PANEL:addTab(name, callback, uniqueID)
		name = L(name)

		local function paintTab(tab, w, h)
			if (self.activeTab == tab) then
				surface.SetDrawColor(ColorAlpha(nut.config.get("color"), 200))
				surface.DrawRect(0, h - 8, w, 8)
			elseif (tab.Hovered) then
				surface.SetDrawColor(0, 0, 0, 50)
				surface.DrawRect(0, h - 8, w, 8)
			end
		end

		surface.SetFont("nutMenuButtonLightFont")
		local w = surface.GetTextSize(name)

		local tab = self.tabs:Add("DButton")
			tab:SetSize(0, self.tabs:GetTall())
			tab:SetText(name)
			tab:SetPos(self.tabs:GetWide(), 0)
			tab:SetTextColor(Color(250, 250, 250))
			tab:SetFont("nutMenuButtonLightFont")
			tab:SetExpensiveShadow(1, Color(0, 0, 0, 150))
			tab:SizeToContentsX()
			tab:SetWide(w + 32)
			tab.Paint = paintTab
			tab.DoClick = function(this)
				if (IsValid(nut.gui.info)) then
					nut.gui.info:Remove()
				end
				
				self.panel:Clear()

				self.title:SetText(this:GetText())
				self.title:SizeToContentsY()
				self.title:AlphaTo(255, 0.5)
				self.title:MoveAbove(self.panel, 8)

				self.panel:AlphaTo(255, 0.5, 0.1)
				self.activeTab = this
				lastMenuTab = uniqueID

				if (callback) then
					callback(self.panel, this)
				end
			end
		self.tabs:AddPanel(tab)

		self.tabs:SetWide(math.min(self.tabs:GetWide() + tab:GetWide(), ScrW()))
		self.tabs:SetPos((ScrW() * 0.5) - (self.tabs:GetWide() * 0.5), 0)

		return tab
	end

	function PANEL:setActiveTab(key)
		if (IsValid(self.tabList[key])) then
			self.tabList[key]:DoClick()
		end
	end

	function PANEL:OnRemove()
	end

	function PANEL:remove()
		CloseDermaMenus()
		
		if (!self.closing) then
			self:AlphaTo(0, 0.25, 0, function()
				self:Remove()
			end)
			self.closing = true
		end
	end
vgui.Register("nutMenu", PANEL, "EditablePanel")

if (IsValid(nut.gui.menu)) then
	vgui.Create("nutMenu")
end