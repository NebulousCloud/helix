local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Container"
ENT.Category = "Helix"
ENT.Spawnable = false

if (SERVER) then
	function ENT:Initialize()
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
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
		end
	end

	function ENT:OnRemove()
		local index = self:GetNetVar("id")

		if (!ix.shuttingDown and !self.ixIsSafe and ix.entityDataLoaded and index) then
			local item = ix.item.inventories[index]

			if (item) then
				ix.item.inventories[index] = nil

				ix.db.query("DELETE FROM ix_items WHERE _invID = "..index)
				ix.db.query("DELETE FROM ix_inventories WHERE _invID = "..index)

				hook.Run("ContainerItemRemoved", self, item)
			end
		end
	end

	function ENT:OpenInventory(activator)
		local definition = PLUGIN.definitions[self:GetModel():lower()]
		local inventory = self:GetInventory()

		if (inventory) then
			ix.storage.Open(activator, inventory, {
				name = definition.name,
				entity = self,
				searchTime = ix.config.Get("containerOpenTime", 0.7)
			})
		end
	end

	function ENT:Use(activator)
		local inventory = self:GetInventory()

		if (inventory and (activator.ixNextOpen or 0) < CurTime()) then
			if (activator:GetChar()) then
				local def = PLUGIN.definitions[self:GetModel():lower()]

				if (self:GetNetVar("locked")) then
					self:EmitSound(def.locksound or "doors/default_locked.wav")
					
					if (!self.keypad) then
						netstream.Start(activator, "invLock", self)
					end
				else
					self:OpenInventory(activator)
				end
			end

			activator.ixNextOpen = CurTime() + 1
		end
	end
else
	ENT.DrawEntityInfo = true

	local COLOR_LOCKED = Color(242, 38, 19)
	local COLOR_UNLOCKED = Color(135, 211, 124)
	local toScreen = FindMetaTable("Vector").ToScreen
	local colorAlpha = ColorAlpha
	local drawText = ix.util.DrawText
	local configGet = ix.config.Get

	function ENT:OnDrawEntityInfo(alpha)
		local locked = self.GetNetVar(self, "locked", false)
		local position = toScreen(self.LocalToWorld(self, self.OBBCenter(self)))
		local x, y = position.x, position.y

		y = y - 20
		local tx, ty = ix.util.DrawText(locked and "P" or "Q", x, y, colorAlpha(locked and COLOR_LOCKED or COLOR_UNLOCKED, alpha), 1, 1, "ixIconsMedium", alpha * 0.65)
		y = y + ty*.9

		local def = PLUGIN.definitions[self:GetModel():lower()]
		local tx, ty = drawText(L("Container"), x, y, colorAlpha(configGet("color"), alpha), 1, 1, nil, alpha * 0.65)
		if (def) then
			y = y + ty + 1
			drawText(def.description, x, y, colorAlpha(color_white, alpha), 1, 1, nil, alpha * 0.65)
		end
	end
end

function ENT:GetInventory()
	return ix.item.inventories[self:GetNetVar("id", 0)]
end
