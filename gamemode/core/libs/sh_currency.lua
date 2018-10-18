ix.currency = ix.currency or {}
ix.currency.symbol = ix.currency.symbol or "$"
ix.currency.singular = ix.currency.singular or "dollar"
ix.currency.plural = ix.currency.plural or "dollars"

function ix.currency.Set(symbol, singular, plural)
	ix.currency.symbol = symbol
	ix.currency.singular = singular
	ix.currency.plural = plural
end

function ix.currency.Get(amount)
	if (amount == 1) then
		return ix.currency.symbol.."1 "..ix.currency.singular
	else
		return ix.currency.symbol..amount.." "..ix.currency.plural
	end
end

function ix.currency.Spawn(pos, amount, angle)
	if (!amount or amount < 0) then
		print("[Helix] Can't create currency entity: Invalid Amount of money")
		return
	end

	local money = ents.Create("ix_money")
	money:Spawn()

	if (IsValid(pos) and pos:IsPlayer()) then
		pos = pos:GetItemDropPos(money)
	elseif (!isvector(pos)) then
		print("[Helix] Can't create currency entity: Invalid Position")

		money:Remove()
		return
	end

	money:SetPos(pos)
	-- double check for negative.
	money:SetNetVar("amount", math.Round(math.abs(amount)))
	money:SetAngles(angle or Angle(0, 0, 0))
	money:Activate()

	return money
end

function GM:OnPickupMoney(client, moneyEntity)
	if (IsValid(moneyEntity)) then
		local amount = moneyEntity:GetAmount()

		client:GetCharacter():GiveMoney(amount)
	end
end

do
	local character = ix.meta.character

	function character:HasMoney(amount)
		if (amount < 0) then
			print("Negative Money Check Received.")
		end

		return self:GetMoney() >= amount
	end

	function character:GiveMoney(amount, bNoLog)
		amount = math.abs(amount)

		if (!bNoLog) then
			ix.log.Add(self:GetPlayer(), "money", amount)
		end

		self:SetMoney(self:GetMoney() + amount)

		return true
	end

	function character:TakeMoney(amount, bNoLog)
		amount = math.abs(amount)

		if (!bNoLog) then
			ix.log.Add(self:GetPlayer(), "money", -amount)
		end

		self:SetMoney(self:GetMoney() - amount)

		return true
	end
end
