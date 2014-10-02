-- currently server verificaiton is not exist.
-- you can exploit the inventory with netstream.
local PANEL = {}
renderdIcons = renderdIcons or {}

function PANEL:Init()
end

function PANEL:PaintOver()
	local itemTable = LocalPlayer():getChar():getInv():getItemAt(self.gridX, self.gridY)

	if (itemTable and itemTable.paintOver) then
		local w, h = self:GetSize()

		itemTable.paintOver(self, itemTable, w, h)
	end
end

function PANEL:Paint()
	local parent = self:GetParent()
	local w, h = self:GetSize()

	surface.SetDrawColor(0, 0, 0, 85)
	surface.DrawRect(2, 2, w - 4, h - 4)

	if (self.clickPos) then
		local x, y = gui.MouseX() - self.clickPos.x, gui.MouseY() - self.clickPos.y
		
		self:SetPos(self.curPos.x + x, self.curPos.y + y)
		
		parent.offsetX = math.Round(x / 64)
		parent.offsetY = math.Round(y / 64)
	end	
end

vgui.Register("nutItemIcon", PANEL, "SpawnIcon")

PANEL = {}
	function PANEL:Init()
		if (IsValid(nut.gui.inv)) then
			nut.gui.inv:Remove()
		end
		
		nut.gui.inv = self


		self.panels = {}
		local created = {}

		if (LocalPlayer():getChar() and LocalPlayer():getChar():getInv().slots) then
			self:SetSize(64, 64)
			self:setGridSize(LocalPlayer():getChar():getInv():getSize())

			for x, items in pairs(LocalPlayer():getChar():getInv().slots) do
				for y, data in pairs(items) do
					if (!data.id) then continue end

					local item = nut.item.instances[data.id]

					if (item and !IsValid(self.panels[item.id])) then
						local icon = self:addIcon(item.model or "models/props_junk/popcan01a.mdl", x, y, item.width, item.height)

						if (IsValid(icon)) then
							icon:SetToolTip("Item #"..item.id.."\n"..L("itemInfo", item.name, (type(item.desc) == "function" and item.desc(item) or item.desc)))

							self.panels[item.id] = icon
						end
					end
				end
			end
		end
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
		local item = self.heldItem
		
		if (IsValid(item)) then
			local offsetX = self.offsetX
			local offsetY = self.offsetY
			
			for x = 0, item.gridW - 1 do
				for y = 0, item.gridH - 1 do
					local x2, y2 = item.gridX + offsetX + x, item.gridY + offsetY + y
					
					if (self:isValidSlot(x2, y2, item)) then
						surface.SetDrawColor(0, 255, 0, 30)
						
						if (x == 0 and y == 0) then
							self.dropPos = {x = (x2 - 1)*64 + 4, y = (y2 - 1)*64 + 27, x2 = x2, y2 = y2}
						end
					else
						surface.SetDrawColor(255, 0, 0, 30)
						self.dropPos = nil
					end
					
					surface.DrawRect((x2 - 1)*64 + 4, (y2 - 1)*64 + 27, 64, 64)
				end
			end
		end
	end
	
	function PANEL:isValidSlot(x, y, this)
		return self.slots[x] and IsValid(self.slots[x][y]) and (!IsValid(self.slots[x][y].item) or self.slots[x][y].item == this)
	end
	
	function PANEL:onTransfer(oldX, oldY, x, y)
		netstream.Start("invMove", oldX, oldY, x, y)

		local inventory = LocalPlayer():getChar():getInv()
		local item = inventory:getItemAt(oldX, oldY)

		inventory.slots[oldX][oldY] = nil
		inventory.slots[x] = inventory.slots[x] or {}
		inventory.slots[x][y] = item
	end

	function PANEL:addIcon(model, x, y, w, h)
		w = w or 1
		h = h or 1
		
		if (self.slots[x] and self.slots[x][y]) then
			local panel = self:Add("nutItemIcon")
			panel:SetSize(w * 64, h * 64)
			panel:SetZPos(1)
			panel:InvalidateLayout(true)
			panel:SetModel(model)
			panel:SetPos(self.slots[x][y]:GetPos())
			panel.gridX = x
			panel.gridY = y
			panel.gridW = w
			panel.gridH = h
			local itemTable = LocalPlayer():getChar():getInv():getItemAt(panel.gridX, panel.gridY)

			if ((itemTable.iconCam and !renderdIcons[itemTable.uniqueID]) or itemTable.forceRender) then
				local iconCam = itemTable.iconCam
				iconCam = {
					cam_pos = iconCam.pos,
					cam_fov = iconCam.fov,
					cam_ang = iconCam.ang,
				}
				renderdIcons[itemTable.uniqueID] = true
				
				panel.Icon:RebuildSpawnIconEx(
					iconCam
				)
			end

			panel.OnMousePressed = function(this, code)
				if (code == MOUSE_LEFT) then
					this:MouseCapture(true)
					this:NoClipping(true)
					this.clickPos = {x = gui.MouseX(), y = gui.MouseY()}
					this.curPos = {x = this.x, y = this.y}
					
					self.heldItem = this
				elseif (code == MOUSE_RIGHT and this.doRightClick) then
					this:doRightClick()
				end
			end
			panel.OnMouseReleased = function(this, code)
				if (code == MOUSE_LEFT and this.clickPos) then
					local data = self.dropPos
					
					if (data) then
						local oldX, oldY = this.gridX, this.gridY

						this.gridX = data.x2
						this.gridY = data.y2
						this:SetPos(data.x, data.y)
						
						if (panel.slots) then
							for k, v in ipairs(panel.slots) do
								if (IsValid(v)) then
									v.item = nil
								end
							end
						end
						
						panel.slots = {}
						self:onTransfer(oldX, oldY, this.gridX, this.gridY)
						
						for x = 1, this.gridW do
							for y = 1, this.gridH do
								local slot = self.slots[this.gridX + x-1][this.gridY + y-1]
								
								slot.item = panel
								panel.slots[#panel.slots + 1] = slot
							end
						end
					else
						local x, y = this.curPos.x, this.curPos.y
						
						this:SetPos(x, y)
					end
					
					this:MouseCapture(false)
					this:NoClipping(false)
					this.clickPos = nil
					this.curPos = nil
					
					self.heldItem = nil
				end
			end
			panel.doRightClick = function(this)
				
				if (itemTable) then
					itemTable.client = LocalPlayer()
						local menu = DermaMenu()
							for k, v in SortedPairs(itemTable.functions) do
								if (v.onCanRun) then
									if (v.onCanRun(itemTable) == false) then
										itemTable.client = nil

										continue
									end
								end

								menu:AddOption(L(v.name or k), function()
									netstream.Start("invAct", k, itemTable.id)
								end):SetImage(itemTable.icon or "icon16/brick.png")
							end
						menu:Open()
					itemTable.client = nil
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
vgui.Register("nutInventory", PANEL, "EditablePanel")

hook.Add("CreateMenuButtons", "nutInventory", function(tabs)
	tabs["inv"] = function(panel)
		panel:Add("nutInventory")
	end
end)