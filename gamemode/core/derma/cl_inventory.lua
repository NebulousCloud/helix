-- The queue for the rendered icons.
renderdIcons = renderdIcons or {}

-- To make making inventory variant, This must be followed up.
function renderNewIcon(panel, itemTable)
	-- re-render icons
	if ((itemTable.iconCam and !renderdIcons[string.lower(itemTable.model)]) or itemTable.forceRender) then
		local iconCam = itemTable.iconCam
		iconCam = {
			cam_pos = iconCam.pos,
			cam_fov = iconCam.fov,
			cam_ang = iconCam.ang,
		}
		renderdIcons[string.lower(itemTable.model)] = true
		
		panel.Icon:RebuildSpawnIconEx(
			iconCam
		)
	end
end

local PANEL = {}

function PANEL:Init()
	self:Droppable("inv")
end

function PANEL:PaintOver(w, h)
	local itemTable = nut.item.instances[self.itemID]

	if (self.waiting and self.waiting > CurTime()) then
		local wait = (self.waiting - CurTime()) / self.waitingTime
		surface.SetDrawColor(255, 255, 255, 100*wait)
		surface.DrawRect(2, 2, w - 4, h - 4)
	end

	if (itemTable and itemTable.paintOver) then
		local w, h = self:GetSize()

		itemTable.paintOver(self, itemTable, w, h)
	end
end

function PANEL:Paint(w, h)
	local parent = self:GetParent()

	surface.SetDrawColor(0, 0, 0, 85)
	surface.DrawRect(2, 2, w - 4, h - 4)
end

function PANEL:wait(time)
	time = math.abs(time) or .2
	self.waiting = CurTime() + time
	self.waitingTime = time
end

function PANEL:isWaiting()
	if (self.waiting and self.waitingTime) then
		return (self.waiting and self.waiting > CurTime())
	end
end

vgui.Register("nutItemIcon", PANEL, "SpawnIcon")

