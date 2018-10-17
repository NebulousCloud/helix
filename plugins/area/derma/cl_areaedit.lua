
local PLUGIN = PLUGIN
local PANEL = {}

function PANEL:Init()
	if (IsValid(ix.gui.areaEdit)) then
		ix.gui.areaEdit:Remove()
	end

	ix.gui.areaEdit = self
	self.list = {}
	self.properties = {}

	self:SetDeleteOnClose(true)
	self:SetSizable(true)
	self:SetTitle(L("areaNew"))

	-- scroll panel
	self.canvas = self:Add("DScrollPanel")
	self.canvas:Dock(FILL)

	-- name entry
	self.nameEntry = vgui.Create("ixTextEntry")
	self.nameEntry:SetFont("ixMenuButtonFont")
	self.nameEntry:SetText(L("areaNew"))

	local listRow = self.canvas:Add("ixListRow")
	listRow:SetList(self.list)
	listRow:SetLabelText(L("name"))
	listRow:SetRightPanel(self.nameEntry)
	listRow:Dock(TOP)
	listRow:SizeToContents()

	-- type entry
	self.typeEntry = self.canvas:Add("DComboBox")
	self.typeEntry:Dock(RIGHT)
	self.typeEntry:SetFont("ixMenuButtonFont")
	self.typeEntry:SetTextColor(color_white)
	self.typeEntry.OnSelect = function(panel)
		panel:SizeToContents()
		panel:SetWide(panel:GetWide() + 12) -- padding for arrow (nice)
	end

	for id, name in pairs(ix.area.types) do
		self.typeEntry:AddChoice(L(name), id, id == "area")
	end

	listRow = self.canvas:Add("ixListRow")
	listRow:SetList(self.list)
	listRow:SetLabelText(L("type"))
	listRow:SetRightPanel(self.typeEntry)
	listRow:Dock(TOP)
	listRow:SizeToContents()

	-- properties
	for k, v in pairs(ix.area.properties) do
		local panel

		if (v.type == ix.type.string or v.type == ix.type.number) then
			panel = vgui.Create("ixTextEntry")
			panel:SetFont("ixMenuButtonFont")
			panel:SetText(tostring(v.default))

			if (v.type == ix.type.number) then
				panel.realGetValue = panel.GetValue
				panel.GetValue = function()
					return tonumber(panel:realGetValue()) or v.default
				end
			end
		elseif (v.type == ix.type.bool) then
			panel = vgui.Create("ixCheckBox")
			panel:SetChecked(v.default, true)
		elseif (v.type == ix.type.color) then
			panel = vgui.Create("DButton")
			panel.value = v.default
			panel:SetText("")
			panel:SetSize(64, 64)

			panel.picker = vgui.Create("DColorCombo")
			panel.picker:SetColor(panel.value)
			panel.picker:SetVisible(false)
			panel.picker.OnValueChanged = function(_, newColor)
				panel.value = newColor
			end

			panel.Paint = function(_, width, height)
				surface.SetDrawColor(Color(0, 0, 0, 255))
				surface.DrawOutlinedRect(0, 0, width, height)

				surface.SetDrawColor(panel.value)
				surface.DrawRect(4, 4, width - 8, height - 8)
			end

			panel.DoClick = function()
				if (!panel.picker:IsVisible()) then
					local x, y = panel:LocalToScreen(0, 0)

					panel.picker:SetPos(x, y + 32)
					panel.picker:SetColor(panel.value)
					panel.picker:SetVisible(true)
					panel.picker:MakePopup()
				else
					panel.picker:SetVisible(false)
				end
			end

			panel.OnRemove = function()
				panel.picker:Remove()
			end

			panel.GetValue = function()
				return panel.picker:GetColor()
			end
		end

		if (IsValid(panel)) then
			local row = self.canvas:Add("ixListRow")
			row:SetList(self.list)
			row:SetLabelText(L(k))
			row:SetRightPanel(panel)
			row:Dock(TOP)
			row:SizeToContents()
		end

		self.properties[k] = function()
			return panel:GetValue()
		end
	end

	-- save button
	self.saveButton = self:Add("DButton")
	self.saveButton:SetText(L("save"))
	self.saveButton:SizeToContents()
	self.saveButton:Dock(BOTTOM)
	self.saveButton.DoClick = function()
		self:Submit()
	end

	self:SizeToContents()
	self:SetPos(64, 0)
	self:CenterVertical()
end

function PANEL:SizeToContents()
	local width = 64
	local height = 37

	for _, v in ipairs(self.canvas:GetCanvas():GetChildren()) do
		width = math.max(width, v:GetLabelWidth())
		height = height + v:GetTall()
	end

	self:SetWide(width + 200)
	self:SetTall(height + self.saveButton:GetTall())
end

function PANEL:Submit()
	local name = self.nameEntry:GetValue()

	if (ix.area.stored[name]) then
		ix.util.NotifyLocalized("areaAlreadyExists")
		return
	end

	local properties = {}

	for k, v in pairs(self.properties) do
		properties[k] = v()
	end

	local _, type = self.typeEntry:GetSelected()

	net.Start("ixAreaAdd")
		net.WriteString(name)
		net.WriteString(type)
		net.WriteVector(PLUGIN.editStart)
		net.WriteVector(PLUGIN:GetPlayerAreaTrace().HitPos)
		net.WriteTable(properties)
	net.SendToServer()

	PLUGIN.editStart = nil
	self:Remove()
end

function PANEL:OnRemove()
	PLUGIN.editProperties = nil
end

vgui.Register("ixAreaEdit", PANEL, "DFrame")

if (IsValid(ix.gui.areaEdit)) then
	ix.gui.areaEdit:Remove()
end