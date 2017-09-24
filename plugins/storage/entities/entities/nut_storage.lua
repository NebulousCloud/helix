local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Storage"
ENT.Category = "NutScript"
ENT.Spawnable = false

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_junk/watermelon01.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self.receivers = {}
		
		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		end
	end

	function ENT:SetInventory(inventory)
		if (inventory) then
			self:SetNetVar("id", inventory:GetID())
			
			inventory.OnAuthorizeTransfer = function(inventory, client, oldInventory, item)
				if (IsValid(client) and IsValid(self) and self.receivers[client]) then
					return true
				end
			end
			inventory.GetReceiver = function(inventory)
				local receivers = {}

				for k, v in pairs(self.receivers) do
					if (IsValid(k)) then
						receivers[#receivers + 1] = k
					end
				end

				return #receivers > 0 and receivers or nil
			end
			inventory.OnCanTransfer = function(inventory, client, oldX, oldY, x, y, newInvID)
				return hook.Run("StorageCanTransfer", inventory, client, oldX, oldY, x, y, newInvID)
			end
		end
	end

	function ENT:OnRemove()
		local index = self:GetNetVar("id")

		if (!nut.shuttingDown and !self.nutIsSafe and nut.entityDataLoaded and index) then
			local item = nut.item.inventories[index]

			if (item) then
				nut.item.inventories[index] = nil

				nut.db.query("DELETE FROM nut_items WHERE _invID = "..index)
				nut.db.query("DELETE FROM nut_inventories WHERE _invID = "..index)

				hook.Run("StorageItemRemoved", self, item)
			end
		end
	end

	local OPEN_TIME = .7
	function ENT:OpenInv(activator)
		local inventory = self:GetInv()
		local def = PLUGIN.definitions[self:GetModel():lower()]

		if (def.OnOpen) then
			def.OnOpen(self, activator)
		end

		activator:SetAction("Opening...", OPEN_TIME, function()
			if (activator:GetPos():Distance(self:GetPos()) <= 100) then
				self.receivers[activator] = true
				activator.nutBagEntity = self
				
				inventory:Sync(activator)
				netstream.Start(activator, "invOpen", self, inventory:GetID())
				self:EmitSound(def.opensound or "items/ammocrate_open.wav")
			end
		end)
	end

	function ENT:Use(activator)
		local inventory = self:GetInv()

		if (inventory and (activator.nutNextOpen or 0) < CurTime()) then
			if (activator:GetChar()) then
				local def = PLUGIN.definitions[self:GetModel():lower()]

				if (self:GetNetVar("locked")) then
					self:EmitSound(def.locksound or "doors/default_locked.wav")
					if (!self.keypad) then
						netstream.Start(activator, "invLock", self)
					end
				else
					self:OpenInv(activator)
				end
			end

			activator.nutNextOpen = CurTime() + OPEN_TIME * 1.5
		end
	end
else
	ENT.DrawEntityInfo = true

	local COLOR_LOCKED = Color(242, 38, 19)
	local COLOR_UNLOCKED = Color(135, 211, 124)
	local toScreen = FindMetaTable("Vector").ToScreen
	local colorAlpha = ColorAlpha
	local drawText = nut.util.drawText
	local configGet = nut.config.Get

	function ENT:OnDrawEntityInfo(alpha)
		local locked = self.GetNetVar(self, "locked", false)
		local position = toScreen(self.LocalToWorld(self, self.OBBCenter(self)))
		local x, y = position.x, position.y

		y = y - 20
		local tx, ty = nut.util.DrawText(locked and "P" or "Q", x, y, colorAlpha(locked and COLOR_LOCKED or COLOR_UNLOCKED, alpha), 1, 1, "nutIconsMedium", alpha * 0.65)
		y = y + ty*.9

		local def = PLUGIN.definitions[self.GetModel(self):lower()]
		local tx, ty = drawText("Storage", x, y, colorAlpha(configGet("color"), alpha), 1, 1, nil, alpha * 0.65)
		if (def) then
			y = y + ty + 1
			drawText(def.description, x, y, colorAlpha(color_white, alpha), 1, 1, nil, alpha * 0.65)
		end
	end
end

function ENT:GetInv()
	return nut.item.inventories[self:GetNetVar("id", 0)]
end