PANEL = {}
	function PANEL:Init()
		self:ShowCloseButton(false)
		self:SetDraggable(true)
		self:MakePopup()
		self:SetTitle(L"inv")

		self.panels = {}
	end
		
	function PANEL:OnRemove()
		if (self.childPanels) then
			for k, v in ipairs(self.childPanels) do
				if (v != self) then
					v:Remove()
				end
			end
		end
	end

	function PANEL:setInventory(inventory)
		if (inventory.slots) then
			if (IsValid(nut.gui.inv1) and nut.gui.inv1.childPanels and inventory != LocalPlayer():getChar():getInv()) then
				table.insert(nut.gui.inv1.childPanels, self)
			end

			self.invID = inventory:getID()
			self:SetSize(64, 64)
			self:setGridSize(inventory:getSize())

			for x, items in pairs(inventory.slots) do
				for y, data in pairs(items) do
					if (!data.id) then continue end

					local item = nut.item.instances[data.id]

					if (item and !IsValid(self.panels[item.id])) then
						local icon = self:addIcon(item.model or "models/props_junk/popcan01a.mdl", x, y, item.width, item.height)

						if (IsValid(icon)) then
							icon:SetToolTip("Item #"..item.id.."\n"..L("itemInfo", L(item.name), L(item:getDesc())))
							icon.itemID = item.id

							self.panels[item.id] = icon
						end
					end
				end
			end
		end

		self:Center()
	end

	function PANEL:setGridSize(w, h)
		self.gridW = w
		self.gridH = h
		
		self:SetSize(w * 64 + 8, h * 64 + 31)
		self:buildSlots()
	end
	
	function PANEL:buildSlots()
		self.slots = self.slots or {}
		
		local function PaintSlot(slot, w, h)
			surface.SetDrawColor(35, 35, 35, 85)
			surface.DrawRect(1, 1, w - 2, h - 2)
			
			surface.SetDrawColor(0, 0, 0, 250)
			surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
		end
		
		for k, v in ipairs(self.slots) do
			for k2, v2 in ipairs(v) do
				v2:Remove()
			end
		end
		
		self.slots = {}
		
		for x = 1, self.gridW do
			self.slots[x] = {}
			
			for y = 1, self.gridH do
				local slot = self:Add("DPanel")
				slot:SetZPos(-999)
				slot.gridX = x
				slot.gridY = y
				slot:SetPos((x - 1) * 64 + 4, (y - 1) * 64 + 27)
				slot:SetSize(64, 64)
				slot.Paint = PaintSlot
				
				self.slots[x][y] = slot	
			end
		end
	end
	
	function PANEL:PaintOver(w, h)
		local item = nut.item.held
		
		if (IsValid(item)) then
			local mouseX, mouseY = self:LocalCursorPos()
			local dropX, dropY = math.ceil((mouseX - 4 - (item.gridW - 1) * 32) / 64), math.ceil((mouseY - 27 - (item.gridH - 1) * 32) / 64)

			for x = 0, item.gridW - 1 do
				for y = 0, item.gridH - 1 do
					local x2, y2 = dropX + x, dropY + y

					if (self:isValidSlot(x2, y2, item)) then
						surface.SetDrawColor(0, 255, 0, 10)
						
						if (x == 0 and y == 0) then
							item.dropPos = item.dropPos or {}
							item.dropPos[self] = {x = (x2 - 1)*64 + 4, y = (y2 - 1)*64 + 27, x2 = x2, y2 = y2}
						end
					else
						surface.SetDrawColor(255, 0, 0, 10)
						
						if (item.dropPos) then
							item.dropPos[self] = nil
						end
					end
					
					surface.DrawRect((x2 - 1)*64 + 4, (y2 - 1)*64 + 27, 64, 64)
				end
			end
		end
	end
	
	function PANEL:isValidSlot(x, y, this)
		return self.slots[x] and IsValid(self.slots[x][y]) and (!IsValid(self.slots[x][y].item) or self.slots[x][y].item == this)
	end
	
	function PANEL:onTransfer(oldX, oldY, x, y, oldInventory, noSend)
		local inventory = nut.item.inventories[oldInventory.invID]
		local inventory2 = nut.item.inventories[self.invID]
		local item

		if (inventory) then
			item = inventory:getItemAt(oldX, oldY)

			if (item.onCanBeTransfered and item:onCanBeTransfered(inventory, inventory != inventory2 and inventory2 or nil) == false) then
				return false
			end
		end

		if (!noSend) then
			if (self != oldInventory) then
				netstream.Start("invMv", oldX, oldY, x, y, oldInventory.invID, self.invID)
			else
				netstream.Start("invMv", oldX, oldY, x, y, oldInventory.invID)
			end
		end

		if (inventory) then			
			inventory.slots[oldX][oldY] = nil
		end

		if (item and inventory2) then
			inventory2.slots[x] = inventory2.slots[x] or {}
			inventory2.slots[x][y] = item
		end
	end

	function PANEL:addIcon(model, x, y, w, h)
		w = w or 1
		h = h or 1
		
		if (self.slots[x] and self.slots[x][y]) then
			local panel = self:Add("nutItemIcon")
			panel:SetSize(w * 64, h * 64)
			panel:SetZPos(999)
			panel:InvalidateLayout(true)
			panel:SetModel(model)
			panel:SetPos(self.slots[x][y]:GetPos())
			panel.gridX = x
			panel.gridY = y
			panel.gridW = w
			panel.gridH = h

			local inventory = nut.item.inventories[self.invID]

			if (!inventory) then
				return
			end

			panel.inv = inventory

			local itemTable = inventory:getItemAt(panel.gridX, panel.gridY)

			if (self.panels[itemTable:getID()]) then
				self.panels[itemTable:getID()]:Remove()
			end

			renderNewIcon(panel, itemTable)

			panel.move = function(this, data, inventory, noSend)
				local oldX, oldY = this.gridX, this.gridY
				local oldParent = this:GetParent()

				if (inventory:onTransfer(oldX, oldY, data.x2, data.y2, oldParent, noSend) == false) then
					return
				end

				data.x = data.x or (data.x2 - 1)*64 + 4
				data.y = data.y or (data.y2 - 1)*64 + 27

				this.gridX = data.x2
				this.gridY = data.y2
				this.invID = inventory.invID
				this:SetParent(inventory)
				this:SetPos(data.x, data.y)

				if (this.slots) then
					for k, v in ipairs(this.slots) do
						if (IsValid(v) and v.item == this) then
							v.item = nil
						end
					end
				end
				
				this.slots = {}

				for x = 1, this.gridW do
					for y = 1, this.gridH do
						local slot = inventory.slots[this.gridX + x-1][this.gridY + y-1]

						slot.item = this
						this.slots[#this.slots + 1] = slot
					end
				end
			end
			panel.OnMousePressed = function(this, code)
				if (code == MOUSE_LEFT) then
					this:DragMousePress(code)
					this:MouseCapture(true)

					nut.item.held = this
				elseif (code == MOUSE_RIGHT and this.doRightClick) then
					this:doRightClick()
				end
			end
			panel.OnMouseReleased = function(this, code)
				if (code == MOUSE_LEFT and nut.item.held == this) then
					local data = this.dropPos

					this:DragMouseRelease(code)
					this:MouseCapture(false)
					this:SetZPos(99)

					nut.item.held = nil

					if (data) then
						local inventory = table.GetFirstKey(data)

						if (IsValid(inventory)) then
							data = data[inventory]
							local oldX, oldY = this.gridX, this.gridY

							if (oldX != data.x2 or oldY != data.y2 or inventory != self) then
								this:move(data, inventory)
							end
						end
					end
				end
			end
			panel.doRightClick = function(this)
				if (itemTable) then
					itemTable.player = LocalPlayer()
						local menu = DermaMenu()
							for k, v in SortedPairs(itemTable.functions) do
								if (v.onCanRun) then
									if (v.onCanRun(itemTable) == false) then
										itemTable.player = nil

										continue
									end
								end

								menu:AddOption(L(v.name or k), function()
									itemTable.player = LocalPlayer()
										local send = true

										if (v.onClick) then
											send = v.onClick(itemTable)
										end

										if (v.sound) then
											surface.PlaySound(v.sound)
										end

										if (send != false) then
											netstream.Start("invAct", k, itemTable.id, self.invID)
										end
									itemTable.player = nil
								end):SetImage(v.icon or "icon16/brick.png")
							end
						menu:Open()
					itemTable.player = nil
				end
			end
			
			panel.slots = {}
			
			for i = 0, w - 1 do
				for i2 = 0, h - 1 do
					local slot = self.slots[x + i] and self.slots[x + i][y + i2]

					if (IsValid(slot)) then
						slot.item = panel
						panel.slots[#panel.slots + 1] = slot
					else
						for k, v in ipairs(panel.slots) do
							v.item = nil
						end

						panel:Remove()

						return
					end
				end
			end
			
			return panel
		end
	end
vgui.Register("nutInventory", PANEL, "DFrame")

hook.Add("CreateMenuButtons", "nutInventory", function(tabs)
	if (hook.Run("CanPlayerViewInventory") != false) then
		tabs["inv"] = function(panel)		
			nut.gui.inv1 = panel:Add("nutInventory")
			nut.gui.inv1.childPanels = {}

			local inventory = LocalPlayer():getChar():getInv()

			if (inventory) then
				nut.gui.inv1:setInventory(inventory)
			end
		end
	end
end)
