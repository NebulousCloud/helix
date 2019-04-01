
local PANEL = {}

function PANEL:Init()
	self:SetTall(64)

	local function AssignClick(panel)
		panel.OnMousePressed = function()
			self.pressing = -1
			self:OnClick()
		end

		panel.OnMouseReleased = function()
			if (self.pressing) then
				self.pressing = nil
			end
		end
	end


	self.icon = self:Add("SpawnIcon")
	self.icon:SetSize(128, 64)
	self.icon:InvalidateLayout(true)
	self.icon:Dock(LEFT)
	self.icon.PaintOver = function(this, w, h)
	end
	AssignClick(self.icon)

	self.limit = self:Add("DLabel")
	self.limit:Dock(RIGHT)
	self.limit:SetMouseInputEnabled(true)
	self.limit:SetCursor("hand")
	self.limit:SetExpensiveShadow(1, Color(0, 0, 60))
	self.limit:SetContentAlignment(5)
	self.limit:SetFont("ixMediumFont")
	self.limit:SetWide(64)
	AssignClick(self.limit)

	self.label = self:Add("DLabel")
	self.label:Dock(FILL)
	self.label:SetMouseInputEnabled(true)
	self.label:SetCursor("hand")
	self.label:SetExpensiveShadow(1, Color(0, 0, 60))
	self.label:SetContentAlignment(5)
	self.label:SetFont("ixMediumFont")
	AssignClick(self.label)
end

function PANEL:OnClick()
	ix.command.Send("BecomeClass", self.class)
end

function PANEL:SetNumber(number)
	local limit = self.data.limit

	if (limit > 0) then
		self.limit:SetText(Format("%s/%s", number, limit))
	else
		self.limit:SetText("∞")
	end
end

function PANEL:SetClass(data)
	if (data.model) then
		local model = data.model
		if (istable(model)) then
			model = table.Random(model)
		end

		self.icon:SetModel(model)
	else
		local char = LocalPlayer():GetCharacter()
		local model = LocalPlayer():GetModel()

		if (char) then
			model = char:GetModel()
		end

		self.icon:SetModel(model)
	end

	self.label:SetText(L(data.name))
	self.data = data
	self.class = data.index

	self:SetNumber(#ix.class.GetPlayers(data.index))
end

vgui.Register("ixClassPanel", PANEL, "DPanel")

PANEL = {}

function PANEL:Init()
	ix.gui.classes = self

	self:SetSize(self:GetParent():GetSize())

	self.list = vgui.Create("DPanelList", self)
	self.list:Dock(FILL)
	self.list:EnableVerticalScrollbar()
	self.list:SetSpacing(5)
	self.list:SetPadding(5)

	self.classPanels = {}
	self:LoadClasses()
end

function PANEL:LoadClasses()
	self.list:Clear()

	for k, v in ipairs(ix.class.list) do
		local no, why = ix.class.CanSwitchTo(LocalPlayer(), k)
		local itsFull = ("class is full" == why)

		if (no or itsFull) then
			local panel = vgui.Create("ixClassPanel", self.list)
			panel:SetClass(v)
			table.insert(self.classPanels, panel)

			self.list:AddItem(panel)
		end
	end
end

vgui.Register("ixClasses", PANEL, "EditablePanel")

hook.Add("CreateMenuButtons", "ixClasses", function(tabs)
	local cnt = table.Count(ix.class.list)

	if (cnt <= 1) then return end

	for k, _ in ipairs(ix.class.list) do
		if (!ix.class.CanSwitchTo(LocalPlayer(), k)) then
			continue
		else
			tabs["classes"] = function(container)
				container:Add("ixClasses")
			end

			return
		end
	end
end)

net.Receive("ixClassUpdate", function()
	local client = net.ReadEntity()

	if (ix.gui.classes and ix.gui.classes:IsVisible()) then
		if (client == LocalPlayer()) then
			ix.gui.classes:LoadClasses()
		else
			for _, v in ipairs(ix.gui.classes.classPanels) do
				local data = v.data

				v:SetNumber(#ix.class.GetPlayers(data.index))
			end
		end
	end
end)
