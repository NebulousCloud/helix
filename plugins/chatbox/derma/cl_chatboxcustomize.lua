
local PLUGIN = PLUGIN

local PANEL = {}

function PANEL:Init()
	ix.gui.chatTabCustomize = self

	self:SetTitle(L("chatNewTab"))
	self:SetSizable(true)
	self:SetSize(ScrW() * 0.5, ScrH() * 0.5)

	self.settings = self:Add("ixSettings")
	self.settings:Dock(FILL)
	self.settings:SetSearchEnabled(true)
	self.settings:AddCategory(L("chatAllowedClasses"))

	-- controls
	local controlsPanel = self:Add("Panel")
	controlsPanel:Dock(BOTTOM)
	controlsPanel:DockMargin(0, 4, 0, 0)
	controlsPanel:SetTall(32)

	self.create = controlsPanel:Add("DButton")
	self.create:SetText(L("create"))
	self.create:SizeToContents()
	self.create:Dock(FILL)
	self.create:DockMargin(0, 0, 4, 0)
	self.create.DoClick = ix.util.Bind(self, self.CreateClicked)

	local uncheckAll = controlsPanel:Add("DButton")
	uncheckAll:SetText(L("uncheckAll"))
	uncheckAll:SizeToContents()
	uncheckAll:Dock(RIGHT)
	uncheckAll.DoClick = function()
		self:SetAllValues(false)
	end

	local checkAll = controlsPanel:Add("DButton")
	checkAll:SetText(L("checkAll"))
	checkAll:SizeToContents()
	checkAll:Dock(RIGHT)
	checkAll:DockMargin(0, 0, 4, 0)
	checkAll.DoClick = function()
		self:SetAllValues(true)
	end

	-- chat class settings
	self.name = self.settings:AddRow(ix.type.string)
	self.name:SetText(L("chatTabName"))
	self.name:SetValue("New Tab")
	self.name:SetZPos(-1)

	for k, _ in SortedPairs(ix.chat.classes) do
		local panel = self.settings:AddRow(ix.type.bool, L("chatAllowedClasses"))
		panel:SetText(k)
		panel:SetValue(true, true)
	end

	self.settings:SizeToContents()
	self:Center()
	self:MakePopup()
end

function PANEL:PopulateFromTab(name, filter)
	self.tab = name

	self:SetTitle(L("chatCustomize"))
	self.create:SetText(L("update"))
	self.name:SetValue(name)

	for _, v in ipairs(self.settings:GetRows()) do
		if (filter[v:GetText()]) then
			v:SetValue(false, true)
		end
	end
end

function PANEL:SetAllValues(bValue)
	for _, v in ipairs(self.settings:GetRows()) do
		if (v == self.name) then
			continue
		end

		v:SetValue(tobool(bValue), true)
	end
end

function PANEL:CreateClicked()
	local name = self.tab and self.tab or self.name:GetValue()

	if (self.tab != self.name:GetValue() and PLUGIN:TabExists(name)) then
		ix.util.Notify(L("chatTabExists"))
		return
	end

	local filter = {}

	for _, v in ipairs(self.settings:GetRows()) do
		-- we only want to add entries for classes we don't want shown
		if (!v:GetValue()) then
			filter[v:GetText()] = true
		end
	end

	if (self.tab) then
		self:OnTabUpdated(name, filter, self.name:GetValue())
	else
		self:OnTabCreated(name, filter)
	end

	self:Remove()
end

function PANEL:OnTabCreated(id, filter)
end

function PANEL:OnTabUpdated(id, filter, newID)
end

vgui.Register("ixChatboxTabCustomize", PANEL, "DFrame")
