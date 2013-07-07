AddCSLuaFile()

ENT.Type = "anim"
ENT.Name = "Container"
ENT.Author = "Chessnut"
ENT.Spawnable = false

if (SERVER) then
	util.AddNetworkString("nut_Storage")
	util.AddNetworkString("nut_StorageUpdate")
	util.AddNetworkString("nut_TransferMoney")

	function ENT:Initialize()
		self:SetModel("models/props_lab/filecabinet02.mdl")
		self:SetNetVar("space", 10)
		self:SetNetVar("inv", {})
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local physicsObject = self:GetPhysicsObject()

		if (IsValid(physicsObject)) then
			physicsObject:Wake()
		end
	end

	function ENT:Use(activator)
		net.Start("nut_Storage")
			net.WriteEntity(self)
		net.Send(activator)
	end

	function ENT:UpdateInv(class, quantity, data)
		if (!nut.item.Get(class)) then
			return
		end

		local inventory = self:GetNetVar("inv")
		local oldInventory = inventory

		inventory = nut.util.StackInv(inventory, class, quantity, data)

		local weight, max = self:GetInvWeight()

		if (weight > max) then
			inventory = oldInventory
		else
			self:SetNetVar("inv", inventory)
		end
	end

	function ENT:GetItemsByClass(class)
		return self:GetNetVar("inv")[class] or {}
	end

	function ENT:GiveMoney(amount)
		local current = self:GetNetVar("money", 0)

		self:SetNetVar("money", current + amount)
	end

	function ENT:TakeMoney(amount)
		self:GiveMoney(-amount)
	end

	net.Receive("nut_StorageUpdate", function(length, client)
		local entity = net.ReadEntity()
		local class = net.ReadString()
		local quantity = net.ReadInt(8)
		local data = net.ReadTable()

		if (IsValid(entity) and entity:GetPos():Distance(client:GetPos()) <= 128) then
			if (quantity > 0 and client:HasItem(class)) then
				local result = client:UpdateInv(class, -1, data)

				if (result) then
					entity:UpdateInv(class, 1, data)
				end
			elseif (entity:HasItem(class)) then
				local result = client:UpdateInv(class, 1, data)

				if (result) then
					entity:UpdateInv(class, -1, data)
				end
			end
		end
	end)

	net.Receive("nut_TransferMoney", function(length, client)
		local entity = net.ReadEntity()
		local amount = net.ReadInt(16)

		amount = math.floor(amount)

		local amount2 = math.abs(amount)

		if (!IsValid(entity) or entity:GetPos():Distance(client:GetPos()) > 128) then
			return
		end

		if (client:HasMoney(amount) and amount > 0) then
			entity:GiveMoney(amount)
			client:TakeMoney(amount)
		elseif (entity:HasMoney(amount2)) then
			entity:TakeMoney(amount2)
			client:GiveMoney(amount2)
		end
	end)
else
	net.Receive("nut_Storage", function(length)
		local entity = net.ReadEntity()

		if (IsValid(entity)) then
			nut.gui.storage = vgui.Create("nut_Storage")
			nut.gui.storage:SetEntity(entity)

			entity:HookNetVar("inv", function()
				if (IsValid(nut.gui.storage) and nut.gui.storage:GetEntity() == entity) then
					nut.gui.storage:Reload()
				end
			end)

			entity:HookNetVar("money", function()
				if (IsValid(nut.gui.storage) and nut.gui.storage:GetEntity() == entity) then
					nut.gui.storage.money:SetText(entity:GetMoney())
					nut.gui.storage.money2:SetText(LocalPlayer():GetMoney())
				end
			end)

			nut.char.HookVar("money", "storageMoney", function()
				if (IsValid(nut.gui.storage) and nut.gui.storage:GetEntity() == entity) then
					nut.gui.storage.money2:SetText(LocalPlayer():GetMoney())
				end
			end)
		end
	end)
end

function ENT:GetInvWeight()
	local weight, maxWeight = 0, self:GetNetVar("max", nut.config.defaultInvWeight)

	for uniqueID, items in pairs(self:GetNetVar("inv")) do
		local itemTable = nut.item.Get(uniqueID)

		if (itemTable) then
			local quantity = 0

			for k, v in pairs(items) do
				quantity = quantity + v.quantity
			end

			local addition = itemTable.weight * quantity

			if (itemTable.weight < 0) then
				maxWeight = maxWeight + addition
			else
				weight = weight + addition
			end
		end
	end

	return weight, maxWeight
end

function ENT:HasMoney(amount)
	return self:GetNetVar("money", 0) >= amount
end

function ENT:HasItem(class, quantity)
	return table.Count(self:GetItemsByClass(class)) > (quantity or 0)
end

function ENT:GetMoney()
	return self:GetNetVar("money", 0)
end