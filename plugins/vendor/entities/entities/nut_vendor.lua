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

ENT.Type = "anim"
ENT.PrintName = "Vendor"
ENT.Spawnable = false

function ENT:Initialize()
	if (SERVER) then
		self:SetModel("models/mossman.mdl")
		self:SetUseType(SIMPLE_USE)
		self:SetMoveType(MOVETYPE_NONE)
		self:DrawShadow(true)
		self:SetSolid(SOLID_BBOX)
		self:PhysicsInit(SOLID_BBOX)
		self:setNetVar("name", "John Doe")

		self.items = {}
		self.factions = {}
		self.classes = {}
		self.money = 0
		self.messages = {
			welcome = "vendorWelcome",
			noSell = "vendorNoSell",
			finish = "vendorFinish"
		}
		self.stocks = {}

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(false)
			physObj:Sleep()
		end
	end

	self:setAnim()
end

function ENT:setAnim()
	for k, v in ipairs(self:GetSequenceList()) do
		if (v:lower():find("idle") and v != "idlenoise") then
			return self:ResetSequence(k)
		end
	end

	self:ResetSequence(4)
end

if (CLIENT) then
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

		self:SetNextClientThink(CurTime() + 0.25)

		return true
	end

	function ENT:OnRemove()
		if (IsValid(self.bubble)) then
			self.bubble:Remove()
		end
	end

	local TEXT_OFFSET = Vector(0, 0, 20)

	function ENT:onShouldDrawselfInfo()
		return true
	end

	function ENT:onDrawselfInfo(alpha)
		local position = (self:LocalToWorld(self:OBBCenter()) + TEXT_OFFSET):ToScreen()
		local x, y = position.x, position.y
		local desc = self:getNetVar("desc")

		nut.util.drawText(self:getNetVar("name", "John Doe"), x, y, ColorAlpha(nut.config.get("color"), alpha), 1, 1, nil, alpha * 0.65)

		if (desc) then
			nut.util.drawText(desc, x, y + 16, ColorAlpha(color_white, alpha), 1, 1, "nutSmallFont", alpha * 0.65)
		end
	end
else
	function ENT:setMoney(value)
		if (value) then
			value = math.max(tonumber(value) or 0, 0)
		end

		local recipient = {}

		for k, v in ipairs(player.GetAll()) do
			if (v.nutVendor == self) then
				recipient[#recipient + 1] = v
			end
		end

		if (#recipient > 0) then
			netstream.Start(recipient, "vendorMoney", value)
		end

		self.money = value
	end

	function ENT:giveMoney(value)
		if (value == 0) then
			return
		end

		if (self.money) then
			self:setMoney(self.money + value)
		end
	end

	function ENT:takeMoney(value)
		self:giveMoney(-value)
	end

	function ENT:canAccess(client)
		if (client:IsAdmin()) then
			return true
		end

		if (hook.Run("CanPlayerUseVendor", client, self) == false) then
			return false
		end

		if (client:GetPos():Distance(self:GetPos()) > 96) then
			return false
		end

		if (table.Count(self.factions) > 0 and !self.factions[client:Team()]) then
			return false
		end

		if (table.Count(self.classes) > 0 and !self.classes[client:getChar():getClass()]) then
			return false
		end

		return true
	end

	function ENT:canBuyItem(client, uniqueID, ignoreStock)
		if (!self.items[uniqueID]) then
			return
		end

		if (hook.Run("CanVendorSellItem", client, self, uniqueID) == false) then
			return false
		end

		if (!ignoreStock and self.stocks and self.stocks[uniqueID] and self.stocks[uniqueID][1] and self.stocks[uniqueID][1] < 1) then
			return false
		end

		return true
	end

	function ENT:canSellItem(client, uniqueID)
		local itemTable = nut.item.list[uniqueID]

		if (!itemTable) then
			return false
		end

		if (hook.Run("CanVendorBuyItem", client, self, uniqueID) == false) then
			return false
		end

		return self.items[uniqueID] != nil
	end

	function ENT:Use(activator)
		if (self:canAccess(activator) == false) then
			local message = self.messages.noSell

			if (message and message:find("%S")) then
				activator:ChatPrint(message)
			end

			return
		end

		local money = self.money

		local items = {}
			for k, v in pairs(self.items) do
				if (self:canBuyItem(activator, k, true)) then
					items[k] = v

					if (items[k][1] == nil) then
						items[k][1] = false
					end
				end
			end

			local adminData

			if (activator:IsAdmin()) then
				adminData = {
					self.factions,
					self.classes
				}
			end

			if (money == nil) then
				money = false
			end
		netstream.Start(activator, "vendorUse", self, items, money, self.stocks, adminData)

		activator.nutVendor = self
		activator:ChatPrint(self:getNetVar("name")..": "..L(self.messages.welcome, activator))
	end

	function ENT:OnRemove()
		if (!nut.shuttingDown) then
			nut.plugin.list.vendor:saveVendors()
		end
	end
end

function ENT:hasMoney(value)
	return self.money >= value
end