
ENT.Type = "anim"
ENT.PrintName = "Vendor"
ENT.Category = "Helix"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.isVendor = true

function ENT:Initialize()
	if (SERVER) then
		self:SetModel("models/mossman.mdl")
		self:SetUseType(SIMPLE_USE)
		self:SetMoveType(MOVETYPE_NONE)
		self:DrawShadow(true)
		self:SetSolid(SOLID_BBOX)
		self:PhysicsInit(SOLID_BBOX)

		self.items = {}
		self.messages = {}
		self.factions = {}
		self.classes = {}

		self:SetNetVar("name", "John Doe")
		self:SetNetVar("desc", "")

		self.receivers = {}

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(false)
			physObj:Sleep()
		end
	end

	timer.Simple(1, function()
		if (IsValid(self)) then
			self:SetAnim()
		end
	end)
end

function ENT:CanAccess(client)
	if (client:IsAdmin()) then
		return true
	end

	local allowed = false
	local uniqueID = ix.faction.indices[client:Team()].uniqueID

	if (self.factions and table.Count(self.factions) > 0) then
		if (self.factions[uniqueID]) then
			allowed = true
		else
			return false
		end
	end

	if (allowed and self.classes and table.Count(self.classes) > 0) then
		local class = ix.class.list[client:GetChar():GetClass()]
		local classID = class and class.uniqueID

		if (!self.classes[classID]) then
			return false
		end
	end

	return true
end

function ENT:GetStock(uniqueID)
	if (self.items[uniqueID] and self.items[uniqueID][VENDOR_MAXSTOCK]) then
		return self.items[uniqueID][VENDOR_STOCK] or 0, self.items[uniqueID][VENDOR_MAXSTOCK]
	end
end

function ENT:GetPrice(uniqueID, selling)
	local price = ix.item.list[uniqueID] and self.items[uniqueID] and
		self.items[uniqueID][VENDOR_PRICE] or ix.item.list[uniqueID].price or 0

	if (selling) then
		price = math.floor(price * (self.scale or 0.5))
	end

	return price
end

function ENT:CanSellToPlayer(client, uniqueID)
	local data = self.items[uniqueID]

	if (!data or !client:GetChar() or !ix.item.list[uniqueID]) then
		return false
	end

	if (data[VENDOR_MODE] == VENDOR_BUYONLY) then
		return false
	end

	if (!client:GetChar():HasMoney(self:GetPrice(uniqueID))) then
		return false
	end

	if (data[VENDOR_STOCK] and data[VENDOR_STOCK] < 1) then
		return false
	end

	return true
end

function ENT:CanBuyFromPlayer(client, uniqueID)
	local data = self.items[uniqueID]

	if (!data or !client:GetChar() or !ix.item.list[uniqueID]) then
		return false
	end

	if (data[VENDOR_MODE] != VENDOR_SELLONLY) then
		return false
	end

	if (!self:HasMoney(data[VENDOR_PRICE] or ix.item.list[uniqueID].price or 0)) then
		return false
	end

	return true
end

function ENT:HasMoney(amount)
	-- Vendor not using money system so they can always afford it.
	if (!self.money) then
		return true
	end

	return self.money >= amount
end

function ENT:SetAnim()
	for k, v in ipairs(self:GetSequenceList()) do
		if (v:lower():find("idle") and v != "idlenoise") then
			return self:ResetSequence(k)
		end
	end

	self:ResetSequence(4)
end

