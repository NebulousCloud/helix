
local PANEL = {}

AccessorFunc(PANEL, "titleBackground", "TitleBackground") -- set to nil to default to config color

function PANEL:Init()
	self.titleBar = vgui.Create("Panel", self)
	self.titleBar:Dock(TOP)

	self.title = vgui.Create("DLabel", self.titleBar)
	self.title:SetText("Title")
	self.title:SetColor(color_white)
	self.title:SetExpensiveShadow(1, color_black)
	self.title:SetContentAlignment(4)
	self.title:SizeToContents()
	self.title:DockMargin(4, 0, 0, 0)
	self.title:Dock(LEFT)

	self.subTitle = vgui.Create("DLabel", self.titleBar)
	self.subTitle:SetText("Subtitle")
	self.subTitle:SetColor(color_white)
	self.subTitle:SetExpensiveShadow(1, color_black)
	self.subTitle:SetContentAlignment(4)
	self.subTitle:SizeToContents()
	self.subTitle:DockMargin(0, 0, 4, 0)
	self.subTitle:Dock(RIGHT)

	self.canvas = vgui.Create("Panel", self)
	self.canvas:DockMargin(4, 4, 4, 0)
	self.canvas:Dock(FILL)

	self:SetFont("ixMediumFont")
	self:SetTitle("Info")
	self:SetSubtitle("")
	self:SetTitleBackground(nil)
end

function PANEL:SizeToContents()
	self.canvas:InvalidateLayout(true)
	self:InvalidateLayout(true)

	self.canvas:SizeToChildren(true, true)
	self:SizeToChildren(true, true)

	-- dock padding
	self:SetSize(self:GetWide(), self:GetTall() + 4)
end

function PANEL:Add(name)
	return self.canvas:Add(name)
end

function PANEL:SetTitle(text)
	self.title:SetText(text)
	self.title:SizeToContents()
end

function PANEL:SetSubtitle(text)
	self.subTitle:SetText(text)
	self.subTitle:SizeToContents()
end

function PANEL:SetFont(font)
	self.title:SetFont(font)
	self.subTitle:SetFont(font)
end

function PANEL:GetTitle()
	return self.title:GetText()
end

function PANEL:Paint(width, height)
	local titleBackground = self.titleBackground

	if (!IsColor(titleBackground)) then
		titleBackground = ix.config.Get("color")
	end

	-- background
	ix.util.DrawBlur(self, 10)

	surface.SetDrawColor(30, 30, 30, 100)
	surface.DrawRect(0, 0, width, height)

	-- title bar
	surface.SetDrawColor(titleBackground)
	surface.DrawRect(0, 0, width, self.title:GetTall())

	-- outline
	surface.SetDrawColor(0, 0, 0, 150)
	surface.DrawOutlinedRect(0, 0, width, height)
end

vgui.Register("ixInfoPanel", PANEL, "EditablePanel")

PANEL = {}
function PANEL:Init()
	if (IsValid(ix.gui.info)) then
		ix.gui.info:Remove()
	end

	ix.gui.info = self

	self:Dock(FILL)
	self:Center()

	local suppress = hook.Run("CanCreateCharInfo", self)

	if (!suppress or (suppress and !suppress.all)) then
		if (!suppress or !suppress.model) then
			self.model = self:Add("ixModelPanel")
			self.model:SetWide(ScrW() * 0.25)
			self.model:Dock(LEFT)
			self.model:SetFOV(50)
			self.model.enableHook = true
			self.model.copyLocalSequence = true
		end

		if (!suppress or !suppress.info) then
			self.info = self:Add("DPanel")
			self.info:SetWide(ScrW() * 0.4)
			self.info:Dock(RIGHT)
			self.info:SetDrawBackground(false)
			self.info:DockMargin(0, ScrH() * 0.15, 0, 0)
		end

		if (!suppress or !suppress.time) then
			self.time = self.info:Add("DLabel")
			self.time:SetFont("ixMediumFont")
			self.time:SetTall(28)
			self.time:SetContentAlignment(5)
			self.time:Dock(TOP)
			self.time:SetTextColor(color_white)
			self.time:SetExpensiveShadow(1, Color(0, 0, 0, 150))
			self.time:DockMargin(0, 0, 0, 16)
		end

		if (!suppress or !suppress.basicInfo) then
			self.basicInfo = self.info:Add("ixInfoPanel")
			self.basicInfo:SetTitle(L("you"))
			self.basicInfo:Dock(TOP)

			if (!suppress or !suppress.description) then
				local lDesc = L"description"
				local lCmdCharDesc = L"cmdCharDesc"
				local lSave = L"save"
				local lClose = L"close"

				self.description = self.basicInfo:Add("DLabel")
				self.description:SetFont("ixMediumFont")
				self.description:SetTextColor(color_white)
				self.description:SetExpensiveShadow(1, Color(0, 0, 0, 150))
				self.description:SetWide(self.info:GetWide())
				self.description:SetContentAlignment(5)
				self.description:Dock(TOP)
				self.description:SetMouseInputEnabled(true)
				self.description:SetCursor("hand")
				self.description.DoClick = function(this)
					Derma_StringRequest(lDesc, lCmdCharDesc, self.description:GetText(), function(desc)
							RunConsoleCommand("ix", "CharDesc", desc)
					end, nil, lSave, lClose)
				end
			end

			if (!suppress or !suppress.money) then
				self.money = self.basicInfo:Add("DLabel")
				self.money:SetFont("ixMediumFont")
				self.money:SetTextColor(color_white)
				self.money:SetExpensiveShadow(1, Color(0, 0, 0, 150))
				self.money:DockMargin(0, 8, 0, 0)
				self.money:Dock(TOP)
			end

			if (!suppress or !suppress.class) then
				local class = ix.class.list[LocalPlayer():GetChar():GetClass()]

				if (class) then
					self.class = self.basicInfo:Add("DLabel")
					self.class:Dock(TOP)
					self.class:SetFont("ixMediumFont")
					self.class:SetTextColor(color_white)
					self.class:SetExpensiveShadow(1, Color(0, 0, 0, 150))
				end
			end
		end

		hook.Run("CreateCharInfoText", self)

		if (!suppress or !suppress.attrib) then
			self.attribInfo = self.info:Add("ixInfoPanel")
			self.attribInfo:SetTitle(L"attributes")
			self.attribInfo:DockMargin(0, 16, 0, 0)
			self.attribInfo:Dock(TOP)
		end
	end

	hook.Run("CreateCharInfo", self)
