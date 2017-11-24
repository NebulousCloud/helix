
-- The queue for the rendered icons.
renderdIcons = renderdIcons or {}

-- To make making inventory variant, This must be followed up.
local function RenderNewIcon(panel, itemTable)
	-- re-render icons
	if ((itemTable.iconCam and !renderdIcons[string.lower(itemTable.model)]) or itemTable.forceRender) then
		local iconCam = itemTable.iconCam
		iconCam = {
			cam_pos = iconCam.pos,
			cam_ang = iconCam.ang,
			cam_fov = iconCam.fov,
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
	local itemTable = ix.item.instances[self.itemID]

	if (self.waiting and self.waiting > CurTime()) then
		local wait = (self.waiting - CurTime()) / self.waitingTime
		surface.SetDrawColor(255, 255, 255, 100*wait)
		surface.DrawRect(2, 2, w - 4, h - 4)
	end

	if (itemTable and itemTable.PaintOver) then
		local w, h = self:GetSize()

		itemTable.PaintOver(self, itemTable, w, h)
	end
end

function PANEL:ExtraPaint(w, h)
end

function PANEL:Paint(w, h)
	local parent = self:GetParent()

	surface.SetDrawColor(0, 0, 0, 85)
	surface.DrawRect(2, 2, w - 4, h - 4)

	self:ExtraPaint(w, h)
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

vgui.Register("ixItemIcon", PANEL, "SpawnIcon")

PANEL = {}
	DEFINE_BASECLASS("DFrame")
	AccessorFunc(PANEL, "iconSize", "IconSize", FORCE_NUMBER)

	function PANEL:Init()
		self:SetIconSize(64)
		self:MakePopup()
		self:Center()
		self:ShowCloseButton(false)
		self:SetDraggable(true)
		self:SetSizable(true)
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

	function PANEL:ViewOnly()
		self.viewOnly = true

		for id, icon in pairs(self.panels) do
			icon.OnMousePressed = nil
			icon.OnMouseReleased = nil
			icon.doRightClick = nil
		end
	end

	function PANEL:SetInventory(inventory)
		local iconSize = self.iconSize

		if (inventory.slots) then
			if (IsValid(ix.gui.inv1) and ix.gui.inv1.childPanels and inventory != LocalPlayer():GetChar():GetInv()) then
				table.insert(ix.gui.inv1.childPanels, self)
			end

			self.invID = inventory:GetID()
			self:SetSize(iconSize, iconSize)
			self:SetGridSize(inventory:GetSize())

			for x, items in pairs(inventory.slots) do
				for y, data in pairs(items) do
					if (!data.id) then continue end

					local item = ix.item.instances[data.id]

					if (item and !IsValid(self.panels[item.id])) then
						local icon = self:AddIcon(item.model or "models/props_junk/popcan01a.mdl", x, y, item.width, item.height, item.skin or 0)

						if (IsValid(icon)) then
							local newTooltip = hook.Run("OverrideItemTooltip", self, data, item)

							if (newTooltip) then
								icon:SetToolTip(newTooltip)
							else
								icon:SetToolTip(
									Format(ix.config.itemFormat,
									item.GetName and item:GetName() or L(item.name), item:GetDescription() or "")
								)
							end
							icon.itemID = item.id

							self.panels[item.id] = icon
						end
					end
				end
			end
		end

		self:Center()
	end

	function PANEL:SetGridSize(w, h)
		local iconSize = self.iconSize
		local newWidth = w * iconSize + 8
		local newHeight = h * iconSize + 31

		self.gridW = w
		self.gridH = h

		self:SetSize(newWidth, newHeight)
		self:SetMinWidth(newWidth)
		self:SetMinHeight(newHeight)
		self:BuildSlots()
	end

	function PANEL:PerformLayout(width, height)
		BaseClass.PerformLayout(self, width, height)

		if (self.Sizing and self.gridW and self.gridH) then
			local newWidth = (width - 8) / self.gridW
			local newHeight = (height - 31) / self.gridH

			self:SetIconSize((newWidth + newHeight) / 2)
			self:RebuildItems()
		end
	end
	
	function PANEL:BuildSlots()
		local iconSize = self.iconSize

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
				slot:SetPos((x - 1) * iconSize + 4, (y - 1) * iconSize + 27)
				slot:SetSize(iconSize, iconSize)
				slot.Paint = PaintSlot
				
				self.slots[x][y] = slot	
			end
		end
	end

	function PANEL:RebuildItems()
		local iconSize = self.iconSize
		
		for x = 1, self.gridW do
			for y = 1, self.gridH do
				local slot = self.slots[x][y]

				slot:SetPos((x - 1) * iconSize + 4, (y - 1) * iconSize + 27)
				slot:SetSize(iconSize, iconSize)
			end
		end

		for k, v in pairs(self.panels) do
			v:SetPos(self.slots[v.gridX][v.gridY]:GetPos())
			v:SetSize(v.gridW * iconSize, v.gridH * iconSize)
		end
	end
	
	local activePanels = {}
	function PANEL:PaintOver(w, h)
		local iconSize = self.iconSize
		local item = ix.item.held
		
		if (IsValid(item)) then
			local mouseX, mouseY = self:LocalCursorPos()
			local dropX, dropY = math.ceil((mouseX - 4 - (item.gridW - 1) * 32) / iconSize), math.ceil((mouseY - 27 - (item.gridH - 1) * 32) / iconSize)

			if ((mouseX < -w*0.05 or mouseX > w*1.05) or (mouseY < h*0.05 or mouseY > h*1.05)) then
				activePanels[self] = nil
			else
				activePanels[self] = true
			end

			item.dropPos = item.dropPos or {}
			if (item.dropPos[self]) then
				item.dropPos[self].item = nil
			end

			for x = 0, item.gridW - 1 do
				for y = 0, item.gridH - 1 do
					local x2, y2 = dropX + x, dropY + y
					
					-- Is Drag and Drop icon is in the Frame?
					if (self.slots[x2] and IsValid(self.slots[x2][y2])) then
						local bool = self:IsEmpty(x2, y2, item)
						
						surface.SetDrawColor(0, 0, 255, 10)

						if (x == 0 and y == 0) then
							item.dropPos[self] = {x = (x2 - 1) * iconSize + 4, y = (y2 - 1) * iconSize + 27, x2 = x2, y2 = y2}
						end
							
						if (bool) then
							surface.SetDrawColor(0, 255, 0, 10)
						else
							surface.SetDrawColor(255, 255, 0, 10)
							
							if (self.slots[x2] and self.slots[x2][y2] and item.dropPos[self]) then
								item.dropPos[self].item = self.slots[x2][y2].item
							end
						end
					
						surface.DrawRect((x2 - 1) * iconSize + 4, (y2 - 1) * iconSize + 27, iconSize, iconSize)
					else
						if (item.dropPos) then
							item.dropPos[self] = nil
						end
					end
				end
			end
		end
	end
	
	function PANEL:IsEmpty(x, y, this)
		return (!IsValid(self.slots[x][y].item) or self.slots[x][y].item == this)
	end
	
	function PANEL:OnTransfer(oldX, oldY, x, y, oldInventory, noSend)
		local inventory = ix.item.inventories[oldInventory.invID]
		local inventory2 = ix.item.inventories[self.invID]
		local item
		
		if (inventory) then
			item = inventory:GetItemAt(oldX, oldY)
			
			if (!item) then
				return false
			end

			if (hook.Run("CanItemBeTransfered", item, ix.item.inventories[oldInventory.invID], ix.item.inventories[self.invID]) == false) then
				return false, "notAllowed"
			end
		
			if (item.OnCanBeTransfered and item:OnCanBeTransfered(inventory, inventory != inventory2 and inventory2 or nil) == false) then
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

	function PANEL:AddIcon(model, x, y, w, h, skin)
		local iconSize = self.iconSize

		w = w or 1
		h = h or 1
		
		if (self.slots[x] and self.slots[x][y]) then
			local panel = self:Add("ixItemIcon")
			panel:SetSize(w * iconSize, h * iconSize)
			panel:SetZPos(999)
			panel:InvalidateLayout(true)
			panel:SetModel(model, skin)
			panel:SetPos(self.slots[x][y]:GetPos())
			panel.gridX = x
			panel.gridY = y
			panel.gridW = w
			panel.gridH = h

			local inventory = ix.item.inventories[self.invID]

			if (!inventory) then
				return
			end

			panel.inv = inventory

			local itemTable = inventory:GetItemAt(panel.gridX, panel.gridY)
			panel.itemTable = itemTable

			if (self.panels[itemTable:GetID()]) then
				self.panels[itemTable:GetID()]:Remove()
			end
			
			if (itemTable.exRender) then
				panel.Icon:SetVisible(false)
				panel.ExtraPaint = function(self, x, y)
					local exIcon = ikon:GetIcon(itemTable.uniqueID)
					if (exIcon) then
						surface.SetMaterial(exIcon)
						surface.SetDrawColor(color_white)
						surface.DrawTexturedRect(0, 0, x, y)
					else
						ikon:renderIcon(
							itemTable.uniqueID,
							itemTable.width,
							itemTable.height,
							itemTable.model,
							itemTable.iconCam
						)
					end
				end
			else
				-- yeah..
				RenderNewIcon(panel, itemTable)
			end

			panel.move = function(this, data, inventory, noSend)
				local oldX, oldY = this.gridX, this.gridY
				local oldParent = this:GetParent()

				if (inventory:OnTransfer(oldX, oldY, data.x2, data.y2, oldParent, noSend) == false) then
					return
				end

				data.x = data.x or (data.x2 - 1) * iconSize + 4
				data.y = data.y or (data.y2 - 1) * iconSize + 27

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
					if (input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)) then
						local func = itemTable.functions

						if (func) then
							local use
							local comm
							for k, v in pairs(USABLE_FUNCS or {}) do
								comm = v
								use = func[comm]

								if (use and use.OnCanRun) then
									if (use.OnCanRun(itemTable) == false) then
										continue
									end
								end

								if (use) then
									break
								end
							end

							if (!use) then return end

							itemTable.player = LocalPlayer()
								if (use.OnCanRun) then
									if (use.OnCanRun(itemTable) == false) then
										itemTable.player = nil

										return
									end
								end

								local send = true

								if (use.OnClick) then
									send = use.OnClick(itemTable)
								end

								if (use.sound) then
									surface.PlaySound(use.sound)
								end

								if (send != false) then
									netstream.Start("invAct", comm, itemTable.id, self.invID)
								end
							itemTable.player = nil
						end
					else
						this:DragMousePress(code)
						this:MouseCapture(true)

						ix.item.held = this
					end
				elseif (code == MOUSE_RIGHT and this.doRightClick) then
					this:doRightClick()
				end
			end
			panel.OnMouseReleased = function(this, code)
				if (code == MOUSE_LEFT and ix.item.held == this) then
					local data = this.dropPos

					this:DragMouseRelease(code)
					this:MouseCapture(false)
					this:SetZPos(99)

					ix.item.held = nil
					
					if (table.Count(activePanels) == 0) then
						local item = this.itemTable
						local inv = this.inv

						if (item and inv) then
							netstream.Start("invAct", "drop", item.id, inv:GetID(), item.id)
						end
						
						return false
					end
					activePanels = {}

					if (data) then
						local inventory = table.GetFirstKey(data)
						
						if (IsValid(inventory)) then
							data = data[inventory]

							if (IsValid(data.item)) then
								inventory = panel.inv

								if (inventory) then
									local targetItem = data.item.itemTable
									
									if (targetItem) then
										-- to make sure...
										if (targetItem.id == itemTable.id) then return end

										if (itemTable.functions) then
											local combine = itemTable.functions.combine

											-- does the item has the combine feature?
											if (combine) then
												itemTable.player = LocalPlayer()

												-- canRun == can item combine into?
												if (combine.OnCanRun and (combine.OnCanRun(itemTable, targetItem.id) != false)) then
													netstream.Start("invAct", "combine", itemTable.id, inventory:GetID(), targetItem.id)
												end

												itemTable.player = nil
											else
												--[[
													-- Drag and drop bag transfer requires half-recode of Inventory GUI.
													-- It will be there. But it will take some time.

													-- okay, the bag doesn't have any combine function.
													-- then, what's next? yes. moving the item in the bag.

													if (targetItem.isBag) then
														-- get the inventory.
														local bagInv = targetItem.GetInv and targetItem:GetInv()
														-- Is the bag's inventory exists?
														if (bagInv) then
															print(bagInv, "baggeD")
															local mx, my = bagInv:FindEmptySlot(itemTable.width, itemTable.height, true)
															
															-- we found slot for the inventory.
															if (mx and my) then		
																print(bagInv, "move")						
																this:move({x2 = mx, y2 = my}, bagInv)
															end
														end
													end
												]]--
											end
										end
									end
								end
							else
								local oldX, oldY = this.gridX, this.gridY

								if (oldX != data.x2 or oldY != data.y2 or inventory != self) then									
									this:move(data, inventory)
								end
							end
						end
					end
				end
			end
			panel.doRightClick = function(this)
				if (itemTable) then
					itemTable.player = LocalPlayer()
						local menu = DermaMenu()
						local override = hook.Run("OnCreateItemInteractionMenu", panel, menu, itemTable)
						
						if (override == true) then if (menu.Remove) then menu:Remove() end return end
							for k, v in SortedPairs(itemTable.functions) do
								if (k == "combine") then continue end -- we don't need combine on the menu mate. 

								if (v.OnCanRun) then
									if (v.OnCanRun(itemTable) == false) then
										itemTable.player = nil

										continue
									end
								end

								-- is Multi-Option Function
								if (v.isMulti) then
									local subMenu, subMenuOption = menu:AddSubMenu(L(v.name or k), function()
										itemTable.player = LocalPlayer()
											local send = true

											if (v.OnClick) then
												send = v.OnClick(itemTable)
											end

											if (v.sound) then
												surface.PlaySound(v.sound)
											end

											if (send != false) then
												netstream.Start("invAct", k, itemTable.id, self.invID)
											end
										itemTable.player = nil
									end)
									subMenuOption:SetImage(v.icon or "icon16/brick.png")

									if (v.multiOptions) then
										local options = isfunction(v.multiOptions) and v.multiOptions(itemTable, LocalPlayer()) or v.multiOptions

										for _, sub in pairs(options) do
											subMenu:AddOption(L(sub.name or "subOption"), function()
												itemTable.player = LocalPlayer()
													local send = true

													if (v.OnClick) then
														send = v.OnClick(itemTable)
													end

													if (v.sound) then
														surface.PlaySound(v.sound)
													end

													if (send != false) then
														netstream.Start("invAct", k, itemTable.id, self.invID, sub.data)
													end
												itemTable.player = nil
											end)
										end
									end
								else
									menu:AddOption(L(v.name or k), function()
										itemTable.player = LocalPlayer()
											local send = true

											if (v.OnClick) then
												send = v.OnClick(itemTable)
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
vgui.Register("ixInventory", PANEL, "DFrame")

hook.Add("CreateMenuButtons", "ixInventory", function(tabs)
	if (hook.Run("CanPlayerViewInventory") != false) then
		tabs["inv"] = function(panel)
			ix.gui.inv1 = panel:Add("ixInventory")
			ix.gui.inv1.childPanels = {}

			local inventory = LocalPlayer():GetChar():GetInv()

			if (inventory) then
				ix.gui.inv1:SetInventory(inventory)
			end
			ix.gui.inv1:SetPos(panel:GetPos())
		end
	end
end)

hook.Add("PostRenderVGUI", "ixInvHelper", function()
	local pnl = ix.gui.inv1

	hook.Run("PostDrawInventory", pnl)
end)
