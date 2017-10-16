nut.currency = nut.currency or {}
nut.currency.symbol = nut.currency.symbol or "$"
nut.currency.singular = nut.currency.singular or "dollar"
nut.currency.plural = nut.currency.plural or "dollars"

function nut.currency.Set(symbol, singular, plural)
	nut.currency.symbol = symbol
	nut.currency.singular = singular
	nut.currency.plural = plural
end

function nut.currency.Get(amount)
	if (amount == 1) then
		return nut.currency.symbol.."1 "..nut.currency.singular
	else
		return nut.currency.symbol..amount.." "..nut.currency.plural
	end
end

function nut.currency.Spawn(pos, amount, angle)
	if (!pos) then
		print("[Nutscript] Can't create currency entity: Invalid Position")
	elseif (!amount or amount < 0) then
		print("[Nutscript] Can't create currency entity: Invalid Amount of money")
	end

	local money = ents.Create("nut_money")
	money:SetPos(pos)
	-- double check for negative.
	money:SetNetVar("amount", math.Round(math.abs(amount)))
	money:SetAngles(angle or Angle(0, 0, 0))
	money:Spawn()
	money:Activate()

	return money
end

function GM:OnPickupMoney(client, moneyEntity)
	if (moneyEntity and moneyEntity:IsValid()) then
		local amount = moneyEntity:GetAmount()

		client:GetChar():GiveMoney(amount)
		client:NotifyLocalized("moneyTaken", nut.currency.Get(amount))
	end
end

do
	local character = nut.meta.character

	function character:HasMoney(amount)
		if (amount < 0) then
			print("Negative Money Check Received.")	
		end

		return self:GetMoney() >= amount
	end

	function character:GiveMoney(amount, noLog)
		if (!noLog) then
			nut.log.Add(self:GetPlayer(), "money", amount)
		end
		
		self:SetMoney(self:GetMoney() + amount)

		return true
	end

	function character:TakeMoney(amount)
		nut.log.Add(self:GetPlayer(), "money", -amount)
		amount = math.abs(amount)
		self:GiveMoney(-amount, true)

		return true
	end
end