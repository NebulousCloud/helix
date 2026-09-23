
--- A library representing the server's currency system.
-- @module ix.currency

ix.currency = ix.currency or {}
ix.currency.symbol = ix.currency.symbol or "$"
ix.currency.singular = ix.currency.singular or "dollar"
ix.currency.plural = ix.currency.plural or "dollars"
ix.currency.model = ix.currency.model or "models/props_lab/box01a.mdl"

local Places = {
    [1] = "Thousand",
    [2] = "Million",
    [3] = "Billion",
    [4] = "Trillion",
    [5] = "Quintillion",
    [6] = "Sextillion",
    [7] = "Heptillion"
}

--- Sets the currency type.
-- @realm shared
-- @string symbol The symbol of the currency.
-- @string singular The name of the currency in it's singular form.
-- @string plural The name of the currency in it's plural form.
-- @string model The model of the currency entity.
function ix.currency.Set(symbol, singular, plural, model)
	ix.currency.symbol = symbol
	ix.currency.singular = singular
	ix.currency.plural = plural
	ix.currency.model = model
end

--- Returns a formatted string according to the current currency.
-- @realm shared
-- @number amount The amount of cash being formatted.
-- @treturn string The formatted string.
function ix.currency.Get(amount)
	if (amount == 1) then
		return ix.currency.symbol.."1 "..ix.currency.singular
	else
		return ix.currency.symbol..amount.." "..ix.currency.plural
	end
end

function ix.currency.Format(amount,Place)
    local String = ""
    local Suffix = ""
    if Place == nil then
        Place = 0
    end
    if !isnumber(amount) then
        return "Input must be value"
    end
	if (amount == 1 or amount == -1) and Place == 0 then
		Suffix = " "..ix.currency.singular
	else
		Suffix = " "..ix.currency.plural
	end
    if amount > 1000 then
        amount = math.Round(amount/1000, 2)
        Place = Place + 1
        if Moni > 1000 and Place < 7 then
            String = ix.currency:Format(amount,Place)
        else
            String = ix.currency.symbol..amount.." "..Places[Place]..Suffix
        end
    elseif amount == 0 then
        String = "Broke"
    elseif amount < 1 then
        String = "Debt of "..ix.currency:Format(amount*-1)
    else
        String = ix.currency.symbol..amount..Suffix
    end
    return String
end

--- Spawns an amount of cash at a specific location on the map.
-- @realm shared
-- @vector pos The position of the money to be spawned.
-- @number amount The amount of cash being spawned.
-- @angle[opt=angle_zero] angle The angle of the entity being spawned.
-- @treturn entity The spawned money entity.
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
	money:SetAmount(math.Round(math.abs(amount)))
	money:SetAngles(angle or angle_zero)
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
