
local PANEL = {}

function PANEL:Init()
	self:SetSize(460, 360)
	self:SetTitle(L"shipment")
	self:Center()
	self:MakePopup()

	self.scroll = self:Add("DScrollPanel")
	self.scroll:Dock(FILL)

	self.list = self.scroll:Add("DListLayout")
	self.list:Dock(FILL)
end

function PANEL:SetItems(entity, items)
	self.entity = entity
	self.items = true
	self.itemPanels = {}

	for k, v in SortedPairs(items) do
		local itemTable = ix.item.list[k]

		if (itemTable) then
			local item = self.list:Add("DPanel")
			item:SetTall(36)
			item:Dock(TOP)
			item:DockMargin(4, 4, 4, 0)

			item.icon = item:Add("SpawnIcon")
			item.icon:SetPos(2, 2)
			item.icon:SetSize(32, 32)
			item.icon:SetModel(itemTable:GetModel())
			item.icon:SetHelixTooltip(function(tooltip)
				ix.hud.PopulateItemTooltip(tooltip, itemTable)
			end)

			item.quantity = item.icon:Add("DLabel")
			item.quantity:SetSize(32, 32)
			item.quantity:SetContentAlignment(3)
			item.quantity:SetTextInset(0, 0)
			item.quantity:SetText(v)
			item.quantity:SetFont("DermaDefaultBold")
			item.quantity:SetExpensiveShadow(1, Color(0, 0, 0, 150))

			item.name = item:Add("DLabel")
			item.name:SetPos(38, 0)
			item.name:SetSize(200, 36)
			item.name:SetFont("ixSmallFont")
			item.name:SetText(L(itemTable.name))
			item.name:SetContentAlignment(4)
			item.name:SetTextColor(color_white)

			item.take = item:Add("DButton")
			item.take:Dock(RIGHT)
			item.take:SetText(L"take")
			item.take:SetWide(48)
			item.take:DockMargin(3, 3, 3, 3)
			item.take:SetTextColor(color_white)
			item.take.DoClick = function(this)
				net.Start("ixShipmentUse")
					net.WriteString(k)
					net.WriteBool(false)
				net.SendToServer()

				items[k] = items[k] - 1

				item.quantity:SetText(items[k])

				if (items[k] <= 0) then
					item:Remove()
					items[k] = nil
				end

				if (table.IsEmpty(items)) then
					self:Remove()
				end
			end

			item.drop = item:Add("DButton")
			item.drop:Dock(RIGHT)
			item.drop:SetText(L"drop")
			item.drop:SetWide(48)
			item.drop:DockMargin(3, 3, 0, 3)
			item.drop:SetTextColor(color_white)
			item.drop.DoClick = function(this)
				net.Start("ixShipmentUse")
					net.WriteString(k)
					net.WriteBool(true)
				net.SendToServer()

				items[k] = items[k] - 1

				item.quantity:SetText(items[k])

				if (items[k] <= 0) then
					item:Remove()
				end
			end

			self.itemPanels[k] = item
		end
	end
end

function PANEL:Think()
	if (self.items and !IsValid(self.entity)) then
		self:Remove()
	end
end

vgui.Register("ixShipment", PANEL, "DFrame")
