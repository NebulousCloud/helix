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
end

function PANEL:PaintOver(w, h)
	local itemTable = LocalPlayer():getChar():getInv():getItemAt(self.gridX, self.gridY)

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

	if (self.clickPos) then
		local x, y = gui.MouseX() - self.clickPos.x, gui.MouseY() - self.clickPos.y
		
		self:SetPos(self.curPos.x + x, self.curPos.y + y)
		
		parent.offsetX = math.Round(x / 64)
		parent.offsetY = math.Round(y / 64)
	end	
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
	
	function PANEL:setInventory(inventory)
		if (inventory.slots) then
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
							icon:SetToolTip("Item #"..item.id.."\n"..L("itemInfo", item.name, (type(item.desc) == "function" and item.desc(item) or item.desc)))

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
		netstream.Start("invMv", oldX, oldY, x, y, self.invID)

		local inventory = LocalPlayer():getChar():getInv(self.invID)

		if (inventory) then
			local item = inventory:getItemAt(oldX, oldY)

			inventory.slots[oldX][oldY] = nil
			inventory.slots[x] = inventory.slots[x] or {}
			inventory.slots[x][y] = item
		end
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

			local inventory = LocalPlayer():getChar():getInv(self.invID)

			if (!inventory) then
				return
			end

			local itemTable = inventory:getItemAt(panel.gridX, panel.gridY)
			renderNewIcon(panel, itemTable)

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
									local send = true

									if (v.onClick) then
										send = v.onClick(itemTable)
									end

									if (send != false) then
										netstream.Start("invAct", k, itemTable.id, self.invID)
									end
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
vgui.Register("nutInventory", PANEL, "DFrame")

hook.Add("CreateMenuButtons", "nutInventory", function(tabs)
	tabs["inv"] = function(panel)		
		nut.gui.inv1 = panel:Add("nutInventory")

		local inventory = LocalPlayer():getChar():getInv()

		if (inventory) then
			nut.gui.inv1:setInventory(inventory)
		end
	end
end)