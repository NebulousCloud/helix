
local PANEL = {}

function PANEL:Init()
	self:SetSize(256, 280)
	self:Center()
	self:MakePopup()
	self:SetTitle(L"vendorFaction")
	self.scroll = self:Add("DScrollPanel")
	self.scroll:Dock(FILL)
	self.scroll:DockPadding(0, 0, 0, 4)

	self.factions = {}
	self.classes = {}

	for k, v in ipairs(ix.faction.indices) do
		local panel = self.scroll:Add("DPanel")
		panel:Dock(TOP)
		panel:DockPadding(4, 4, 4, 4)
		panel:DockMargin(0, 0, 0, 4)

		local faction = panel:Add("DCheckBoxLabel")
		faction:Dock(TOP)
		faction:SetText(L(v.name))
		faction:DockMargin(0, 0, 0, 4)
		faction.OnChange = function(this, state)
			self:updateVendor("faction", v.uniqueID)
		end

		self.factions[v.uniqueID] = faction

		for _, v2 in ipairs(ix.class.list) do
			if (v2.faction == k) then
				local class = panel:Add("DCheckBoxLabel")
				class:Dock(TOP)
				class:DockMargin(16, 0, 0, 4)
				class:SetText(L(v2.name))
				class.OnChange = function(this, state)
					self:updateVendor("class", v2.uniqueID)
				end

				self.classes[v2.uniqueID] = class

				panel:SetTall(panel:GetTall() + class:GetTall() + 4)
			end
		end
	end
end

function PANEL:Setup()
	for k, _ in pairs(self.entity.factions or {}) do
		self.factions[k]:SetChecked(true)
	end

	for k, _ in pairs(self.entity.classes or {}) do
		self.classes[k]:SetChecked(true)
	end
end

vgui.Register("ixVendorFactionEditor", PANEL, "DFrame")