end

function PANEL:Setup()
	local char = LocalPlayer():GetChar()
	local factionName = team.GetName(LocalPlayer():Team())

	if (self.basicInfo) then
		if (self.description) then
			self.description:SetText(char:GetDescription())
			self.description:SizeToContents()
		end

		if (self.money) then
			self.money:SetText(L("charMoney", char:GetMoney()))
			self.money:SizeToContents()
		end

		if (self.time) then
			local format = "%A, %B %d, %Y. %X"

			self.time:SetText(os.date(format, ix.date.Get()))
			self.time.Think = function(this)
				if ((this.nextTime or 0) < CurTime()) then
					this:SetText(os.date(format, ix.date.Get()))
					this.nextTime = CurTime() + 0.5
				end
			end
		end

		if (self.class) then
			local class = ix.class.list[char:GetClass()]

			-- don't show class label if the class is the same name as the faction
			if (class and class.name != factionName) then
				self.class:SetText(L("charClass", L(class.name)))
			else
				self.class:SetVisible(false)
			end

			self.class:SizeToContents()
		end

		if (self.model) then
			self.model:SetModel(LocalPlayer():GetModel())
			self.model.Entity:SetSkin(LocalPlayer():GetSkin())

			for _, v in ipairs(LocalPlayer():GetBodyGroups()) do
				self.model.Entity:SetBodygroup(v.id, LocalPlayer():GetBodygroup(v.id))
			end

			local ent = self.model.Entity

			if (ent and IsValid(ent)) then
				local mats = LocalPlayer():GetMaterials()

				for k, _ in pairs(mats) do
					ent:SetSubMaterial(k - 1, LocalPlayer():GetSubMaterial(k - 1))
				end
			end
		end

		self.basicInfo:SetTitle(LocalPlayer():GetName())
		self.basicInfo:SetSubtitle(team.GetName(LocalPlayer():Team()))
		self.basicInfo:SetTitleBackground(team.GetColor(LocalPlayer():Team()))
		self.basicInfo:SizeToContents()
	end

	if (self.attribInfo) then
		local boost = char:GetBoosts()

		for k, v in SortedPairsByMemberValue(ix.attributes.list, "name") do
			local attribBoost = 0
			if (boost[k]) then
				for _, bValue in pairs(boost[k]) do
					attribBoost = attribBoost + bValue
				end
			end

			local bar = self.attribInfo:Add("ixAttribBar")
			bar:Dock(TOP)
			bar:DockMargin(0, 0, 0, 3)

			local attribValue = char:GetAttrib(k, 0)
			if (attribBoost) then
				bar:SetValue(attribValue - attribBoost or 0)
			else
				bar:SetValue(attribValue)
			end

			local maximum = v.maxValue or ix.config.Get("maxAttributes", 30)
			bar:SetMax(maximum)
			bar:SetReadOnly()
			bar:SetText(Format("%s [%.1f/%.1f] (%.1f", L(v.name), attribValue, maximum, attribValue/maximum*100) .. "%)")

			if (attribBoost) then
				bar:SetBoost(attribBoost)
			end
		end

		self.attribInfo:SizeToContents()
	end

	hook.Run("OnCharInfoSetup", self)
end

vgui.Register("ixCharInfo", PANEL, "EditablePanel")

hook.Add("CreateMenuButtons", "ixCharInfo", function(tabs)
	tabs["you"] = function(panel, button, menu)
		menu.title:SetVisible(false)

		local info = panel:Add("ixCharInfo")
		info:Setup()
	end
end)
