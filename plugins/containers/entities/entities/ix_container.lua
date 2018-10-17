
local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Container"
ENT.Category = "Helix"
ENT.Spawnable = false
ENT.bNoPersist = true

if (SERVER) then
	ENT.money = 0

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

	function ENT:SetMoney(amount)
		self.money = math.max(0, math.Round(tonumber(amount) or 0))
	end

	function ENT:GetMoney()
		return self.money
	end

	function ENT:OnRemove()
		local index = self:GetNetVar("id")

		if (!ix.shuttingDown and !self.ixIsSafe and ix.entityDataLoaded and index) then
			local inventory = ix.item.inventories[index]

			if (inventory) then
				ix.item.inventories[index] = nil

				local query = mysql:Delete("ix_items")
					query:Where("inventory_id", index)
				query:Execute()

				query = mysql:Delete("ix_inventories")
					query:Where("inventory_id", index)
				query:Execute()

				hook.Run("ContainerRemoved", self, inventory)
			end
		end
	end

	function ENT:OpenInventory(activator)
		local inventory = self:GetInventory()

		if (inventory) then
			local name = self:GetDisplayName()

			ix.storage.Open(activator, inventory, {
				name = name,
				entity = self,
				searchTime = ix.config.Get("containerOpenTime", 0.7),
				data = {money = self:GetMoney()},
				OnPlayerClose = function()
					ix.log.Add(activator, "closeContainer", name, inventory:GetID())
				end
			})

			if (self:GetNetVar("locked")) then
				self.Sessions[activator:GetCharacter():GetID()] = true
			end

			ix.log.Add(activator, "openContainer", name, inventory:GetID())
		end
	end

	function ENT:Use(activator)
		local inventory = self:GetInventory()

		if (inventory and (activator.ixNextOpen or 0) < CurTime()) then
			local character = activator:GetCharacter()

			if (character) then
				local def = PLUGIN.definitions[self:GetModel():lower()]

				if (self:GetNetVar("locked") and !self.Sessions[character:GetID()]) then
					self:EmitSound(def.locksound or "doors/default_locked.wav")

					if (!self.keypad) then
						net.Start("ixContainerPassword")
							net.WriteEntity(self)
						net.Send(activator)
					end
				else
					self:OpenInventory(activator)
				end
			end

			activator.ixNextOpen = CurTime() + 1
		end
	end
else
	ENT.PopulateEntityInfo = true

	local COLOR_LOCKED = Color(242, 38, 19, 255)
	local COLOR_UNLOCKED = Color(135, 211, 124, 255)

	function ENT:OnPopulateEntityInfo(container)
		local definition = PLUGIN.definitions[self:GetModel():lower()]
		local bLocked = self:GetNetVar("locked", false)

		surface.SetFont("ixIconsSmall")

		local iconText = bLocked and "P" or "Q"
		local iconWidth, iconHeight = surface.GetTextSize(iconText)

		local title = container:AddRow("name")
		title:SetFont("ixSmallTitleFont")
		title:SetText(self:GetDisplayName())
		title:SetBackgroundColor(ix.config.Get("color"))
		title:SetTextInset(iconWidth + 8, 0)
		title:SizeToContents()

		title.Paint = function(panel, width, height)
			panel:PaintBackground(width, height)

			surface.SetFont("ixIconsSmall")
			surface.SetTextColor(bLocked and COLOR_LOCKED or COLOR_UNLOCKED)
			surface.SetTextPos(4, height * 0.5 - iconHeight * 0.5)
			surface.DrawText(iconText)
		end

		local description = container:AddRow("description")
		description:SetText(definition.description)
		description:SizeToContents()
	end
end

function ENT:GetDisplayName()
	local definition = PLUGIN.definitions[self:GetModel():lower()]
	return self:GetNetVar("name", definition.name)
end

function ENT:GetInventory()
	return ix.item.inventories[self:GetNetVar("id", 0)]
end
