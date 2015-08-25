ENT.Type = "anim"
ENT.PrintName = "Vendor"
ENT.Category = "NutScript"
ENT.Spawnable = true
ENT.AdminOnly = true

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

		self:setNetVar("name", "John Doe")
		self:setNetVar("desc", "")

		self.receivers = {}

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(false)
			physObj:Sleep()
		end
	end

	timer.Simple(1, function()
		if (IsValid(self)) then
			self:setAnim()
		end
	end)
end

function ENT:canAccess(client)
	if (client:IsAdmin()) then
		return true
	end

	local allowed = false
	local uniqueID = nut.faction.indices[client:Team()].uniqueID

	if (self.factions and table.Count(self.factions) > 0) then
		if (self.factions[uniqueID]) then
			allowed = true
		else
			return false
		end
	end

	if (allowed and self.classes and table.Count(self.classes) > 0) then
		local class = nut.class.list[client:getChar():getClass()]
		local uniqueID = class and class.uniqueID

		if (!self.classes[uniqueID]) then
			return false
		end
	end

	return true
end

function ENT:getStock(uniqueID)
	if (self.items[uniqueID] and self.items[uniqueID][VENDOR_MAXSTOCK]) then
		return self.items[uniqueID][VENDOR_STOCK] or 0, self.items[uniqueID][VENDOR_MAXSTOCK]
	end
end

function ENT:getPrice(uniqueID, selling)
	local price = nut.item.list[uniqueID] and self.items[uniqueID] and self.items[uniqueID][VENDOR_PRICE] or nut.item.list[uniqueID].price or 0

	if (selling) then
		price = math.floor(price * (self.scale or 0.5))
	end

	return price
end

function ENT:canSellToPlayer(client, uniqueID)
	local data = self.items[uniqueID]

	if (!data or !client:getChar() or !nut.item.list[uniqueID]) then
		return false
	end

	if (data[VENDOR_MODE] == VENDOR_BUYONLY) then
		return false
	end

	if (!client:getChar():hasMoney(self:getPrice(uniqueID))) then
		return false
	end

	if (data[VENDOR_STOCK] and data[VENDOR_STOCK] < 1) then
		return false
	end

	return true
end

function ENT:canBuyFromPlayer(client, uniqueID)
	local data = self.items[uniqueID]

	if (!data or !client:getChar() or !nut.item.list[uniqueID]) then
		return false
	end

	if (data[VENDOR_MODE] != VENDOR_SELLONLY) then
		return false
	end

	if (!self:hasMoney(data[VENDOR_PRICE] or nut.item.list[uniqueID].price or 0)) then
		return false
	end

	return true
end

function ENT:hasMoney(amount)
	-- Vendor not using money system so they can always afford it.
	if (!self.money) then
		return true
	end
	
	return self.money >= amount
end

function ENT:setAnim()
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

		local entity = ents.Create("nut_vendor")
		entity:SetPos(trace.HitPos)
		entity:SetAngles(angles)
		entity:Spawn()

		PLUGIN:saveVendors()
		
		return entity
	end

	function ENT:Use(activator)
		if (!self:canAccess(activator) or hook.Run("CanPlayerUseVendor", activator) == false) then
			if (self.messages[VENDOR_NOTRADE]) then
				activator:ChatPrint(self:getNetVar("name")..": "..self.messages[VENDOR_NOTRADE])
			end

			return
		end

		self.receivers[#self.receivers + 1] = activator

		if (self.messages[VENDOR_WELCOME]) then
			activator:ChatPrint(self:getNetVar("name")..": "..self.messages[VENDOR_WELCOME])
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

		activator.nutVendor = self
		netstream.Start(activator, "vendorOpen", self:EntIndex(), unpack(data))
	end

	function ENT:setMoney(value)
		self.money = value

		netstream.Start(self.receivers, "vendorMoney", value)
	end

	function ENT:giveMoney(value)
		if (self.money) then
			self:setMoney(self:getMoney() + value)
		end
	end

	function ENT:takeMoney(value)
		if (self.money) then
			self:giveMoney(-value)
		end
	end

	function ENT:setStock(uniqueID, value)
		if (!self.items[uniqueID][VENDOR_MAXSTOCK]) then
			return
		end

		self.items[uniqueID] = self.items[uniqueID] or {}
		self.items[uniqueID][VENDOR_STOCK] = math.min(value, self.items[uniqueID][VENDOR_MAXSTOCK])

		netstream.Start(self.receivers, "vendorStock", uniqueID, value)
	end

	function ENT:addStock(uniqueID, value)
		if (!self.items[uniqueID][VENDOR_MAXSTOCK]) then
			return
		end

		self:setStock(uniqueID, self:getStock(uniqueID) + (value or 1))
	end

	function ENT:takeStock(uniqueID, value)
		if (!self.items[uniqueID][VENDOR_MAXSTOCK]) then
			return
		end
		
		self:addStock(uniqueID, -(value or 1))
	end

	function ENT:OnRemove()
		if (!nut.shuttingDown and !self.nutIsSafe) then
			PLUGIN:saveVendors()
		end
	end
else
	function ENT:createBubble()
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
		local noBubble = self:getNetVar("noBubble")

		if (IsValid(self.bubble) and noBubble) then
			self.bubble:Remove()
		elseif (!IsValid(self.bubble) and !noBubble) then
			self:createBubble()
		end

		if ((self.nextAnimCheck or 0) < CurTime()) then
			self:setAnim()
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
	local drawText = nut.util.drawText
	local configGet = nut.config.get

	ENT.DrawEntityInfo = true

	function ENT:onDrawEntityInfo(alpha)
		local position = toScreen(self.LocalToWorld(self, self.OBBCenter(self)) + TEXT_OFFSET)
		local x, y = position.x, position.y
		local desc = self.getNetVar(self, "desc")

		drawText(self.getNetVar(self, "name", "John Doe"), x, y, colorAlpha(configGet("color"), alpha), 1, 1, nil, alpha * 0.65)

		if (desc) then
			drawText(desc, x, y + 16, colorAlpha(color_white, alpha), 1, 1, "nutSmallFont", alpha * 0.65)
		end
	end
end

function ENT:getMoney()
	return self.money
end
