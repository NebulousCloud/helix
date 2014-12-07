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

nut.currency = nut.currency or {}
nut.currency.symbol = nut.currency.symbol or "$"
nut.currency.singular = nut.currency.singular or "dollar"
nut.currency.plural = nut.currency.plural or "dollars"

function nut.currency.set(symbol, singular, plural)
	nut.currency.symbol = symbol
	nut.currency.singular = singular
	nut.currency.plural = plural
end

function nut.currency.get(amount)
	if (amount == 1) then
		return nut.currency.symbol.."1 "..nut.currency.singular
	else
		return nut.currency.symbol..amount.." "..nut.currency.plural
	end
end

function nut.currency.spawn(pos, amount, angle)
	if (!pos) then
		print("[Nutscript] Can't create currency entity: Invalid Position")
	elseif (!amount or amount < 0) then
		print("[Nutscript] Can't create currency entity: Invalid Amount of money")
	end

	local money = ents.Create("nut_money")
	money:SetPos(pos)
	-- double check for negative.
	money:setNetVar("amount", math.Round(math.abs(amount)))
	money:SetAngles(angle or Angle(0, 0, 0))
	money:Spawn()
	money:Activate()

	return money
end

function GM:OnPickupMoney(client, moneyEntity)
	if (moneyEntity and moneyEntity:IsValid()) then
		local amount = moneyEntity:getAmount()

		client:getChar():giveMoney(amount)
		client:notify(L("moneyTaken", client, nut.currency.get(amount)))
	end
end

do
	local character = FindMetaTable("Character")

	function character:hasMoney(amount)
		if (amount < 0) then
			print("Negative Money Check Received.")	
		end

		return self:getMoney() >= amount
	end

	function character:giveMoney(amount)
		amount = math.abs(amount)
		self:setMoney(self:getMoney() + amount)
	end

	function character:takeMoney(amount)
		amount = math.abs(amount)
		self:giveMoney(-amount)
	end
end