if (SERVER) then
	local PLUGIN = PLUGIN

	function ENT:SpawnFunction(client, trace)
		local angles = (trace.HitPos - client:GetPos()):Angle()
		angles.r = 0
		angles.p = 0
		angles.y = angles.y + 180

		local entity = ents.Create("ix_vendor")
		entity:SetPos(trace.HitPos)
		entity:SetAngles(angles)
		entity:Spawn()

		PLUGIN:SaveData()

		return entity
	end

	function ENT:Use(activator)
		local character = activator:GetCharacter()

		if (!self:CanAccess(activator) or hook.Run("CanPlayerUseVendor", activator) == false) then
			if (self.messages[VENDOR_NOTRADE]) then
				activator:ChatPrint(self:GetNetVar("name")..": "..self.messages[VENDOR_NOTRADE])
			end

			return
		end

		self.receivers[#self.receivers + 1] = activator

		if (self.messages[VENDOR_WELCOME]) then
			activator:ChatPrint(self:GetNetVar("name")..": "..self.messages[VENDOR_WELCOME])
		end

		local items = {}

		-- Only send what is needed.
		for k, v in pairs(self.items) do
			if (table.Count(v) > 0 and (activator:IsAdmin() or v[VENDOR_MODE])) then
				items[k] = v
			end
		end

		self.scale = self.scale or 0.5

		local data = {}
		data[1] = items
		data[2] = self.money
		data[3] = self.scale

		if (activator:IsAdmin()) then
			data[4] = self.messages
			data[5] = self.factions
			data[6] = self.classes
		end

		activator.ixVendor = self

		-- force sync to prevent outdated inventories while buying/selling
		if (character) then
			character:GetInventory():Sync(activator, true)
		end

		netstream.Start(activator, "vendorOpen", self:EntIndex(), unpack(data))
	end

	function ENT:SetMoney(value)
		self.money = value

		netstream.Start(self.receivers, "vendorMoney", value)
	end

	function ENT:GiveMoney(value)
		if (self.money) then
			self:SetMoney(self:GetMoney() + value)
		end
	end

	function ENT:TakeMoney(value)
		if (self.money) then
			self:GiveMoney(-value)
		end
	end

	function ENT:SetStock(uniqueID, value)
		if (!self.items[uniqueID][VENDOR_MAXSTOCK]) then
			return
		end

		self.items[uniqueID] = self.items[uniqueID] or {}
		self.items[uniqueID][VENDOR_STOCK] = math.min(value, self.items[uniqueID][VENDOR_MAXSTOCK])

		netstream.Start(self.receivers, "vendorStock", uniqueID, value)
	end

	function ENT:AddStock(uniqueID, value)
		if (!self.items[uniqueID][VENDOR_MAXSTOCK]) then
			return
		end

		self:SetStock(uniqueID, self:GetStock(uniqueID) + (value or 1))
	end

	function ENT:TakeStock(uniqueID, value)
		if (!self.items[uniqueID][VENDOR_MAXSTOCK]) then
			return
		end

		self:AddStock(uniqueID, -(value or 1))
	end
else
	function ENT:CreateBubble()
		self.bubble = ClientsideModel("models/extras/info_speech.mdl", RENDERGROUP_OPAQUE)
		self.bubble:SetPos(self:GetPos() + Vector(0, 0, 84))
		self.bubble:SetModelScale(0.6, 0)
	end

	function ENT:Draw()
		local bubble = self.bubble

		if (IsValid(bubble)) then
			local realTime = RealTime()

			bubble:SetRenderOrigin(self:GetPos() + Vector(0, 0, 84 + math.sin(realTime * 3) * 0.05))
			bubble:SetRenderAngles(Angle(0, realTime * 100, 0))
		end

		self:DrawModel()
	end

	function ENT:Think()
		local noBubble = self:GetNetVar("noBubble")

		if (IsValid(self.bubble) and noBubble) then
			self.bubble:Remove()
		elseif (!IsValid(self.bubble) and !noBubble) then
			self:CreateBubble()
		end

		if ((self.nextAnimCheck or 0) < CurTime()) then
			self:SetAnim()
			self.nextAnimCheck = CurTime() + 60
		end

		self:SetNextClientThink(CurTime() + 0.25)

		return true
	end

	function ENT:OnRemove()
		if (IsValid(self.bubble)) then
			self.bubble:Remove()
		end
	end

	local TEXT_OFFSET = Vector(0, 0, 20)
	local toScreen = FindMetaTable("Vector").ToScreen
	local colorAlpha = ColorAlpha
	local drawText = ix.util.DrawText
	local configGet = ix.config.Get

	ENT.DrawEntityInfo = true

	function ENT:OnDrawEntityInfo(alpha)
		local position = toScreen(self.LocalToWorld(self, self.OBBCenter(self)) + TEXT_OFFSET)
		local x, y = position.x, position.y
		local desc = self.GetNetVar(self, "desc")

		drawText(self.GetNetVar(self, "name", "John Doe"), x, y, colorAlpha(configGet("color"), alpha), 1, 1, nil, alpha * 0.65)

		if (desc) then
			drawText(desc, x, y + 16, colorAlpha(color_white, alpha), 1, 1, "ixSmallFont", alpha * 0.65)
		end
	end
end

function ENT:GetMoney()
	return self.money
end
